-- main.lua
-- Entry point, State Management, and Game Loop

require("constants")
require("physics")
require("strategy")

sfx = compy.audio
gfx = love.graphics
timer = love.timer

-- Game State 

GS = {
  init = false,
  mode = "start",
  input = "mouse",
  tf = nil
}

GS.assets = {
  text_player = nil,
  text_opponent = nil,
  text_info = nil,
  text_mode = nil
}

GS.score = {
  player = 0,
  opponent = 0
}

GS.mouse = {
  x = 0,
  y = 0
}
GS.ai = strategy.hard

-- Entities (Unified Vectors: pos, vel, size)

GS.player = {
  color = COLOR_PAD_P,
  color_side = COLOR_PAD_P_SIDE,
  pos = {
    x = 0,
    y = 0
  },
  vel = {
    x = 0,
    y = 0
  },
  size = PADDLE.size,
  limits = LIMITS.player,
  speed = PADDLE.speed
}

GS.opponent = {
  color = COLOR_PAD_OPP,
  color_side = COLOR_PAD_OPP_SIDE,
  pos = {
    x = 0,
    y = 0
  },
  vel = {
    x = 0,
    y = 0
  },
  size = PADDLE.size,
  limits = LIMITS.opp,
  speed = AI.speed_hard
}

GS.ball = {
  color = COLOR_BALL,
  color_side = COLOR_BALL_SIDE,
  pos = {
    x = 0,
    y = 0
  },
  vel = {
    x = 0,
    y = 0
  },
  radius = BALL.radius,
  snapshot = {
    x = 0,
    y = 0
  },
  st = 0
}

GS.paddles = {
  GS.player,
  GS.opponent
}

-- Helpers 

function get_key_direction(key_check, key_pos, key_neg)
  if key_check(key_pos) then
    return 1
  end
  if key_check(key_neg) then
    return -1
  end
  return 0
end

function clamp(value, min_val, max_val)
  return math.max(min_val, math.min(value, max_val))
end

function center_text_x(text)
  return (GAME.width - text:getWidth()) / 2
end

function copy_vector(dest, src)
  dest.x = src.x
  dest.y = src.y
end

function integrate_position(pos, vel, dt)
  pos.x = pos.x + vel.x * dt
  pos.y = pos.y + vel.y * dt
end

function update_scale()
  local w, h = gfx.getDimensions()
  local sx = w / GAME.width
  local sy = h / GAME.height
  GS.tf = love.math.newTransform():scale(sx, sy)
end

function sync_phys(now)
  local b = GS.ball
  copy_vector(b.snapshot, b.pos)
  b.st = now
end

function move_ball_time(t_target)
  local b = GS.ball
  local dt = t_target - b.st
  copy_vector(b.pos, b.snapshot)
  integrate_position(b.pos, b.vel, dt)
end

function reset_ball_pos(serve_vector)
  local b = GS.ball
  local serve = serve_vector or LAYOUT.serve_pos_player
  copy_vector(b.pos, serve)
  b.vel.x, b.vel.y = 0, 0
end

function get_strat_name()
  if GS.ai == strategy.manual then 
    return "2 Players (Manual)" 
  end
  if GS.ai == strategy.easy then 
    return "1 Player (Easy)" 
  end
  return "1 Player (Hard)"
end

function update_ui()
  GS.assets.text_player:set(GS.score.player)
  GS.assets.text_opponent:set(GS.score.opponent)
  GS.assets.text_mode:set(get_strat_name())
end

function reset_round(now)
  GS.player.pos.x = LIMITS.player.min
  GS.player.pos.y = LAYOUT.pad_start_y
  GS.opponent.pos.x = LIMITS.opp.max
  GS.opponent.pos.y = LAYOUT.pad_start_y
  local is_player = (GS.score.player + GS.score.opponent) % 2
       == 0
  local serve = is_player and LAYOUT.serve_pos_player
       or LAYOUT.serve_pos_opp
  reset_ball_pos(serve)
  sync_phys(now)
end

-- Init 

function init_assets()
  local f = gfx.getFont()
  GS.assets.text_info = gfx.newText(f, "Press Space to Start")
  GS.assets.text_player = gfx.newText(f, "0")
  GS.assets.text_opponent = gfx.newText(f, "0")
  GS.assets.text_mode = gfx.newText(f, "")
  update_ui()
