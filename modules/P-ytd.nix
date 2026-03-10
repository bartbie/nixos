{ nixonLib, ... }:
{
  wrapped.mpv.module =
    { pkgs-unstable, ... }:
    {
      wrappers = nixonLib.pkgh.mapArg0 pkgs-unstable.yt-dpl "yt-dpl" {
        ytd-audio.prependArgs = [
          "-t"
          "mp3"
        ];
        ytd-video.prependArgs = [
          "-t"
          "mp4"
        ];
      };
    };
}
