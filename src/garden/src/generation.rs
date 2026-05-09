use color_eyre::{
    Result,
    eyre::{self, Ok, OptionExt, eyre},
};

use fs::DirEntry;
use fs_err as fs;

use jiff::Timestamp;
use rayon::iter::{IntoParallelIterator, ParallelIterator};
use serde::{Deserialize, Serialize};
use std::{
    fmt::Display,
    path::{Path, PathBuf},
    str::FromStr,
};
use tracing::{trace, warn};

use crate::profile::Profile;

macro_rules! impl_fromstr {
    ($name:ident) => {
        impl FromStr for $name {
            type Err = std::convert::Infallible;

            fn from_str(s: &str) -> std::result::Result<Self, Self::Err> {
                std::result::Result::Ok(Self(s.into()))
            }
        }
    };
}

macro_rules! impl_display {
    ($name:ident) => {
        impl Display for $name {
            fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
                self.0.fmt(f)
            }
        }
    };
}

macro_rules! newtype {
    ($name:ident, $typ:ty) => {
        #[derive(Debug, Clone, Deserialize, Serialize, PartialEq, Eq, PartialOrd, Ord)]
        pub struct $name($typ);

        impl std::ops::Deref for $name {
            type Target = $typ;

            fn deref(&self) -> &Self::Target {
                &self.0
            }
        }
    };
}

fn timestamp_from_path(path: impl AsRef<Path>) -> Result<Timestamp> {
    Ok(fs::metadata(path)
        .and_then(|m| m.created())
        .inspect_err(|e| warn!(?e, "failed to read ctime"))?
        .try_into()
        .inspect_err(|e| warn!(?e, "failed to parse ctime into timestamp"))?)
}

newtype!(KernelVersion, String);
impl_fromstr!(KernelVersion);
impl_display!(KernelVersion);

newtype!(NixosVersion, String);
impl_fromstr!(NixosVersion);
impl_display!(NixosVersion);

#[derive(Debug, Clone, Deserialize, Serialize, PartialEq, Eq)]
pub struct GenerationId {
    id: u32,
    name: String,
}

impl GenerationId {
    pub fn id(&self) -> u32 {
        self.id
    }

    pub fn name(&self) -> &str {
        &self.name
    }

    fn new(name: &str, id: u32) -> Self {
        Self {
            name: if name.is_empty() { "system" } else { name }.to_string(),
            id,
        }
    }

    fn from_prefix(prefix: &str, s: &str) -> Result<Self> {
        if !s.starts_with(&format!("{prefix}-")) {
            return Err(eyre!(r#""{}" not a prefix of {}"#, prefix, s));
        }
        Self::from_str(s)
    }

    pub fn from_path(prefix: &str, path: impl AsRef<Path>) -> Result<Self> {
        let name = path
            .as_ref()
            .file_name()
            .ok_or_eyre("failed to get file_name from path")?
            .to_string_lossy();
        if !name.ends_with("-link") {
            return Err(eyre!(r#""{}" doesn't end with "-link""#, name));
        }
        GenerationId::from_prefix(prefix, &name)
    }
}

impl PartialOrd for GenerationId {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        (self.name == other.name)
            .then(|| self.id.partial_cmp(&other.id))
            .flatten()
    }
}
impl From<GenerationId> for String {
    fn from(value: GenerationId) -> Self {
        let GenerationId { mut name, id } = value;
        name.push_str(&format!("-{id}"));
        name
    }
}

impl Display for GenerationId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        self.clone().to_string().fmt(f)
    }
}

impl FromStr for GenerationId {
    type Err = eyre::Report;

    fn from_str(s: &str) -> std::result::Result<Self, Self::Err> {
        let s = s.strip_suffix("-link").unwrap_or(s);
        let (name, id) = s
            .rsplit_once('-')
            .ok_or_eyre("failed to rsplit_once at '-'")?;
        if name.is_empty() {
            return Err(eyre!("GenerationId without a prefix!"));
        }
        Ok(Self::new(name, id.parse()?))
    }
}

newtype!(Current, bool);

impl Current {
    pub fn is(profile: &Profile, id: &GenerationId) -> Result<Self> {
        let curr = profile.current_generation_id()?;
        Ok(Self(curr == *id))
    }
}

#[derive(Debug, Deserialize, Serialize)]
pub struct GenerationMetadata {
    id: GenerationId,
    timestamp: Timestamp,
    current: Current,
    pathbuf: PathBuf,
}

impl GenerationMetadata {
    pub fn current(&self) -> &Current {
        &self.current
    }

