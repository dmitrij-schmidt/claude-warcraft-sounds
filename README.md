# claude-warcraft-sounds

A [Claude Code](https://code.claude.com) plugin that plays Warcraft dwarf voice
lines on lifecycle events, so you can tell what a session is doing without
looking at it. Built for running Claude Code on one machine while working on
another, with the first machine's headphones on.

## Install

```
/plugin marketplace add dmitrij-schmidt/claude-warcraft-sounds
/plugin install claude-warcraft-sounds@warcraft-sounds
```

For local development: `claude --plugin-dir /path/to/clone`.

Needs Linux or macOS, bash 4+, and one of `afplay`, `pw-play`, `paplay`,
`aplay`, `ffplay`, `mpv`, `cvlc`. If no player is found it exits silently.
Windows needs WSL.

## Event mapping

| Hook event | Matcher | Sound |
|---|---|---|
| `SessionStart` | — | `DwarfMaleHello04.wav` |
| `SessionEnd` | — | `DwarfMaleGoodbye03.wav` |
| `UserPromptSubmit` | — | *silent — starts the turn timer, cancels the idle nag* |
| `StopFailure` | — | `DwarfMaleIncoming02.wav` |
| `PermissionDenied` | — | `DwarfMale_err_guildpermissions01.wav` |
| `Notification` | `idle_prompt` | `RiflemanWhat2.wav`, repeating |
| `PermissionRequest` | — | `DwarfMale_err_guildpermissions04.wav` |
| `PreToolUse` | `AskUserQuestion` | `DwarfMaleHelp02.wav` |
| `PreToolUse` | `ExitPlanMode` | `GyrocopterReady1.wav` |
| `Stop` | — | `HeroMountainKingWhat3.wav`, if the turn ran ≥ 30s |
| `TaskCompleted` | — | `RiflemanReady1.wav` |
| `TeammateIdle` | — | `DwarfMaleYawn01.wav` |

`Stop` only plays if the turn ran at least 30s, so short turns stay silent.
The idle prompt repeats every 45s, five times, then gives up; answering it or
ending the session cancels it.

`AskUserQuestion` and `ExitPlanMode` are tools rather than hook events, hence
the `PreToolUse` matchers. `Notification` is scoped to `idle_prompt` so it does
not double-fire with `PermissionRequest`. All hooks are `async` and exit `0` on
failure, so none of this can block or break a session.

## Configuration

| Variable | Default | Effect |
|---|---|---|
| `CLAUDE_WARCRAFT_SOUNDS` | `1` | `0` mutes everything without uninstalling |
| `CLAUDE_WARCRAFT_STOP_MIN_SECONDS` | `30` | Minimum turn length before `Stop` plays |
| `CLAUDE_WARCRAFT_IDLE_REPEAT_SECONDS` | `45` | Gap between idle-prompt repeats |
| `CLAUDE_WARCRAFT_IDLE_MAX_REPEATS` | `5` | Repeats before the nag gives up |

## Layout

```
.claude-plugin/plugin.json       plugin manifest
.claude-plugin/marketplace.json  marketplace manifest (the repo lists itself)
hooks/hooks.json                 event -> sound wiring
scripts/play.sh                  audio backend shim
scripts/turn-timer.sh            turn-duration gate for Stop
scripts/idle-nag.sh              repeating idle-prompt nag
media/*.wav                      11 sound files
```

Transient state (turn timestamps, nag PIDs) lives in
`$TMPDIR/claude-warcraft-sounds-$UID/`, keyed by session id, and is safe to
delete at any time.

## Notes and caveats

- Sound comes out of the machine **running Claude Code**. Over SSH with no
  audio socket, a player is found and plays to nothing — a silent failure.
- There is no remote-notification path — out of earshot means no signal.
- Developed against PipeWire on Debian-based Linux. Other players and macOS
  should work but have not been exercised.

## Troubleshooting

**No sound.** Confirm a player exists, then test the shim directly:

```bash
CLAUDE_PLUGIN_ROOT="$PWD" ./scripts/play.sh DwarfMaleHello04.wav
```

**`Stop` never fires.** Usually correct — turns under 30s are gated. Set
`CLAUDE_WARCRAFT_STOP_MIN_SECONDS=0` to confirm the wiring.

**Stuck nag loop.** `rm -rf "${TMPDIR:-/tmp}/claude-warcraft-sounds-$(id -u)"`
and `pkill -f idle-nag.sh`.

## Assets and licensing

The code is Beerware — see [LICENSE](LICENSE). **The sounds are not.**

`media/` holds ripped audio from *Warcraft III: Reign of Chaos* and *World of
Warcraft*, via The Spriters Resource
([WC3](https://sounds.spriters-resource.com/pc_computer/warcraft3reignofchaos),
[WoW](https://sounds.spriters-resource.com/pc_computer/worldofwarcraft)). Their
terms allow non-commercial use with credit to the source. Blizzard Entertainment
owns the underlying audio; The Spriters Resource cannot license it, and no
license to it is granted here.

This is a non-commercial fan project with no affiliation to or endorsement by
Blizzard, and the sounds will be removed on request from the rightsholder.

To run it on audio you hold the rights to, drop your own files into `media/` and
point `hooks/hooks.json` at them; no code changes are needed.
