# CLAUDE.md

Rules for working on VESC Scooter Support. Follow these exactly.

## What this is

One VESC package that supports multiple scooter dashboards and slave ESCs from a single
LispBM script (`scooter_support.lisp`). The model (G30, M365/1S/PRO2, Slave) is chosen in
the QML UI and stored in EEPROM — never in separate script variants.

## Comments (LispBM and everywhere else)

- No unnecessary comments. Write comments the way Izuna does — look at the existing
  scripts before writing any: short `;` comments that explain intent, not mechanics
  (`; beep feedback`, `; turn off light when locking`), section markers like
  `; -> Code starts here`, and a header comment with version, credits, wiring and guide links.
- Never comment what the code already says, never leave notes about why a change was made
  (that belongs in the commit message), never add filler like "this function does X".
- Protocol byte layouts are the exception: frame offsets and CRC quirks deserve a comment,
  because they cannot be read from the code (`; Frame 0x64`, `; 255/3.3 = 77.2`).

## QML / UX

- No description or explanation labels. They waste space on mobile. Every control gets a
  short, straightforward label that is understandable on its own (`Start Speed (km/h)`,
  not a paragraph about what start speed does).
- The UI runs on phones inside VESC Tool: tightly packed, TabBar + SwipeView, action
  buttons (Load/Save/Reset) always visible at the bottom, never buried at the end of a scroll.
- Do not bother users with technical internals. Speak in their terms: power ratings of
  profiles, button combination for the secret profile (later), cruise control (later),
  idle timeout (shut down after X seconds of inactivity), rear light, and so on.
- Every new setting lands in the tab/group where it belongs. Never append controls loosely
  at the end because it is easier.

## Build

- `make` produces `vesc_scooter_support.vescpkg` (needs `vesc_tool` on PATH or
  `VESC_TOOL=/path/to/vesc_tool`).
- Test the built package in VESC Tool before releasing anything.