end

function ensure_init()
  if GS.init then
    return 
  end
  update_scale()
  init_assets()
  reset_round(timer.getTime())
  GS.init = true
  love.mouse.setRelativeMode(true)
end

-- Logic 

function constrain(p)
  p.pos.y = clamp(p.pos.y, 0, LIMITS.y_max)
  p.pos.x = clamp(p.pos.x, p.limits.min, p.limits.max)
end

function process_input(dt)
  local p, k = GS.player, love.keyboard.isDown
  local dx = get_key_direction(k, "w", "s")
  local dy = get_key_direction(k, "d", "a")
  if dx ~= 0 or dy ~= 0 then
    GS.input = "keyboard"
    p.vel.x, p.vel.y = dx * p.speed, dy * p.speed
    return 
  end
  if GS.mouse.x ~= 0 or GS.mouse.y ~= 0 then
    GS.input = "mouse"
    p.vel.x, p.vel.y = -GS.mouse.y / dt, GS.mouse.x / dt
    GS.mouse.x, GS.mouse.y = 0, 0
  end
end

function update_pads_input(dt)
  GS.player.vel.x, GS.player.vel.y = 0, 0
  process_input(dt)
  GS.ai(GS.opponent, GS.ball, dt)
end

function move_pads(dt)
  for _, p in ipairs(GS.paddles) do
    integrate_position(p.pos, p.vel, dt)
    constrain(p)
  end
end

-- Physics Loop 

function select_hit_paddle(dt)
  local first = {
    time = nil,
    n = { }
  }
  for _, p in ipairs(GS.paddles) do
    local t, n = detect(GS.ball, p, dt)
    if t and (not first.time or t < first.time) then
      first.time = t
      first.paddle = p
      copy_vector(first.n, n)
    end
  end
  return first
end

function process_collision(col, t_sim)
  local t_imp = t_sim + col.time
  move_ball_time(t_imp)
  bounce(GS.ball, col.paddle, col.n)
  sfx.shot()
  sync_phys(t_imp)
end

function check_bounds(now)
  local b = GS.ball
  if b.pos.y - b.radius < 0 then
    b.pos.y = b.radius
    b.vel.y = -b.vel.y
    sync_phys(now)
    sfx.knock()
  end
  if GAME.height < b.pos.y + b.radius then
    b.pos.y = GAME.height - b.radius
    b.vel.y = -b.vel.y
    sync_phys(now)
    sfx.knock()
  end
end

-- Scoring 

function handle_game_over()
  GS.mode = "over"
  GS.assets.text_info:set("Game Over")
  sfx.gameover()
  love.mouse.setRelativeMode(false)
end

function process_win(win, now)
  GS.score[win] = GS.score[win] + 1
  update_ui()
  if GAME.score_win <= GS.score[win] then
    handle_game_over()
  else
    sfx.win()
    reset_round(now)
  end
end

function check_score(now)
  local x, r = GS.ball.pos.x, GS.ball.radius
  local win = nil
  if x + r < 0 then
    win = "opponent"
  end
  if GAME.width < x - r then
    win = "player"
  end
  if win then
    process_win(win, now)
  end
end

function update_ball(dt, now)
  local t_sim = now - dt
  sync_phys(t_sim)
  local col = select_hit_paddle(dt)
  if col.time then
    process_collision(col, t_sim)
  end
  move_ball_time(now)
  check_bounds(now)
  check_score(now)
end

-- Controls 

actions = {
  start = { },
  play = { },
  over = { }
}

function actions.start.space()
  GS.mode = "play"
  love.mouse.setRelativeMode(true)
  reset_round(timer.getTime())
  sfx.beep()
end

actions.start["1"] = function()
  GS.input = "mouse"
  if GS.ai == strategy.easy then
    GS.ai = strategy.hard
  else
    GS.ai = strategy.easy
  end
  update_ui()
  sfx.toggle()
end

actions.start["2"] = function()
  GS.ai = strategy.manual
  GS.input = "keyboard"
  update_ui()
  sfx.toggle()
end

function actions.start.e()
  GS.ai = strategy.easy
  GS.input = "mouse"
  update_ui()
  sfx.toggle()
end

