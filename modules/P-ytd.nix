{ nixonLib, ... }:
{
  wrapped.mpv.module =
    { pkgs-unstable, ... }:
    {
      wrappers = nixonLib.pkgh.mapArg0 pkgs-unstable.yt-dlp "yt-dlp" {
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
