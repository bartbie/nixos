{
  lib,
  theme,
  ...
}:
{
  flake.modules.nixos.base =
    {
      config,
      pkgs,
      ...
    }:
    let
      script =
        let
          inherit (config.system.nixos) variantName codeName release;
          inherit (config.networking) hostName;
          kernelVer = config.boot.kernelPackages.kernel.version;
          dyn-short-release = ''(.nixosVersion | split(".")[0:2] | join("."))'';
          dyn-long-release = "(.nixosVersion)";
        in
        # bash
        ''
          export START_TIME=$(${pkgs.coreutils}/bin/date +%s%N)

          export HOSTNAME=$(${pkgs.nettools}/bin/hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || echo ${hostName})

          # rfc 3339
          export CURRENT_DATE=$(${pkgs.coreutils}/bin/date --rfc-3339=seconds)

          # check if we are running during boot or rebuild
          export IS_BOOT=$(${pkgs.systemd}/bin/systemctl is-active --quiet multi-user.target 2>/dev/null && echo 0 || echo 1)

          ${lib.getExe pkgs.nixos-rebuild} list-generations --json 2>/etc/issue2 \
          | ${lib.getExe pkgs.jq} -r '
            def format_to_rfc3339: strptime("%Y-%m-%d %H:%M:%S")
              | strflocaltime("%Y-%m-%d %H:%M:%S%z")
              | sub("(?<hours>[+-][0-9]{2})(?<minutes>[0-9]{2})$"; "\(.hours):\(.minutes)");

            def is_boot: env.IS_BOOT == "1";

            map(select(.current == true))
            | .[0]
            | .kernelVersion |= if . == "Unknown" then null else . end
            | .kernelVersion //= "${kernelVer}"
            | .generation |= if is_boot then . else . + 1 end
            | (.date |= if is_boot then . | format_to_rfc3339 else env.CURRENT_DATE end)
            | [
                "Welcome to ${variantName} @ \(env.HOSTNAME)",
                (
                  [
                    "ver:",
                    (if ${dyn-short-release} == "${release}" then "\(${dyn-long-release}) (${codeName})" else ${dyn-long-release} end),
                    .kernelVersion
                  ]
                  | join(" ")
                ),
                (
                  [
                    "gen:",
                    (.generation | tostring),
                    .date,
                    (if is_boot then empty else "(approx.)" end)
                  ]
                  | join(" ")
                ),
                (.specialisations | (if . == [] then empty else [ "spec:" ] + . end) | join(" ")),
                (if .kernelVersion == "${kernelVer}" then empty else "kernel version mismatch; flake: ${kernelVer}" end),
                (
                  [
                    "issue:",
                    (if is_boot then "[boot]" else "[rebuild]" end)
                  ]
                  | join(" ")
                )
              ]
            | join("\n")
          ' > /etc/issue

          END_TIME=$(${pkgs.coreutils}/bin/date +%s%N)
          DURATION_MS=$(( (END_TIME - START_TIME) / 1000000 ))
          # remove newline
          truncate -s -1 /etc/issue
          printf " %d.%03ds (approx.)\n" $((DURATION_MS/1000)) $((DURATION_MS%1000)) >> /etc/issue
          echo "" >> /etc/issue
          ls -la /nix/var/nix/profiles/ >> /etc/issue
        '';
    in
    {
      system.nixos.variantName = "Nixon";

      # TODO: replace script with better program not depending on nixos-rebuild
      # environment.etc.issue.enable = lib.mkForce false;

      # system.activationScripts.update-issue = {
      #   text = assert (builtins.match ".*(,[:space:]*])+.*" script) == null;
      #   # assert correct list syntax - no , on last element
      #     script;
      # };
    };

  flake.modules.nixos.pc =
    { pkgs, ... }:
    {
      boot = {
        loader = {
          systemd-boot = {
            enable = lib.mkDefault true;
            configurationLimit = 10;
            consoleMode = "max";
            # consoleMode = "auto";
          };
        };

        kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
      };
      # console.colors = let
      #   colors = theme.termcolors.simple.lists;
      # in
      #   (colors.ansi ++ colors.brights)
      #   |> builtins.map (lib.removePrefix "#");
    };
}
