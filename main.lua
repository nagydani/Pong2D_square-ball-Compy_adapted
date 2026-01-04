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
  canvas = nil,
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

function init_canvas()
  local c = gfx.newCanvas(GAME.width, GAME.height)
  gfx.setCanvas(c)
  gfx.setColor(COLORS.fg)
  local cx = (GAME.width / 2) - (GRID.width / 2)
  local y = 0
  while y < GAME.height do
    gfx.rectangle("fill", cx, y, GRID.width, GRID.dash)
    y = y + GRID.dash + GRID.gap
  end
  gfx.setCanvas()
  return c
end

function init_assets()
  local f = gfx.getFont()
  GS.assets.text_info = gfx.newText(f, "Press Space to Start")
  GS.assets.text_player = gfx.newText(f, "0")
  GS.assets.text_opponent = gfx.newText(f, "0")
  GS.assets.text_mode = gfx.newText(f, "")
  GS.assets.canvas = init_canvas()
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
  local dy = get_key_direction(k, "a", "q")
  local dx = get_key_direction(k, "d", "s")
  if dx ~= 0 or dy ~= 0 then
    GS.input, p.vel.x, p.vel.y = "keyboard", dx * p.speed, dy * 
        p.speed
    return 
  end
  if GS.mouse.x ~= 0 or GS.mouse.y ~= 0 then
    GS.input, p.vel.x, p.vel.y = "mouse", GS.mouse.x / dt, GS.
        mouse.y / dt
    GS.mouse.x, GS.mouse.y = 0, 0
  end
end

function update_pads(dt)
  GS.player.vel.x, GS.player.vel.y = 0, 0
  process_input(dt)
  GS.ai(GS.opponent, GS.ball, dt)
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
  local x = GS.ball.pos.x
  local win = nil
  local p_limit = LIMITS.player.min + GS.player.size.x
  if x < LIMITS.player.min then
    win = "opponent"
  end
  local o_limit = LIMITS.opp.max
  if LIMITS.opp.max + GS.opponent.size.x < x then
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

function draw_objs()
  gfx.draw(GS.assets.canvas, 0, 0)
  for _, p in ipairs(GS.paddles) do
    gfx.rectangle("fill", p.pos.x, p.pos.y, p.size.x, p.size.y)
  end
  local b = GS.ball
  gfx.circle("fill", b.pos.x, b.pos.y, b.radius)
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
  update_pads(dt)
  update_ball(dt, now)
end

function love.draw()
  if not GS.init then
    return 
  end
  gfx.push()
  gfx.applyTransform(GS.tf)
  gfx.clear(COLORS.bg)
  gfx.setColor(COLORS.fg)
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