    pub fn timestamp(&self) -> Timestamp {
        self.timestamp
    }

    pub fn id(&self) -> &GenerationId {
        &self.id
    }

    pub fn as_path(&self) -> &Path {
        self.pathbuf.as_path()
    }

    pub fn from_path(parent: &Profile, path: impl Into<PathBuf>) -> Result<Self> {
        let path = path.into();
        let id = GenerationId::from_path(parent.name(), &path)?;
        Ok(Self {
            timestamp: timestamp_from_path(&path)?,
            current: Current::is(parent, &id)?,
            pathbuf: path,
            id,
        })
    }

    pub fn read_under(&self, subpath: impl AsRef<Path>) -> std::io::Result<String> {
        fs::read_to_string(self.pathbuf.join(subpath))
    }

    pub fn parse_under<T>(&self, subpath: impl AsRef<Path>) -> Result<T>
    where
        T: FromStr,
        eyre::Report: From<T::Err>,
    {
        Ok(self.read_under(subpath)?.parse()?)
    }
}

#[derive(Debug, Deserialize, Serialize)]
pub struct NixosVersionInfo {
    pub nixos_version: String,
    pub nixpkgs_revision: String,
    pub configuration_revision: Option<String>,
    pub release_name: String,
}

impl FromStr for NixosVersionInfo {
    type Err = eyre::Report;

