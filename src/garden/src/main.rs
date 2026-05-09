mod generation;
mod profile;

use clap::Parser;
use color_eyre::{
    Result,
    eyre::{Ok, OptionExt, eyre},
};
use std::{io::Write, path::PathBuf, time::Instant};
use tracing::trace;

use generation::GenerationInfo;
use profile::Profile;

/// macro for writing elapsed time
macro_rules! t_writeln {
    ($w: expr, $t_measure: expr, $tag: expr) => {
        Ok(if let Some(start) = $t_measure {
            writeln!($w, "{}: {:.3}s", $tag, start.elapsed().as_secs_f64())?;
        } else {
        })
    };
    ($w: expr, $t_measure: expr) => {
        t_writeln!($w, $t_measure, "took")
    };
}

struct IssueFormatArgs<'vn, 'hn> {
    pub variant_name: &'vn str,
    pub hostname: &'hn str,
}

fn format_issue(
    current: &GenerationInfo,
    IssueFormatArgs {
        variant_name,
        hostname,
    }: IssueFormatArgs<'_, '_>,
) -> Option<String> {
    const UNKNOWN: &str = "Unknown";

    let kernel = current
        .kernel_ver
        .as_ref()
        .map(|x| x.as_str())
        .unwrap_or(UNKNOWN);
    let generation = current.generation.id();
    let date = current
        .date
        .to_zoned(jiff::tz::TimeZone::system())
        .strftime("%Y-%m-%d %H:%M:%S%:z");

    let mut lines = vec![
        format!("Welcome to {variant_name} @ {hostname}"),
        format!(
            "ver: {} ({}) {}",
            current.nixos_ver, current.release_name, kernel
        ),
        format!("gen: {} {}", generation, date),
    ];
    if !current.specialisations.is_empty() {
        lines.push(format!("spec: {}", current.specialisations.join(" ")));
    }
    lines.push(format!("nixpkgs: {}", current.nixpkgs_rev));
    Some(lines.join("\n"))
}

fn is_boot() -> bool {
    !std::process::Command::new("systemctl")
        .args(["is-active", "--quiet", "multi-user.target"])
        .status()
        .map_or(true, |s| s.success()) // if systemctl fails, assume boot
}

#[derive(clap::Parser, Debug)]
#[command(version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    cmd: Cmd,

    #[arg(long, num_args=0..=1, default_missing_value = "true")]
    timed: bool,
}

/// Tool for managing Nixon configuration
#[derive(clap::Subcommand, Debug)]
enum Cmd {
    /// Manage generation & os info
    Info(Info),
}

/// Manage generation & os info
#[derive(clap::Args, Debug)]
struct Info {
    #[command(subcommand)]
    cmd: InfoType,

    /// Which profile to use
    #[arg(long, default_value = "system")]
    profile: String,
}

#[derive(clap::Subcommand, Debug)]
enum InfoType {
    /// List current generation as json object
    Show,
    /// List all generations as json objects
    List,
    /// Formatting for /etc/issue
    Issue(IssueArgs),
}

impl Info {
    fn handle(self, measure_time: bool) -> Result<()> {
        let t_start = measure_time.then(std::time::Instant::now);
        trace!(?t_start);

        let profile = Profile::new(&self.profile).unwrap_or_default();
        trace!(info=?self);

        match self.cmd {
            InfoType::List => info_list(&profile, t_start),
            InfoType::Show => info_show(&profile, t_start),
            InfoType::Issue(issue) => issue.handle(&profile, t_start),
        }
    }
}

#[derive(clap::Args, Debug)]
struct IssueArgs {
    /// Configuration name
    #[arg(long, default_value = "Nixon")]
    variant_name: String,
    /// Override hostname [default: /etc/hostname]
    #[arg(long)]
    hostname: Option<String>,
    /// Override boot detection [default: auto-detect via systemctl]
    #[arg(long, num_args = 0..=1, default_missing_value = "true")]
    boot: Option<bool>,
    /// Write output to file instead of stdout [default path: /etc/issue]
    #[arg(long, default_missing_value = "/etc/issue", num_args = 0..=1)]
    write: Option<PathBuf>,
    /// run only at boot
    #[arg(long, group = "boot_mode")]
    only_boot: bool,
    /// if not at boot, defer prog by scheduling itself with systemd-run
    #[arg(long, group = "boot_mode")]
    defer: bool,
}
enum RunMode {
    Immediate,
    OnlyBoot,
    Defer,
}

