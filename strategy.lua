-- strategy.lua
-- AI Logic and Input Handling

strategy = { }

-- Returns direction (-1, 0, 1) based on target difference.

function get_dir(current, target, deadzone)
  local diff = target - current
  if math.abs(diff) < deadzone then
    return 0
  end
  return (0 < diff) and 1 or -1
end

--  Core AI Logic

-- Core AI: Manages Attack/Defend states. 

-- Common logic for both difficulties.

function run_unified_strategy(pad, ball, dt, limit)
  local dist = math.abs(ball.pos.x - pad.pos.x)
  local is_incoming = 0 < ball.vel.x
  local is_serving = math.abs(ball.vel.x) < AI.serve_threshold
  local is_reachable = dist < AI.strike_dist
  local tx, ty = AI.wall_x, ball.pos.y
  if (is_incoming or is_serving) and is_reachable then
    tx = AI.attack_x
    local t = love.timer.getTime() * AI.noise_freq
    local noise = love.math.noise(t) - AI.noise_offset
    ty = ball.pos.y + (noise * AI.noise_range)
  end
  local cy = pad.pos.y + PADDLE.half_y
  pad.vel.x = get_dir(pad.pos.x, tx, AI.dead_x) * limit
  pad.vel.y = get_dir(cy, ty, AI.dead_y) * limit
end

-- Easy Strategy: Uses low speed

function strategy.easy(pad, ball, dt)
  run_unified_strategy(pad, ball, dt, AI.speed_easy)
end

-- Hard Strategy: Uses high speed

function strategy.hard(pad, ball, dt)
  run_unified_strategy(pad, ball, dt, AI.speed_hard)
end

-- Manual AI

function strategy.manual(pad, ball, dt)
  local is_down = love.keyboard.isDown
  local dx = get_key_direction(is_down, "right", "left")
  local dy = get_key_direction(is_down, "down", "up")
  pad.vel.x = PADDLE.speed * dx
  pad.vel.y = PADDLE.speed * dy
end
