-- main.lua

require "constants"
require "strategy"

gfx = love.graphics

-- runtime configuration

USE_FIXED = true
FIXED_DT = 1 / 60
MAX_STEPS = 5
SPEED_SCALE = 2.5
MOUSE_SENSITIVITY = 1

-- runtime variables

screen_w, screen_h = 0, 0
paddle_max_y, ball_max_y = 0, 0
center_x = 0
paddle_w = 0
paddle_h = 0
ball_size = 0

inited = false
mouse_enabled = false
time_t, acc = 0, 0

-- game state

S = {}

S.player = {
  x = PADDLE_OFFSET_X,
  y = 0,
  dy = 0
}
S.opp = {
  x = 0,
  y = 0,
  dy = 0
}
S.ball = {
  x = 0,
  y = 0,
  dx = BALL_SPEED_X,
  dy = BALL_SPEED_Y,
}
S.score = {
  player = 0,
  opp = 0
}
S.state = "start"

-- ui resources

font = nil
texts = {}
center_canvas = nil

-- screen helpers

function cache_dims()
  screen_w = gfx.getWidth()
  screen_h = gfx.getHeight()
  -- scale: convert proportional constants to real pixels
  local base_h = 480
  local scale = screen_h / base_h
  paddle_w = math.floor(PADDLE_WIDTH * scale + 0.5)
  paddle_h = math.floor(PADDLE_HEIGHT * scale + 0.5)
  ball_size = math.floor(BALL_SIZE * scale + 0.5)
  paddle_max_y = screen_h - paddle_h
  ball_max_y = screen_h - ball_size
  center_x = math.floor(screen_w / 2 + 0.5)
end

function layout()
  -- apply scaled sizes to state
  S.player.y = (screen_h - paddle_h) / 2
  S.opp.x = (screen_w - PADDLE_OFFSET_X) - paddle_w
  S.opp.y = (screen_h - paddle_h) / 2
  S.ball.x = (screen_w - ball_size) / 2
  S.ball.y = (screen_h - ball_size) / 2
end

-- text helpers

function set_text(name, str)
  local old = texts[name]
  if old then
    old:release()
  end
  texts[name] = gfx.newText(
    font, str
  )
end

function rebuild_score_texts()
  set_text(
    "score_l",
    tostring(S.score.player)
  )
  set_text(
    "score_r",
    tostring(S.score.opp)
  )
end

-- canvas

function draw_center_line()
  local x = center_x - 2
  local step = ball_size * 2
  local y = 0
  while y < screen_h do
    gfx.rectangle("fill", x, y, 4, ball_size)
    y = y + step
  end
end

function build_center_canvas()
  if center_canvas then
    center_canvas:release()
  end
  center_canvas =
    gfx.newCanvas(screen_w, screen_h)
  gfx.setCanvas(center_canvas)
  gfx.clear(0, 0, 0, 0)
  gfx.setColor(COLOR_FG)
  draw_center_line()
  gfx.setCanvas()
end

-- initialization

function build_static_texts()
  font = gfx.getFont()
  set_text("start", "Press Space")
  set_text("over", "Game Over")
  rebuild_score_texts()
end

function do_init()
  cache_dims()
  layout()
  build_center_canvas()
  build_static_texts()
  mouse_enabled = true
  time_t = love.timer.getTime()
  inited = true
  strategy.set_opp_strategy("ai")
end

function ensure_init()
  if not inited then do_init() end
end

-- paddle and ball movement

function clamp_paddle(p)
  if p.y < 0 then p.y = 0 end
  if p.y > paddle_max_y then p.y = paddle_max_y end
end

function move_paddle(p, dir, dt)
  p.dy = PADDLE_SPEED * dir
  p.y = p.y + p.dy * dt
  clamp_paddle(p)
end

function check_scored(bx)
  if bx < 0 then
    return "opp"
  end
  if screen_w < bx + ball_size then
    return "player"
  end
  return nil
end

function move_ball(b, dt)
  b.x = b.x + b.dx * dt
  b.y = b.y + b.dy * dt
  if b.y < 0 then
    b.y = 0
    b.dy = -b.dy
  end
  if screen_h < b.y + ball_size then
    b.y = screen_h - ball_size
    b.dy = -b.dy
  end
  return check_scored(b.x)
end

function bounce_ball(b)
  if b.y < 0 then
    b.y = 0
    b.dy = -b.dy
  end
  if ball_max_y < b.y then
    b.y = ball_max_y
    b.dy = -b.dy
  end
end

-- collision and score

function hit_offset(b, p)
  local pc = p.y + paddle_h / 2
  local bc = b.y + ball_size / 2
  return (bc - pc) / (paddle_h / 2)
