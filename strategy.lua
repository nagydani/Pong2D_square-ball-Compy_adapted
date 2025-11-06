-- strategy.lua
-- opponent behavior module

-- AI strategy

local function opp_ai(S, dt)
  local c = S.opp.y + S.opp.h / 2
  local by = S.ball.y + S.ball.size / 2
  local d = by - c
  if math.abs(d) < AI_DEADZONE then
    S.opp.dy = 0
  else
    local dir = (0 < d) and 1 or -1
    move_paddle(S.opp, dir, dt)
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

strategy = { current = nil }

-- API

function strategy.set_opp_strategy(name, fn)
  if name == "ai" then
    strategy.current = opp_ai
  elseif name == "manual" then
    strategy.current = opp_manual
  elseif name == "custom"
       and fn
  then
    strategy.current = fn
  end
end

function strategy.update(S, dt)
  if strategy.current then
    strategy.current(S, dt)
  end
end
