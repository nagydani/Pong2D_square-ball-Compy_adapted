-- constants.lua

-- Configuration and Layout

-- Colors (RGB)

COLOR_BG = {
  0,
  0,
  0
}
COLOR_FG = {
  0.8,
  0.8,
  0.8
}
COLOR_WHITE = {
  1,
  1,
  1
}

COLOR_FIELD = {
  0.1,
  0.1,
  0.1
}
COLOR_GRID = {
  0.3,
  0.3,
  0.3
}

COLOR_BUMP_TOP = {
  0.6,
  0.6,
  0.6
}
COLOR_BUMP_L = {
  0.4,
  0.4,
  0.4
}
COLOR_BUMP_R = {
  0.4,
  0.4,
  0.4
}

COLOR_PAD_P = {
  0.2,
  0.4,
  1
}
COLOR_PAD_P_SIDE = {
  0.1,
  0.2,
  0.5
}
COLOR_PAD_OPP = {
  1,
  0.2,
  0.2
}
COLOR_PAD_OPP_SIDE = {
  0.5,
  0.1,
  0.1
}

COLOR_BALL = {
  1,
  1,
  1
}
COLOR_BALL_SIDE = {
  0.5,
  0.5,
  0.5
}

GAME = {
  width = 640,
  height = 480,
  speed_scale = 1.5,
  score_win = 10,
  score_off_y = 20,
  ai_deadzone = 4,
  elasticity = 0.5
}
GAME.zone_width = GAME.width / 4

GRID_VIEW = {
  rows = 12,
  cols = 8
}

PADDLE = {
  size = {
    x = 10,
    y = 60
  },
  height = 45,
  speed = 180 * GAME.speed_scale,
  off_x = 0
}
PADDLE.half_y = PADDLE.size.y / 2

BALL = {
  radius = 15,
  height = 15
}

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
    max = GAME.zone_width - PADDLE.size.x
  },
  opp = {
    min = GAME.width - GAME.zone_width,
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
  strike_dist = 140,
  serve_threshold = 10,
  dead_x = 2,
  dead_y = GAME.ai_deadzone
}

-- Perspective Configuration

VIEW = {
  s = 0.67,
  d = 600,
  xm = 300,
  ym = -(GAME.height / 2),
  h = 355,
  c = {
    x = GAME.width / 2,
    y = 0
  }
}

-- Bumper parameters

BUMPER = {
  height = 30,
  depth = 60
}
