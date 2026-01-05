-- physics.lua

-- 0. TOOLS

-- Pre-allocated buffers

V_REL = {
  x = 0,
  y = 0
}
D_VEC = {
  x = 0,
  y = 0
}

CORNER_BUFF = { }
for i = 1, 4 do
  CORNER_BUFF[i] = {
    x = 0,
    y = 0
  }
end

-- Helpers

function get_corners(pad)
  local x, y = pad.pos.x, pad.pos.y
  local w, h = pad.size.x, pad.size.y
  CORNER_BUFF[1].x, CORNER_BUFF[1].y = x, y
  CORNER_BUFF[2].x, CORNER_BUFF[2].y = x + w, y
  CORNER_BUFF[3].x, CORNER_BUFF[3].y = x, y + h
  CORNER_BUFF[4].x, CORNER_BUFF[4].y = x + w, y + h
  return CORNER_BUFF
end

-- Calculates wall distance 

function get_dist(ball, pad, axis, dv)
  local pos_b = ball.pos[axis]
  local pos_p = pad.pos[axis]
  local size_p = pad.size[axis]
  local s = (0 < dv) and -1 or 1
  local edge = (0 < dv) and pos_p or (pos_p + size_p)
  return (edge + s * ball.radius) - pos_b
end

-- 1. TIME CALCULATION

function check_time(t, dt)
  if 0 <= t and t <= dt then
    return t
  end
  return nil
end

-- Solves linear intersection (Wall/SIde)

function calc_time(dist, v, dt)
  local t = dist / v
  return check_time(t, dt)
end

-- Solves geometry intersection (Corner)

function calc_circ_time(d, v, r, dt)
  local v2 = v.x * v.x + v.y * v.y
  local perp = v.x * d.y - v.y * d.x
  local r2v2 = r * r * v2
  if r2v2 < perp * perp then
    return nil
  end
  local proj = d.x * v.x + d.y * v.y
  local disc = r2v2 - perp * perp
  if disc < 0 then
    return nil
  end
  local t = (proj - math.sqrt(disc)) / v2
  return check_time(t, dt)
end

-- 2. AXIS LOGIC

-- Checks if Ball Center lies within Paddle bounds.

function check_center(ball, pad, axis, t)
  local ortho = (axis == "x") and "y" or "x"
  local b_proj = ball.pos[ortho] + ball.vel[ortho] * t
  local p_proj = pad.pos[ortho] + pad.vel[ortho] * t
  if p_proj <= b_proj and b_proj <= p_proj + pad.size[ortho]
       then
    coll[axis].t = t
    coll[axis].n[axis] = (0 < ball.vel[axis] - pad.vel[axis])
         and -1 or 1
    coll[axis].n[ortho] = 0
  end
end

-- 3. RESOLUTION

function bounce(ball, pad, norm)
  local rv_x = ball.vel.x - pad.vel.x
  local rv_y = ball.vel.y - pad.vel.y
  local dot = rv_x * norm.x + rv_y * norm.y
  local n_x, n_y = dot * norm.x, dot * norm.y
  local t_x, t_y = rv_x - n_x, rv_y - n_y
  local e = GAME.elasticity
  local friction = 0.5
  n_x, n_y = -n_x * e, -n_y * e
  local slide = 1 - friction
  t_x, t_y = t_x * slide, t_y * slide
  ball.vel.x = pad.vel.x + (n_x + t_x)
  ball.vel.y = pad.vel.y + (n_y + t_y)
end

-- Collision candidates

coll = {
  x = { },
  y = { },
  c = { }
}
coll.x.n = {
  x = 0,
  y = 0
}
coll.y.n = {
  x = 0,
  y = 0
}
coll.c.n = {
  x = 0,
  y = 0
}

function select_earliest_impact()
  local best = nil
  if coll.x.t then
    best = coll.x
  end
  if coll.y.t and (not best or coll.y.t < best.t) then
    best = coll.y
  end
  if coll.c.t and (not best or coll.c.t < best.t) then
    best = coll.c
  end
  if best then
    return best.t, best.n
  end
  return nil, nil
end

-- 4. COLLISION DETECTION

function collide_side(ball, pad, axis, dt)
  local dv = ball.vel[axis] - pad.vel[axis]
  local dist = get_dist(ball, pad, axis, dv)
  local t = calc_time(dist, dv, dt)
  if t then
    check_center(ball, pad, axis, t)
  end
end

function add_corner_hit(t, nx, ny)
  if not coll.c.t or t < coll.c.t then
    coll.c.t = t
    coll.c.n.x, coll.c.n.y = nx, ny
  end
end

function collide_corner(ball, pad, corner, dt)
  D_VEC.x = corner.x - ball.pos.x
  D_VEC.y = corner.y - ball.pos.y
  local t = calc_circ_time(D_VEC, V_REL, ball.radius, dt)
  if t then
    local bx = ball.pos.x + V_REL.x * t
    local by = ball.pos.y + V_REL.y * t
    local inv_r = 1 / ball.radius
    add_corner_hit(
      t,
      (bx - corner.x) * inv_r,
      (by - corner.y) * inv_r
    )
  end
end

function detect(ball, pad, dt)
  coll.x.t, coll.y.t, coll.c.t = nil, nil, nil
  collide_side(ball, pad, "x", dt)
  collide_side(ball, pad, "y", dt)
  V_REL.x = ball.vel.x - pad.vel.x
  V_REL.y = ball.vel.y - pad.vel.y
  for _, corner in ipairs(get_corners(pad)) do
    collide_corner(ball, pad, corner, dt)
  end
  return select_earliest_impact()
end
