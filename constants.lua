-- constants.lua
-- Configuration and Layout

COLORS = {
  bg = Color[Color.black],
  fg = Color[Color.white + Color.bright]
}

GAME = {
  width = 640,
  height = 480,
  speed_scale = 1.5,
  score_win = 10,
  score_off_y = 20,
  ai_deadzone = 4,
  elasticity = 0.8
}

GRID = {
  width = 4,
  dash = 10,
  gap = 20
}

PADDLE = {
  size = {
    x = 10,
    y = 60
  },
  speed = 180 * GAME.speed_scale,
  off_x = 0
}
PADDLE.half_y = PADDLE.size.y / 2

BALL = { radius = 10 }

-- Dynamic geometry

LAYOUT = {
  pad_start_y = (GAME.height - PADDLE.size.y) / 2,
  serve_pos_player = {
    x = GAME.width / 6,
    y = GAME.height / 2
  }
}

LAYOUT.serve_pos_opp = {
  x = (GAME.width - LAYOUT.serve_pos_player.x),
  y = LAYOUT.serve_pos_player.y
}

LIMITS = {
  player = {
    min = PADDLE.off_x,
    max = (GAME.width / 4) - PADDLE.size.x
  },
  opp = {
    min = GAME.width - (GAME.width / 4),
    max = (GAME.width - PADDLE.off_x) - PADDLE.size.x
  },
  y_max = GAME.height - PADDLE.size.y
}

-- AI Configuration

AI = {
  noise_freq = 1.5,
  noise_range = PADDLE.size.y * 0.9,
  noise_offset = 0.5,
  speed_easy = 120,
  speed_hard = 270,
  wall_x = LIMITS.opp.max,
  attack_x = LIMITS.opp.max - 150,
  t_attack = 0.6,
  dead_x = 2,
  dead_y = GAME.ai_deadzone
}
