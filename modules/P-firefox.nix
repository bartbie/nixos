{ lib, ... }:
let
  mkLock = Value: {
    inherit Value;
    Status = "locked";
  };
  lock-false = mkLock false;
  lock-true = mkLock true;
  lock-empty-string = mkLock "";

  common =
    { pkgs, ... }:
    {
      programs.firefox = {
        package = pkgs.firefox-devedition;
        enable = true;
        policies = {
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          DontCheckDefaultBrowser = true;
          DisablePocket = true;
          NoDefaultBookmarks = true;
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
          };
          Cookies = {
            Behavior = "reject-tracker-and-partition-foreign";
          };
          HttpsOnlyMode = "enabled";
          SanitizeOnShutdown = true;
          OfferToSaveLogins = false;
          PasswordManagerEnabled = false;
          DisableFormHistory = false;
          CaptivePortal = false;
          DisplayBookmarksToolbar = "newtab";
          SearchBar = "unified";
          OverridePostUpdatePage = "";
          OverrideFirstRunPage = "";
          Homepage = {
            URL = "about:blank";
            StartPage = "previous-session";
          };
          ExtensionSettings =
            let
              mapAddons =
                let
                  defaults = {
                    installation_mode = "force_installed";
                  };
                  addAddon =
                    name:
                    {
                      version ? "latest",
                      ...
                    }@opts:
                    {
                      install_url = "https://addons.mozilla.org/firefox/downloads/latest/${name}/${version}.xpi";
                    }
                    // defaults
                    // lib.filterAttrs (
                      n: _:
                      !(builtins.elem n [
                        "version"
                        "id"
                      ])
                    ) opts;

                  transformOpts =
                    name: opts: addAddon name (lib.optionalAttrs (builtins.typeOf opts != "string") opts);

                  coerceId = _: val: if builtins.typeOf val == "string" then val else val.id;
                in
                lib.mapAttrs' (k: val: lib.nameValuePair (coerceId k val) (transformOpts k val));
            in
            mapAddons {
              "ublock-origin" = "uBlock0@raymondhill.net";
              "bitwarden-password-manager" = "{446900e4-71c2-419f-a6a7-df9c091e268b}";
              "darkreader" = "addon@darkreader.org";

              "google-container" = "@contain-google";
              "facebook-container" = "@contain-facebook";
              "multi-account-containers" = "@testpilot-containers";

              "sidebery" = "{3c078156-979c-498b-8990-85f7987dd929}";
              "sort-tabs-advanced" = "{d6f02b92-88b3-4aa5-ba7c-14519042171d}";

              "videospeed" = "{7be2ba16-0f1e-4d93-9ebc-5164397477a9}";
              "sponsorblock" = "sponsorBlocker@ajay.app";
              "dearrow" = "deArrow@ajay.app";
              # Unhook - good when showcasing smth on yt
              "youtube-recommended-videos" = "myallychou@gmail.com";
              # PocketTube
              "youtube-subscription-groups" = "danabok16@gmail.com";
              "return-youtube-dislikes" = "{762f9885-5a13-4abd-9c77-433dcd38b8fd}";

              "vimium-ff" = "{d7742d87-e61d-4b78-b8a1-b469842139fa}";

              "old-reddit-redirect" = "{9063c2e9-e07c-4c2c-9646-cfe7ca8d0498}";
              # i will NOT be using your CSS when i need to find something.
              "reddit-enhancement-suite" = "jid1-xUfzOsOFlzSOXg@jetpack";

              "search_by_image" = "{2e5ff8c8-32fe-46d0-9fc8-6b8986621f3c}";

              "to-google-translate" = "jid1-93WyvpgvxzGATw@jetpack";
              # TWP - Translate Web Pages
              "traduzir-paginas-web" = "{036a55b4-5e72-4d05-a06c-cba2dfcc134a}";

              "react-devtools" = "@react-devtools";
            };
        };
        preferences = {
          # Privacy settings
          "extensions.pocket.enabled" = false;
          "browser.topsites.contile.enabled" = false;
          "browser.aboutConfig.showWarning" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.system.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.default.sites" = "";
          "extensions.getAddons.showPane" = false; # uses Google Analytics
          "extensions.htmlaboutaddons.recommendations.enabled" = false;
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.server" = "data:,";
          "toolkit.telemetry.archive.enabled" = false;
          "toolkit.telemetry.newProfilePing.enabled" = false;
          "toolkit.telemetry.shutdownPingSender.enabled" = false;
          "toolkit.telemetry.updatePing.enabled" = false;
          "toolkit.telemetry.bhrPing.enabled" = false;
          "toolkit.telemetry.firstShutdownPing.enabled" = false;
          "browser.send_pings" = false;
        };
      };
    };
in
{
  flake.modules = {
    nixos.pc = common;
    darwin.base = common;
  };
}
