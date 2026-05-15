# Shufflepuck Café (pong3d) 

An air-hockey-style game for the Compy platform, rendered in a
3D perspective view. Built on LÖVE2D.

The player controls the front paddle (mouse or keyboard); the
back paddle is either an AI opponent or a second local player.

---

## Files

- **constants.lua** — sizes, colors, speeds, AI tuning,
  perspective parameters.
- **physics.lua** — swept (continuous) collision detection
  between the ball and paddles, and impulse-based bounce
  resolution.
- **strategy.lua** — opponent behavior: easy AI, hard AI,
  and manual control for a second player.
- **main.lua** — entry point, game state, update/draw loop,
  input handling, and perspective rendering.

---

## Controls

Player paddle:
- **Mouse** (relative mode) or **W / A / S / D**.

Second player paddle (manual mode only):
- **Arrow keys**.

Menu and game flow:
- **Space** — start a round, or restart after Game Over.
- **R** — reset the score and return to the start screen.
- **1** — toggle Easy / Hard AI.
- **2** — switch to two-player (manual) mode.
- **E** — force Easy mode.
- **Pause** — pause / un-pause the game.
- **Shift + Esc** — quit.

Plain Esc does not quit, because on Android a right mouse
click generates an Esc keypress at the kernel level.

---

## Game rules

First side to reach 10 points wins. A point is scored when the
ball passes behind the opponent's paddle. After each point the
ball is served from alternating sides.

The game starts in single-player Easy mode by default.

---

## Architecture notes

All mutable state lives in a single global table `GS`. The game
runs as a simple `love.update(dt)` loop — no fixed-timestep
accumulator. Collision detection is swept, so the ball cannot
tunnel through paddles at high speeds.

The 3D perspective is a simple projection from a virtual
640×480 play field onto the screen, applied per-vertex via
`project(x, y)` in `main.lua`. Drawing is layered: floor and
grid first, then paddles and ball in depth order, then UI on
top.