    fn from_str(s: &str) -> std::result::Result<Self, Self::Err> {
        #[derive(Debug, Deserialize, Serialize)]
        #[serde(rename_all = "camelCase")]
        pub struct Json {
            pub nixos_version: String,
            pub nixpkgs_revision: String,
            pub configuration_revision: Option<String>,
        }

        let re = regex::Regex::new(r"(?s)cat <<EOF\n(.*)\nEOF")?;
        let x = re
            .captures(s)
            .inspect(|x| trace!(?x))
            .and_then(|x| x.get(1))
            .ok_or_else(|| eyre!("couldn't find json in nixos-version script!"))?;
        let json: Json = serde_json::from_str(x.as_str())?;
        let re = regex::Regex::new(r"\((.+)\)")?;
        let release_name = re
            .captures(s)
            .and_then(|x| x.get(1))
            .inspect(|x| trace!(?x))
            .map(|x| x.as_str().to_owned())
            .ok_or_else(|| eyre!("Couldn't get release name!"))?;

        Ok(Self {
            nixos_version: json.nixos_version,
            nixpkgs_revision: json.nixpkgs_revision,
            configuration_revision: json.configuration_revision,
            release_name,
        })
    }
}

#[derive(Debug, Deserialize, Serialize)]
pub struct GenerationInfo {
    pub generation: GenerationId,
    pub kernel_ver: Option<KernelVersion>,
    pub nixos_ver: NixosVersion,
    pub release_name: String,
    pub date: Timestamp,
    pub specialisations: Vec<String>,
    pub current: Current,
    pub nixpkgs_rev: String,
    pub config_rev: Option<String>,
}

impl GenerationInfo {
    pub fn from_metadata(meta: GenerationMetadata) -> Result<Self> {
        let nixos_ver = meta
            .parse_under("nixos-version")
            .inspect_err(|e| warn!(?e, "failed to parse nixos-version"))
            .ok();
        let kernel_ver = meta
            .as_path()
            .join("kernel-modules/lib/modules")
            .read_dir()?
            .flatten()
            .filter_map(|x| {
                x.file_name()
                    .into_string()
                    .inspect_err(|e| warn!(?e, "failed to parse file_name"))
                    .ok()
            })
            .filter_map(|x| {
                x.parse()
                    .inspect_err(|e| warn!(?e, "failed to parse kernel-version"))
                    .ok()
            })
            .next();

        let specialisations = meta
            .as_path()
            .join("specialisation")
            .read_dir()?
            .flatten()
            .filter_map(|x| x.path().is_dir().then(|| x.file_name()))
            .filter_map(|x| x.into_string().inspect_err(|e| warn!(?e)).ok())
            .collect();

        let info: NixosVersionInfo = meta.parse_under(Path::new("sw/bin/nixos-version"))?;

        Ok(Self {
            nixos_ver: nixos_ver.unwrap_or(info.nixos_version.parse()?),
            kernel_ver,
            specialisations,
            generation: meta.id,
            date: meta.timestamp,
            current: meta.current,
            nixpkgs_rev: info.nixpkgs_revision,
            config_rev: info.configuration_revision,
            release_name: info.release_name,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    mod generation_id {
        use super::*;

        mod from_str {
            use super::*;
            macro_rules! from_str_test {
                (err, $test_name:ident, $val: expr) => {
                    #[test]
                    fn $test_name() {
                        assert!($val.parse::<GenerationId>().is_err());
                    }
                };
                ($test_name:ident, $name: expr, $id: expr) => {
                    #[test]
                    fn $test_name() {
                        let g: GenerationId = format!("{}-{}", $name, $id).parse().unwrap();
                        assert_eq!(g.name, $name);
                        assert_eq!(g.id, $id);
                    }
                };
                ($test_name:ident, $name: expr, $id: expr, link) => {
                    #[test]
                    fn $test_name() {
                        let g: GenerationId = format!("{}-{}-link", $name, $id).parse().unwrap();
                        assert_eq!(g.name, $name);
                        assert_eq!(g.id, $id);
                    }
                };
            }

            from_str_test!(standard, "system", 42);
            from_str_test!(multi_segment_name, "home-manager", 7);
            from_str_test!(u32_max_id, "system", u32::MAX);

            from_str_test!(err, no_dash_errors, "system");
            from_str_test!(err, empty_errors, "");
            from_str_test!(err, lone_dash_errors, "-");
            from_str_test!(err, non_numeric_id_errors, "system-abc");
            from_str_test!(err, empty_id_errors, "system-");
            from_str_test!(err, u32_overflow_errors, "system-4294967296");
            from_str_test!(err, empty_name_errors, "-42");
            from_str_test!(err, double_link_suffix_errors, "system-42-link-link");
            from_str_test!(strips_link_suffix, "system", 42, link);

            #[test]
            fn leading_zeros_in_id() {
                let g: GenerationId = "system-007".parse().unwrap();
                assert_eq!(g.name, "system");
                assert_eq!(g.id, 7);
            }
        }

        mod from_path {
            use super::*;
            macro_rules! from_path_test {
                (none, $test_name:ident, $prefix: expr, $link: expr) => {
                    #[test]
                    fn $test_name() {
                        let g = GenerationId::from_path(
                            $prefix,
                            format!("/nix/var/nix/profiles/{}", $link),
                        );
                        assert!(g.is_err());
                    }
                };
                ($test_name:ident, $name: expr, $id: expr) => {
                    #[test]
                    fn $test_name() {
                        let g = GenerationId::from_path(
                            $name,
                            format!("/nix/var/nix/profiles/{}-{}-link", $name, $id),
                        )
                        .unwrap();
                        assert_eq!(g.name, $name);
                        assert_eq!(g.id, $id);
                    }
                };
            }
            from_path_test!(standard, "system", 42);
            from_path_test!(profile_name_contains_dashes, "home-manager", 7);
            from_path_test!(none, requires_link_suffix, "system", "system-42");
            from_path_test!(none, wrong_prefix_returns_none, "system", "other-42-link");
            from_path_test!(none, non_link_file_returns_none, "system", "system");
        }

        mod partial_cmp {
            use std::cmp::Ordering;

            use super::*;

            macro_rules! partial_cmp_test {
                ($test_name: ident, $a:expr, $b: expr, $res: expr) => {
                    partial_cmp_test!($test_name, $a, $b, $res, $res);
                };
                ($test_name: ident, $a: expr, $b: expr, $resAtB: expr, $resBtA: expr) => {
                    #[test]
                    fn $test_name() {
                        let a: GenerationId = $a.parse().unwrap();
                        let b: GenerationId = $b.parse().unwrap();
                        assert_eq!(a.partial_cmp(&b), $resAtB);
                        assert_eq!(b.partial_cmp(&a), $resBtA);
                    }
                };
            }

            partial_cmp_test!(
                same_name_orders_by_id,
                "system-1",
                "system-2",
                Some(Ordering::Less),
                Some(Ordering::Greater)
            );

            partial_cmp_test!(different_names_returns_none, "system-1", "home-2", None);

            partial_cmp_test!(
                different_names_same_id_returns_none,
                "system-1",
                "home-1",
                None
            );

            partial_cmp_test!(
                equal_when_both_fields_match,
                "system-42",
                "system-42",
                Some(Ordering::Equal)
            );
        }
    }

    mod nixos_version_info {
        use super::*;

        #[test]
        fn parses_real_world_script() {
            /// Captured 2026-05-11 from /nix/var/nix/profiles/system/sw/bin/nixos-version.
            /// If nixpkgs ever reformats this template, regenerate.
            pub const GOLDEN_NIXOS_VERSION_SCRIPT: &str = // sh
                r#"#! /nix/store/wv8bpzriikv65xnd1vciqpq7rnr8h2q2-bash-5.3p3/bin/bash
# shellcheck shell=bash

case "$1" in
  -h|--help)
    exec man nixos-version
    exit 1
    ;;
  --hash|--revision)
    if ! [[ d96b37bbeb9840f1c0ebfe90585ef5067b69bbb3 =~ ^[0-9a-f]+$ ]]; then
      echo "$0: Nixpkgs commit hash is unknown" >&2
      exit 1
    fi
    echo "d96b37bbeb9840f1c0ebfe90585ef5067b69bbb3"
    ;;
  --configuration-revision)
    if [[ "@configurationRevision@" =~ "@" ]]; then
      echo "$0: configuration revision is unknown" >&2
      exit 1
    fi
    echo "@configurationRevision@"
    ;;
  --json)
    cat <<EOF
{"nixosVersion":"25.11.20260407.d96b37b","nixpkgsRevision":"d96b37bbeb9840f1c0ebfe90585ef5067b69bbb3"}
EOF
    ;;
  *)
    echo "25.11.20260407.d96b37b (Xantusia)"
    ;;
esac"#;
            let info: NixosVersionInfo = GOLDEN_NIXOS_VERSION_SCRIPT.parse().unwrap();
            assert_eq!(info.nixos_version, "25.11.20260407.d96b37b");
            assert_eq!(
                info.nixpkgs_revision,
                "d96b37bbeb9840f1c0ebfe90585ef5067b69bbb3"
            );
            assert_eq!(info.configuration_revision, None);
            assert_eq!(info.release_name, "Xantusia");
        }