end

function collide(b, p, off)
  local hx1 = b.x < p.x + paddle_w
  local hx2 = p.x < b.x + ball_size
  local hy1 = b.y < p.y + paddle_h
  local hy2 = p.y < b.y + ball_size
  if hx1 and hx2 and hy1 and hy2 then
    b.x = p.x + off
    b.dx = -b.dx
    b.dy = b.dy + hit_offset(b, p) * (BALL_SPEED_Y * 0.75)
  end
end

function scored(side)
  local s = S.score
  s[side] = s[side] + 1
  rebuild_score_texts()
  if WIN_SCORE <= s[side] then
    S.state = "gameover"
    love.mouse.setRelativeMode(false)
    return true
  end
  return false
end

function reset_ball()
  local b = S.ball
  b.x = (screen_w - ball_size) / 2
  b.y = (screen_h - ball_size) / 2
  local s = S.score.player + S.score.opp
  local dir = (s % 2 == 0) and 1 or -1
  b.dx = dir * BALL_SPEED_X
  b.dy = ((s % 3 - 1) * BALL_SPEED_Y) * 0.3
end

-- control and update

key_actions = {
  start = { },
  play = { },
  gameover = { }
}

function key_actions.start.space()
  S.state = "play"
  love.mouse.setRelativeMode(true)
  reset_ball()
end

-- reserve for future pause or ignore
function key_actions.play.space()
  
end

function key_actions.gameover.space()
  S.score.player = 0
  S.score.opp = 0
  rebuild_score_texts()
  layout()
  S.state = "start"
  love.mouse.setRelativeMode(false)
end

for name in pairs(key_actions) do
  key_actions[name].escape = love.event.quit
end

function love.keypressed(k)
  local group = key_actions[S.state]
  if group and group[k] then
    group[k]()
  end
end

keydown = {
  q = -1,
  a = 1
}

function update_player(dt)
  local dir = 0
  for k, v in pairs(keydown) do
    if love.keyboard.isDown(k) then
      dir = v
    end
  end
  move_paddle(S.player, dir, dt)
end

function love.mousemoved(x, y, dx, dy, t)
  if not mouse_enabled or t
     or S.state ~= "play"
  then
    return
  end
  local p = S.player
  p.y = p.y + dy * MOUSE_SENSITIVITY
  clamp_paddle(p)
end

-- main step/update

function step_ball(b, dt)
  move_ball(b, dt)
  bounce_ball(b)
  collide(b, S.player, paddle_w)
  collide(b, S.opp, -ball_size)
end

function handle_score()
  local side = check_scored(S.ball.x)
  if side then
    scored(side)
    reset_ball()
    return true
  end
  return false
end

function step_game(dt)
  if S.state ~= "play" 
  then
    return
  end
  local sdt = dt * SPEED_SCALE
  update_player(sdt)
  strategy.update(S, sdt)
  step_ball(S.ball, sdt)
  if handle_score() 
  then
    return
  end
end

function update_fixed(rdt)
  acc = acc + rdt
  local steps = 0
  while FIXED_DT <= acc and steps < MAX_STEPS do
    step_game(FIXED_DT)
    acc = acc - FIXED_DT
    steps = steps + 1
  end
end

function love.update(dt)
  ensure_init()
  local now = love.timer.getTime()
  local rdt = now - time_t
  time_t = now
  if USE_FIXED then 
    update_fixed(rdt)
  else
    step_game(rdt)
  end
end

-- drawing

function draw_bg()
  gfx.clear(COLOR_BG)
  gfx.setColor(COLOR_FG)
end

function draw_paddle(p)
  gfx.rectangle("fill", p.x, p.y, paddle_w, paddle_h)
end

function draw_ball(b)
  gfx.rectangle("fill", b.x, b.y, ball_size, ball_size)
end

function draw_scores()
  gfx.draw(texts.score_l, screen_w / 2 - 60, SCORE_OFFSET_Y)
  gfx.draw(texts.score_r, screen_w / 2 + 40, SCORE_OFFSET_Y)
end

function draw_state_text(s)
  local state_text = {
    start = texts.start,
    gameover = texts.over
  }

  local t = state_text[s]
  if t then
    gfx.draw (t, screen_w / 2 - 40, screen_h / 2 - 16)
  end
end

function love.draw()
  cache_dims()
  draw_bg()
  gfx.draw(center_canvas)
  draw_paddle(S.player)
  draw_paddle(S.opp)
  draw_ball(S.ball)
  draw_scores()
  draw_state_text(S.state)
end

function love.resize()
  cache_dims()
  layout()
  build_center_canvas()
end