function actions.play.r()
  GS.score.player = 0
  GS.score.opponent = 0
  update_ui()
  reset_round(timer.getTime())
  GS.mode = "start"
  GS.assets.text_info:set("Press Space to Start")
  love.mouse.setRelativeMode(false)
end

actions.over.space = actions.play.r
actions.over.r = actions.play.r

for k, v in pairs(actions) do
  v.escape = love.event.quit
end

-- Drawing

-- Perspective Transformation

function project(x, y)
  local depth = VIEW.xm + x
  local factor = VIEW.d / depth
  local sx = VIEW.s * ((VIEW.ym + y) * factor) + VIEW.c.x
  local sy = VIEW.s * (VIEW.h * factor) + VIEW.c.y
  return sx, sy, factor
end

-- Helper: Draws a single line in 3D space

function draw_3d_line(x1, y1, x2, y2)
  local sx1, sy1 = project(x1, y1)
  local sx2, sy2 = project(x2, y2)
  gfx.line(sx1, sy1, sx2, sy2)
end

-- Draws a bumper section 

function draw_bumper_section(y_base, z_off)
  local w, sh = GAME.width, VIEW.s * BUMPER.height
  local x1, y1, factor1 = project(0, y_base)
  local x2, y2, factor2 = project(w, y_base)
  local ty1, ty2 = y1 - (sh * factor1), y2 - (sh * factor2)
  gfx.polygon("fill", x1, y1, x2, y2, x2, ty2, x1, ty1)
  local x3, y3, factor3 = project(w, y_base + z_off)
  local x4, y4, factor4 = project(0, y_base + z_off)
  local ty3, ty4 = y3 - (sh * factor3), y4 - (sh * factor4)
  gfx.setColor(COLOR_BUMP_TOP)
  gfx.polygon("fill", x1, ty1, x2, ty2, x3, ty3, x4, ty4)
end

-- Draws the floor background (The Playing Area)

function draw_field()
  local w, h = GAME.width, GAME.height
  local x1, y1 = project(0, 0)
  local x2, y2 = project(w, 0)
  local x3 = project(w, h)
  local x4 = project(0, h)
  gfx.polygon("fill", x1, y1, x2, y2, x3, y2, x4, y1)
end

-- Draws the perspective grid 

function draw_perspective_grid()
  local w, h, z = GAME.width, GAME.height, GAME.zone_width
  for y = 0, h, h / GRID_VIEW.cols do
    draw_3d_line(0, y, z, y)
    draw_3d_line(w - z, y, w, y)
  end
  draw_3d_line(z, 0, w - z, 0)
  draw_3d_line(z, h, w - z, h)
  for x = 0, z, w / GRID_VIEW.rows do
    draw_3d_line(x, 0, x, h)
    draw_3d_line(w - x, 0, w - x, h)
  end
end

-- Draws a vertical (frontal) paddle face 

function draw_paddle_face(x1, y1, x2, y2)
  local h = PADDLE.height * VIEW.s
  local sx1, sy1, factor1 = project(x1, y1)
  local sx2, sy2, factor2 = project(x2, y2)
  local ty1 = sy1 - (h * factor1)
  local ty2 = sy2 - (h * factor2)
  gfx.polygon("fill", sx1, sy1, sx2, sy2, sx2, ty2, sx1, ty1)
end

-- Draws a paddle:  real height for body.

function draw_paddle_top(p, h_3d)
  local x, y, w, h = p.pos.x, p.pos.y, p.size.x, p.size.y
  local s = h_3d * VIEW.s
  local x1, y1, factor1 = project(x, y)
  local x2, y2, factor2 = project(x + w, y)
  local x3, y3, factor3 = project(x + w, y + h)
  local x4, y4, factor4 = project(x, y + h)
  local ty1, ty2 = y1 - (s * factor1), y2 - (s * factor2)
  local ty3, ty4 = y3 - (s * factor3), y4 - (s * factor4)
  gfx.polygon("fill", x1, ty1, x2, ty2, x3, ty3, x4, ty4)
end

-- Draws ball: full 3D body 