        #[test]
        fn missing_heredoc_errors() {
            let script = r#"case "$1" in
  *)
    echo "25.11 (Codename)"
    ;;
esac"#;
            assert!(script.parse::<NixosVersionInfo>().is_err());
        }

        #[test]
        fn missing_release_name_errors() {
            let script = r#"case "$1" in
  --json)
    cat <<EOF
{"nixosVersion":"X","nixpkgsRevision":"Y"}
EOF
    ;;
esac"#;
            assert!(script.parse::<NixosVersionInfo>().is_err());
        }

        #[test]
        fn empty_input_errors() {
            assert!("".parse::<NixosVersionInfo>().is_err());
        }

        #[test]
        fn pretty_printed_json() {
            let script = r#"case "$1" in
  --json)
    cat <<EOF
{
  "nixosVersion": "25.11.test",
  "nixpkgsRevision": "abc"
}
EOF
    ;;
  *)
    echo "25.11.test (Codename)"
    ;;
esac"#;
            let info: NixosVersionInfo = script.parse().unwrap();
            assert_eq!(info.nixos_version, "25.11.test");
            assert_eq!(info.nixpkgs_revision, "abc");
            assert_eq!(info.configuration_revision, None);
            assert_eq!(info.release_name, "Codename");
        }

        #[test]
        fn nested_parens_in_release_name() {
            let script = r#"case "$1" in
  --json)
    cat <<EOF
{"nixosVersion":"X","nixpkgsRevision":"Y"}
EOF
    ;;
  *)
    echo "1.0 (Code (paren) name)"
    ;;
esac"#;
            let info: NixosVersionInfo = script.parse().unwrap();
            assert_eq!(info.nixos_version, "X");
            assert_eq!(info.nixpkgs_revision, "Y");
            assert_eq!(info.configuration_revision, None);
            assert_eq!(info.release_name, "Code (paren) name");
        }

        #[test]
        fn configuration_revision_present_when_json_carries_it() {
            let script = r#"case "$1" in
  --json)
    cat <<EOF
{"nixosVersion":"X","nixpkgsRevision":"Y","configurationRevision":"deadbeef"}
EOF
    ;;
  *)
    echo "X (Codename)"
    ;;
esac"#;
            let info: NixosVersionInfo = script.parse().unwrap();
            assert_eq!(info.nixos_version, "X");
            assert_eq!(info.nixpkgs_revision, "Y");
            assert_eq!(info.configuration_revision, Some("deadbeef".into()));
            assert_eq!(info.release_name, "Codename");
        }
    }
}
