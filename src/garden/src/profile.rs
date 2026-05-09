use color_eyre::{
    Result,
    eyre::{Ok, OptionExt},
};

use rayon::iter::{IntoParallelIterator, ParallelIterator};
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use tracing::warn;

use crate::generation::{GenerationId, GenerationInfo, GenerationMetadata};

#[derive(Debug, Deserialize, Serialize)]
pub struct Profile {
    name: String,
    pathbuf: PathBuf,
}

impl Default for Profile {
    fn default() -> Self {
        Self::system()
    }
}

#[inline(always)]
pub fn profiles_root() -> &'static Path {
    Path::new("/nix/var/nix/profiles/")
}

impl Profile {
    pub fn system() -> Self {
        Self::new("system").expect("system profile creation should never fail")
    }

    pub fn new(name: &str) -> Option<Self> {
        Some(Self {
            pathbuf: match name {
                "system" | "" => profiles_root().join("system"),
                n => profiles_root().join("system-profiles").join(n),
            },
            name: name.into(),
        })
    }

    #[inline(always)]
    pub fn name(&self) -> &str {
        &self.name
    }

    #[inline(always)]
    pub fn as_pathbuf(&self) -> &PathBuf {
        &self.pathbuf
    }

    #[inline(always)]
    pub fn as_path(&self) -> &Path {
        self.pathbuf.as_path()
    }

    pub fn profile_parent_path(&self) -> &Path {
        self.pathbuf.parent().expect("should always exist")
    }

    pub fn profile_default_generation_path(&self) -> PathBuf {
        self.profile_parent_path().join(&self.name)
    }

    pub fn current_generation_id(&self) -> Result<GenerationId> {
        GenerationId::from_path(
            &self.name,
            self.profile_default_generation_path().read_link()?,
        )
    }

    pub fn iter_generation_links(&self) -> Result<glob::Paths> {
        Ok(glob::glob(
            &self
                .profile_parent_path()
                .join(format!("{}-*-link", self.name))
                .to_string_lossy(),
        )?)
    }

    pub fn par_iter_metadata(&self) -> Result<impl ParallelIterator<Item = GenerationMetadata>> {
        let paths: Vec<_> = self
            .iter_generation_links()?
            .filter_map(|x| x.inspect_err(|e| warn!(?e, "failed to glob")).ok())
            .collect();

        Ok(paths
            .into_par_iter()
            .filter_map(|e| GenerationMetadata::from_path(self, e).ok()))
    }

    pub fn par_iter_info(&self) -> Result<impl ParallelIterator<Item = GenerationInfo>> {
        Ok(self.par_iter_info_all()?.filter_map(|e| {
            e.inspect_err(|e| warn!(?e, "failed to parse generation into SysInfo"))
                .ok()
        }))
    }

    pub fn par_iter_info_all(
        &self,
    ) -> Result<impl ParallelIterator<Item = Result<GenerationInfo>>> {
        Ok(self
            .par_iter_metadata()?
            .map(|genr| GenerationInfo::from_metadata(genr)))
    }

    pub fn collect_metadata(&self) -> Result<Vec<GenerationMetadata>> {
        Ok(self.par_iter_metadata()?.collect())
    }

    pub fn collect_info(&self) -> Result<Vec<GenerationInfo>> {
        Ok(self.par_iter_info()?.collect())
    }

    pub fn find_current_info(&self) -> Result<Option<GenerationInfo>> {
        self.par_iter_metadata()?
            .find_map_any(|meta| meta.current().then_some(meta))
            .map(GenerationInfo::from_metadata)
            .transpose()
    }
}

impl AsRef<Path> for Profile {
    fn as_ref(&self) -> &Path {
        &self.pathbuf
    }
}

impl AsRef<PathBuf> for Profile {
    fn as_ref(&self) -> &PathBuf {
        &self.pathbuf
    }
}

impl From<Profile> for PathBuf {
    fn from(value: Profile) -> Self {
        value.pathbuf
    }
}
