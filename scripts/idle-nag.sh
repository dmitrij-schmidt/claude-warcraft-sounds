#!/usr/bin/env bash
# Repeating nag for the idle prompt.
#
#   idle-nag.sh start <file.wav>   hooked to Notification/idle_prompt
#   idle-nag.sh stop               hooked to UserPromptSubmit and SessionEnd
#
# Plays once immediately, then repeats every
# CLAUDE_WARCRAFT_IDLE_REPEAT_SECONDS (default 45) up to
# CLAUDE_WARCRAFT_IDLE_MAX_REPEATS times (default 5), then gives up --
# past that point you are genuinely away and sound is the wrong tool.
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
pidfile="$state_dir/nag-${session//[^a-zA-Z0-9_-]/_}.pid"

cancel() {
  [ -f "$pidfile" ] || return 0
  local pid; pid=$(cat "$pidfile" 2>/dev/null)
  rm -f "$pidfile"
  case "$pid" in ''|*[!0-9]*) return 0 ;; esac
  kill "$pid" 2>/dev/null
}

case "${1:-}" in
  start)
    [ $# -ge 2 ] || exit 0
    cancel   # never stack two nags on one session
    (
      "$root/scripts/play.sh" "$2"
      n=0
      while [ "$n" -lt "${CLAUDE_WARCRAFT_IDLE_MAX_REPEATS:-5}" ]; do
        sleep "${CLAUDE_WARCRAFT_IDLE_REPEAT_SECONDS:-45}"
        [ -f "$pidfile" ] || exit 0
        "$root/scripts/play.sh" "$2"
        n=$((n + 1))
      done
      rm -f "$pidfile"
    ) >/dev/null 2>&1 &
    echo $! > "$pidfile"
    disown 2>/dev/null
    ;;
  stop)
    cancel
    ;;
esac
exit 0