function draw_ball(h_real)
  local b = GS.ball
  local x, y, factor = project(b.pos.x, b.pos.y)
  local r = b.radius * factor * VIEW.s
  local depth = (VIEW.h * factor) / VIEW.d
  local h = h_real * factor * VIEW.s
  gfx.setColor(b.color_side)
  gfx.ellipse("fill", x, y, r, r * depth)
  gfx.rectangle("fill", x - r, y - h, r * 2, h)
  gfx.setColor(b.color)
  gfx.ellipse("fill", x, y - h, r, r * depth)
end

function draw_layer_env()
  gfx.setColor(COLOR_FIELD)
  draw_field()
  gfx.setColor(COLOR_GRID)
  draw_perspective_grid()
  gfx.setColor(COLOR_BUMP_L)
  draw_bumper_section(0, -BUMPER.depth)
  gfx.setColor(COLOR_BUMP_R)
  draw_bumper_section(GAME.height, BUMPER.depth)
end

-- Draws paddle tops

function draw_top_surfaces(h)
  for _, p in ipairs(GS.paddles) do
    gfx.setColor(p.color)
    draw_paddle_top(p, h)
  end
end

-- Helper: Draws the front face (parallel to screen).

function draw_front_face(p, ball_depth, pass)
  local px, py, ph = p.pos.x, p.pos.y, p.size.y
  local is_deeper = (ball_depth < px)
  if (pass == 1) == is_deeper then
    draw_paddle_face(px, py, px, py + ph)
  end
end

-- Helper: Draws the side face (perpendicular to screen).

function draw_side_face(p, by, vy, pass)
  local wall_y
  if vy < p.pos.y then
    wall_y = p.pos.y
  elseif p.pos.y + p.size.y < vy then
    wall_y = p.pos.y + p.size.y
  end
  if wall_y then
    local same_side = (by < wall_y) == (vy < wall_y)
    if (pass == 1) == same_side then
      local px, pw = p.pos.x, p.size.x
      draw_paddle_face(px, wall_y, px + pw, wall_y)
    end
  end
end

-- Handles the sorting of vertical surfaces vs puck

function draw_layered()
  local bx, by = GS.ball.pos.x, GS.ball.pos.y
  local vy = GAME.height / 2
  for i = 1, 2 do
    if i == 2 then
      draw_ball(BALL.height)
    end
    for _, p in ipairs(GS.paddles) do
      gfx.setColor(p.color_side)
      draw_front_face(p, bx, i)
      draw_side_face(p, by, vy, i)
    end
  end
end

-- Main draw function

function draw_objs()
  draw_layer_env()
  draw_layered()
  draw_top_surfaces(PADDLE.height)
end

function draw_scores()
  local txt = GS.assets.text_player
  local wp = txt:getWidth()
  local cx = GAME.width / 2
  local y_off = GAME.score_off_y
  gfx.draw(txt, (cx - 60) - wp / 2, y_off)
  gfx.draw(GS.assets.text_opponent, cx + 40, y_off)
end

function draw_info()
  if GS.mode == "play" then
    return 
  end
  local ti = GS.assets.text_info
  local xi = center_text_x(ti)
  local yi = GAME.height * 0.4 - ti:getHeight() / 2
  gfx.draw(ti, xi, yi)
  if GS.mode == "start" then
    local tm = GS.assets.text_mode
    local xm = center_text_x(tm)
    local ym = GAME.height * 0.6 - tm:getHeight() / 2
    gfx.draw(tm, xm, ym)
  end
end

function draw_ui()
  gfx.setColor(1, 1, 1)
  draw_scores()
  draw_info()
end

-- Main Loop 

function love.update(dt)
  ensure_init()
  if GS.mode ~= "play" then
    return 
  end
  local now = timer.getTime()
  update_pads_input(dt)
  update_ball(dt, now)
  move_pads(dt)
end

function love.draw()
  if not GS.init then
    return 
  end
  gfx.push()
  gfx.applyTransform(GS.tf)
  gfx.clear(COLOR_BG)
  draw_objs()
  draw_ui()
  gfx.pop()
end

function love.mousemoved(x, y, dx, dy)
  if GS.mode == "play" then
    GS.mouse.x = GS.mouse.x + dx
    GS.mouse.y = GS.mouse.y + dy
  end
end

function love.keypressed(k)
  local action = actions[GS.mode][k]
  if action then
    action()
  end
end

function love.resize(w, h)
  if GS.init then
    update_scale()
  end
end
