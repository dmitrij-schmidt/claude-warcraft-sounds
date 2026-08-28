#!/usr/bin/env bash
# Play one sound from media/. Usage: play.sh <filename.wav>
# Set CLAUDE_WARCRAFT_SOUNDS=0 to mute the whole plugin.
set -u

[ "${CLAUDE_WARCRAFT_SOUNDS:-1}" = "0" ] && exit 0
[ $# -ge 1 ] || exit 0

root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
sound="$root/media/$1"
[ -f "$sound" ] || exit 0

play() {
  case "$1" in
    afplay)  afplay "$sound" ;;
    paplay)  paplay "$sound" ;;
    pw-play) pw-play "$sound" ;;
    aplay)   aplay -q "$sound" ;;
    ffplay)  ffplay -nodisp -autoexit -loglevel quiet "$sound" ;;
    mpv)     mpv --no-video --really-quiet "$sound" ;;
    cvlc)    cvlc --play-and-exit --quiet "$sound" ;;
  esac
}

for p in afplay pw-play paplay aplay ffplay mpv cvlc; do
  if command -v "$p" >/dev/null 2>&1; then
    play "$p" >/dev/null 2>&1 &
    exit 0
  fi
done
exit 0
