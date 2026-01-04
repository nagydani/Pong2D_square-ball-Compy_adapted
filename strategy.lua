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

function run_ai(pad, ball, speed_mode)
  local bx, vx = ball.pos.x, ball.vel.x
  local in_zone = (AI.zone_x < bx) and (AI.retreat_v < vx)
  local attack = (vx == 0 and AI.mid_field < bx) or in_zone
  local tx = attack and AI.attack_x or AI.wall_x
  local noise = love.math.noise(
    love.timer.getTime() * AI.noise_freq
  ) - 0.5
  local ty = attack and (ball.pos.y + noise * AI.noise_range)
       or ball.pos.y
  local center_y = pad.pos.y + PADDLE.half_y
  pad.vel.x = get_dir(pad.pos.x, tx, AI.dead_x) * speed_mode
  pad.vel.y = get_dir(center_y, ty, AI.dead_y) * speed_mode
end

-- Easy Strategy: Uses low speed

function strategy.easy(pad, ball, dt)
  run_ai(pad, ball, AI.speed_easy)
end

-- Hard Strategy: Uses high speed

function strategy.hard(pad, ball, dt)
  run_ai(pad, ball, AI.speed_hard)
end

-- Manual AI

function strategy.manual(pad, ball, dt)
  local is_down = love.keyboard.isDown
  local dx = get_key_direction(is_down, "right", "left")
  local dy = get_key_direction(is_down, "down", "up")
  pad.vel.x = PADDLE.speed * dx
  pad.vel.y = PADDLE.speed * dy
end
