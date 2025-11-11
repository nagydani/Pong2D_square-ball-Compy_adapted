-- strategy.lua
-- opponent behavior module

-- fast AI (hard)
local function opp_ai_hard(S, dt)
  local c = S.opp.y + PADDLE_HEIGHT / 2
  local by = S.ball.y + BALL_SIZE / 2
  local d = by - c
  if math.abs(d) < AI_DEADZONE then
    S.opp.dy = 0
  else
    local dir = (0 < d) and 1 or -1
    move_paddle(S.opp, dir, dt)
  end
end

-- slow AI (easy)
local function opp_ai_easy(S, dt)
  local c = S.opp.y + PADDLE_HEIGHT / 2
  local by = S.ball.y + BALL_SIZE / 2
  local d = by - c
  if math.abs(d) < AI_DEADZONE then
    S.opp.dy = 0
  else
    local dir = (0 < d) and 1 or -1
    move_paddle(S.opp, dir, dt * 0.6)
  end
end

-- Manual (second player)
local function opp_manual(S, dt)
  local dir = 0
  if love.keyboard.isDown("up") then
    dir = -1
  elseif love.keyboard.isDown("down") then
    dir = 1
  end
  move_paddle(S.opp, dir, dt)
end

-- global strategy table
strategy = {
  current = nil,
  mode = "ai",        -- "ai" | "manual"
  difficulty = "hard" -- "easy" | "hard"
}

local function pick_ai(diff)
  if diff == "easy" then
    return opp_ai_easy
  else
    return opp_ai_hard
  end
end

-- API
function strategy.set_opp_mode(mode)
  strategy.mode = mode
  if mode == "ai" then
    strategy.current = pick_ai(strategy.difficulty)
  else
    strategy.current = opp_manual
  end
end

function strategy.set_difficulty(diff)
  strategy.difficulty = diff
  if strategy.mode == "ai" then
    strategy.current = pick_ai(diff)
  end
end

function strategy.set_opp_strategy(name, fn)
  if name == "ai" then
    strategy.set_opp_mode("ai")
  elseif name == "manual" then
    strategy.set_opp_mode("manual")
  elseif name == "custom" and fn then
    strategy.current = fn
  end
end
