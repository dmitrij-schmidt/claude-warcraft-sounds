#!/usr/bin/env bash
# Turn-duration gate for the Stop sound.
#
#   turn-timer.sh start            hooked to UserPromptSubmit; records turn start
#   turn-timer.sh stop <file.wav>  hooked to Stop; plays only if the turn ran long
#
# Threshold: CLAUDE_WARCRAFT_STOP_MIN_SECONDS (default 30).
# The point is to stay quiet on quick turns you are watching live, and only
# speak up when the turn ran long enough that you probably wandered off.
set -u

[ "${CLAUDE_WARCRAFT_SOUNDS:-1}" = "0" ] && exit 0

root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
state_dir="${TMPDIR:-/tmp}/claude-warcraft-sounds-$(id -u)"
mkdir -p "$state_dir" 2>/dev/null || exit 0

# Pull session_id out of the hook payload without spawning jq. It is a plain
# JSON string (a uuid), so a regex is sufficient and costs no subprocess.
payload=$(cat)
if [[ $payload =~ \"session_id\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
  session="${BASH_REMATCH[1]}"
else
  session="nosession"
fi
stamp="$state_dir/${session//[^a-zA-Z0-9_-]/_}"

case "${1:-}" in
  start)
    date +%s > "$stamp"
    ;;
  stop)
    [ $# -ge 2 ] || exit 0
    [ -f "$stamp" ] || exit 0
    started=$(cat "$stamp" 2>/dev/null)
    rm -f "$stamp"
    case "$started" in ''|*[!0-9]*) exit 0 ;; esac
    elapsed=$(( $(date +%s) - started ))
    [ "$elapsed" -ge "${CLAUDE_WARCRAFT_STOP_MIN_SECONDS:-30}" ] || exit 0
    "$root/scripts/play.sh" "$2"
    ;;
esac
exit 0