impl IssueArgs {
    fn run_mode(&self) -> RunMode {
        match (self.only_boot, self.defer) {
            (true, _) => RunMode::OnlyBoot,
            (_, true) => RunMode::Defer,
            _ => RunMode::Immediate,
        }
    }

    fn handle(self, profile: &Profile, t_start: Option<Instant>) -> Result<()> {
        fn write_str(mut writer: &mut impl Write, s: &str, t_start: Option<Instant>) -> Result<()> {
            writeln!(&mut writer, "{s}")?;
            t_writeln!(&mut writer, t_start, "issue gen took")?;
            Ok(())
        }

        fn get_hostname(hostname: Option<String>) -> Result<String> {
            let hostname = hostname
                .or_else(|| {
                    std::fs::read_to_string("/etc/hostname")
                        .map(|s| s.trim().to_string())
                        .ok()
                })
                .ok_or_eyre("failed to read /etc/hostname; pass it manually");
            trace!(?hostname);
            hostname
        }

        let run_mode = self.run_mode();
        let Self {
            variant_name,
            hostname,
            boot,
            write,
            ..
        } = self;
        trace!(?variant_name);

        let is_boot = boot.unwrap_or_else(is_boot);
        trace!(?is_boot);

        match (run_mode, is_boot) {
            (RunMode::OnlyBoot, false) => {
                eprintln!("running only at boot!");
            }
            (RunMode::Defer, false) => {
                let exe = std::env::current_exe()?;
                let hostname = get_hostname(hostname)?;
                let mut cmd = std::process::Command::new("systemd-run");
                cmd.args(["--system", "--no-block", "--on-active=3s"]);
                cmd.arg(&exe);
                cmd.args(["info", "issue", "--hostname", &hostname, "--write"]);
                cmd.status()?;
            }
            (RunMode::Immediate, _) | (RunMode::OnlyBoot, true) | (RunMode::Defer, true) => {
                let curr = profile
                    .find_current_info()?
                    .ok_or_eyre("Couldn't find current generation!")?;

                let hostname = &get_hostname(hostname)?;

                let s = format_issue(
                    &curr,
                    IssueFormatArgs {
                        variant_name: &variant_name,
                        hostname,
                    },
                )
                .ok_or_eyre("failed to format issue!")?;

                if let Some(path) = write {
                    let file = std::fs::File::create(path)?;
                    let mut writer = std::io::BufWriter::new(file);
                    write_str(&mut writer, &s, t_start)?;
                } else {
                    let stdout = std::io::stdout().lock();
                    let mut writer = std::io::BufWriter::new(stdout);
                    write_str(&mut writer, &s, t_start)?;
                }
            }
        };
        Ok(())
    }
}

fn info_list(profile: &Profile, t_start: Option<Instant>) -> Result<()> {
    let sysinfos = {
        let mut v = profile.collect_info()?;
        v.sort_unstable_by_key(|x| x.generation.id());
        v
    };
    let stdout = std::io::stdout().lock();
    let mut writer = std::io::BufWriter::new(stdout);
    for i in sysinfos {
        serde_json::to_writer_pretty(&mut writer, &i)?;
        writeln!(writer)?;
    }
    t_writeln!(&mut writer, t_start)?;
    Ok(())
}

fn info_show(profile: &Profile, t_start: Option<Instant>) -> Result<()> {
    let curr = profile
        .find_current_info()?
        .ok_or_else(|| eyre!("Coudln't find current generation!"))?;
    let stdout = std::io::stdout().lock();
    let mut writer = std::io::BufWriter::new(stdout);
    serde_json::to_writer_pretty(&mut writer, &curr)?;
    t_writeln!(&mut writer, t_start)?;
    Ok(())
}

fn run(args: Cli) -> Result<()> {
    match args.cmd {
        Cmd::Info(info) => info.handle(args.timed),
    }?;
    Ok(())
}

fn main() -> Result<()> {
    color_eyre::install()?;
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    run(Cli::parse())
}
