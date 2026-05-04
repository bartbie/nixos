# toggle: [un]bind usb-audio interfaces of any device that ALSO
# exposes a uvc video interface - i.e. webcam mics, regardless of
# vendor. class 0e = video, class 01 = audio. only act on the Audio
# Control interface (subclass 01) - it is the binding root, sibling
# Audio Streaming interfaces (subclass 02) follow it automatically and
# crash bind/unbind writes if hit directly.
set -euo pipefail
acted=0
for dev in /sys/bus/usb/devices/*/; do
  base=$(basename "$dev")
  has_video=0
  for iface in "$dev"$base:*; do
    [[ -d $iface ]] || continue
    class=$(cat "$iface/bInterfaceClass" 2>/dev/null || echo "")
    if [[ $class == "0e" ]]; then has_video=1; break; fi
  done
  [[ $has_video == 1 ]] || continue
  product=$(cat "$dev/product" 2>/dev/null || echo "unknown")
  for iface in "$dev"$base:*; do
    [[ -d $iface ]] || continue
    class=$(cat "$iface/bInterfaceClass" 2>/dev/null || echo "")
    subclass=$(cat "$iface/bInterfaceSubClass" 2>/dev/null || echo "")
    [[ $class == "01" && $subclass == "01" ]] || continue
    name=$(basename "$iface")
    if [[ -e $iface/driver ]]; then
      echo "$name" > /sys/bus/usb/drivers/snd-usb-audio/unbind
      echo "killed: $name ($product)"
    else
      echo "$name" > /sys/bus/usb/drivers/snd-usb-audio/bind
      echo "restored: $name ($product)"
    fi
    acted=1
  done
done
if [[ $acted == 0 ]]; then
  echo "no webcam with audio interface found" >&2
  exit 1
fi
