#!/usr/bin/env nu
use std/dirs
use std/log

def try_or_exit [f: closure] {
  try {
    f
  } catch { |err|
    log error $err
    exit 1
  }
}

def exit_if_error [code: int = 1] {
  if $env.LAST_EXIT_CODE != 0 {
    exit 1
  }
}

# print but to stderr
def eprint [...args: any]: any -> nothing {
  $in | print -e ...$args
}


# open $EDITOR
def open-editor [] {
      try {
        eprint $"running $EDITOR (($env.EDITOR))"
        run-external $env.EDITOR
      } catch { ||
        eprint "Couldn't run the $EDITOR."
        eprint "Continuing."
      }
}

# any uncommited changes?
def any_changes [jj: bool] {
    #  jj can be sometimes faster?
    if $jj {
      return ((jj diff) != "")
    }
    try {
      git diff HEAD --quiet o+e> /dev/null
      return false
    }
    return true
}

# run system rebuild
def rebuild [dry: bool, nh: bool, log_file_path: string] {
    if $dry {
      eprint "NixOS Rebuilding... (dry)"
      return
    }
    eprint "NixOS Rebuilding..."
    if $nh {
      nh os switch
    } else {
      # Rebuild, output simplified errors, log trackebacks
      nixos-rebuild switch ---use-remote-host o+e> $log_file_path
      open nixos-switch.log | find error | print
    }
    exit_if_error 1

}

# commit the changes
def commit [dry: bool, jj: bool, custom_msg: bool, --no-timezone] {
  let msg = if not $custom_msg {
    def parse-date [no_timezone: bool]: string -> string {
      if $no_timezone {
        $in
      } else {
        $in | date to-timezone local
      } | format date "%F %R %z"
    }
    # Get current generation metadata
    let current = (
      nixos-rebuild list-generations --json
      | from json
      | where $it.current == true
      | do {
        let row = $in | get 0
        let gen = $row.generation | into string
        let date = $row.date | parse-date $no_timezone
        let ver = $row.nixosVersion | split row '.' | get 0 1 | str join "."
        let krnl = $row.kernelVersion
        [$gen, $date, $ver, $krnl] | str join "|"
      }
    )
    $current
  } else {
    null
  }

  def print-msg [msg?: string] {
    if $msg != null and msg != "" {
      eprint $"Commit name: ($msg)"
    }
  }

  if not $jj {
    print-msg $msg
    if $dry {
      return
    }
    git commit -am $msg
  }

  def jj-commit [msg?: string, --dry] {
    if $dry {return}
    if $msg != null {
      jj commit -m $msg
    } else {
      jj commit
    }
  }

  let jj_msg = jj log -r "@" --no-graph | lines | get 1
  if $jj_msg == "(no description set)" {
    print-msg $msg
    jj-commit $msg --dry=$dry
  } else {
    eprint $"Description already set: ($jj_msg)."
    jj-commit --dry=$dry
  }
}

def main [
  flake: path = /etc/nixos, # Where is the config located
  log_file_path: path = ./nixos-switch.log, # where to save log file, not used with nh
  --jj=true, # Use jujutsu
  --nh=true, # Use nh
  --open-editor=true, # Open $EDITOR in (flake)
  --format=true, # Format code beforehand
  --commit=true, # Commit afterwards
  --show-diff=true, # Show VCS diff
  --custom-msg, # Write custom message in VCS, otherwise use generation metadata
  --no-timezone, # When generating commit message, don't give timezone away
  --dry, # Fake effectful operations
]: nothing -> nothing {
  try {
    dirs add $flake

    if $open_editor {
      open-editor
    }

    if not (any_changes $jj) {
      eprint "No changes detected, exiting."
      exit 1
    }

    if $format {
      if not $dry {
        eprint "Running formatter."
        nix fmt .
      } else {
        eprint "Running formatter. (dry)"
      }
    }

    if $show_diff {
      if $jj {
        jj show
      } else {
        git diff HEAD
      }
    }

    rebuild $dry $nh $log_file_path

    if $commit {
      commit $dry $jj $custom_msg --no-timezone=$no_timezone
    }

    let goodbye = if not $dry {"NixOS Rebuilt OK!"} else {"NixOS Rebuilt OK (dry)!"}
    print $goodbye
    try {
      notify-send -e $goodbye --icon=software-update-available e+o>| ignore
    }

  } catch { |err|
   eprint $err.rendered
  }
}
