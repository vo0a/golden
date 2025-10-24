-- golden - 케이팝 데몬 헌터스
-- 개선 버전 v2.0

-- ========================================
-- 전역 변수 초기화
-- ========================================

function _init()
  game_state = "play"
  stage = 1
  frame = 0
  
  -- 스테이지 설정
  stage_config = {
    {max_enemies=10, portal_interval=300, boss_hp=100, boss_speed=1},
    {max_enemies=15, portal_interval=240, boss_hp=150, boss_speed=1.5},
    {max_enemies=25, portal_interval=180, boss_hp=200, boss_speed=2}
  }
  
  init_player()
  init_boss()
  init_platforms()
  
  enemies = {}
  portals = {}
  notes = {}
  boss_bullets = {}
  
  jinu_active = false
  jinu_timer = 0
  
  -- 스테이지 전환 관련
  stage_clear = false
  stage_clear_timer = 0
end

-- ========================================
-- 플랫폼 초기화 (구조물)
-- ========================================

function init_platforms()
  platforms = {}
  
  -- 기본 땅
  add(platforms, {x=0, y=120, w=128, h=8})
  
  -- 랜덤 플랫폼 생성 (3-5개)
  local num_platforms = 3 + flr(rnd(3))
  for i=1,num_platforms do
    add(platforms, {
      x = 10 + rnd(90),
      y = 40 + rnd(60),
      w = 20 + rnd(20),
      h = 4
    })
  end
end

-- ========================================
-- 플레이어 초기화
-- ========================================

function init_player()
  player = {
    x = 32,
    y = 100,
    w = 8,
    h = 8,
    vx = 0,
    vy = 0,
    grounded = false,
    jump_count = 0,
    hp = 100,
    max_hp = 100,
    special = 0,
    facing = 1,
    anim_frame = 0,
    shoot_cooldown = 0
  }
end

-- ========================================
-- 보스 초기화
-- ========================================

function init_boss()
  local cfg = stage_config[stage]
  boss = {
    x = 96,
    y = 40,
    w = 16,
    h = 16,
    vx = 0,
    vy = 0,
    hp = cfg.boss_hp,
    max_hp = cfg.boss_hp,
    phase = stage,
    portal_timer = 0,
    move_timer = 0,
    attack_timer = 0,
    attack_pattern = 1,
    target_x = 96,
    target_y = 40,
    anim_frame = 0
  }
end

-- ========================================
-- 메인 업데이트 루프
-- ========================================

function _update60()
  frame += 1
  
  if game_state == "play" then
    if stage_clear then
      -- 스테이지 클리어 대기
      stage_clear_timer += 1
      if btnp(4) or stage_clear_timer > 120 then
        next_stage()
      end
    else
      update_input()
      update_player()
      update_boss()
      update_enemies()
      update_portals()
      update_projectiles()
      check_collisions()
      update_jinu()
      check_game_state()
    end
    
  elseif game_state == "title" then
    if btnp(4) or btnp(5) then
      game_state = "play"
    end
  elseif game_state == "gameover" or game_state == "win" then
    if btnp(4) then
      _init()
    end
  end
end

-- ========================================
-- 다음 스테이지로 진행
-- ========================================

function next_stage()
  stage += 1
  if stage > 3 then
    game_state = "win"
  else
    stage_clear = false
    stage_clear_timer = 0
    init_player()
    init_boss()
    init_platforms()
    enemies = {}
    portals = {}
    notes = {}
    boss_bullets = {}
  end
end

-- ========================================
-- 입력 처리
-- ========================================

function update_input()
  -- 좌우 이동
  if btn(0) then
    player.vx = -2
    player.facing = -1
  elseif btn(1) then
    player.vx = 2
    player.facing = 1
  else
    player.vx = 0
  end
  
  -- 점프 (이단 점프 가능)
  if btnp(4) and player.jump_count < 2 then
    player.vy = -4
    player.jump_count += 1
    sfx(0)
  end
  
  -- 하강 (공중에서)
  if btn(3) and not player.grounded then
    player.vy = 4
  end
  
  -- 공격
  if btnp(5) and player.shoot_cooldown <= 0 then
    shoot_note()
    player.shoot_cooldown = 15
  end
end

-- ========================================
-- 플레이어 업데이트
-- ========================================

function update_player()
  if player.shoot_cooldown > 0 then
    player.shoot_cooldown -= 1
  end
  
  -- 중력 적용
  player.vy += 0.3
  if player.vy > 4 then
    player.vy = 4
  end
  
  -- 위치 업데이트
  player.x += player.vx
  player.y += player.vy
  
  -- 화면 경계 체크
  if player.x < 0 then player.x = 0 end
  if player.x > 120 then player.x = 120 end
  if player.y < 0 then player.y = 0 end
  
  -- 플랫폼 충돌 체크
  player.grounded = false
  for p in all(platforms) do
    if player.x + player.w > p.x and
       player.x < p.x + p.w and
       player.y + player.h >= p.y and
       player.y + player.h <= p.y + 6 and
       player.vy >= 0 then
      player.y = p.y - player.h
      player.vy = 0
      player.grounded = true
      player.jump_count = 0
      break
    end
  end
  
  -- 화면 밖으로 떨어지면 데미지
  if player.y > 128 then
    player.hp -= 20
    player.x = 32
    player.y = 100
    player.vy = 0
  end
  
  -- 애니메이션
  if player.vx != 0 then
    player.anim_frame = (player.anim_frame + 1) % 32
  else
    player.anim_frame = 0
  end
end

-- ========================================
-- 음표 발사
-- ========================================

function shoot_note()
  add(notes, {
    x = player.x + (player.facing > 0 and 8 or 0),
    y = player.y + 3,
    w = 4,
    h = 4,
    vx = player.facing * 3,
    vy = 0,
    damage = 10
  })
  sfx(1)
end

-- ========================================
-- 보스 업데이트
-- ========================================

function update_boss()
  local cfg = stage_config[stage]
  
  -- 회피 이동
  local dx = boss.x - player.x
  local dy = boss.y - player.y
  local dist = sqrt(dx * dx + dy * dy)
  
  if dist < 40 then
    boss.target_x = boss.x + sgn(dx) * 20
    boss.target_y = boss.y + sgn(dy) * 20
  end
  
  -- 음표 회피
  for n in all(notes) do
    local ndx = n.x - boss.x
    local ndy = n.y - boss.y
    local ndist = sqrt(ndx * ndx + ndy * ndy)
    if ndist < 30 then
      boss.target_x = boss.x - sgn(ndx) * 25
      boss.target_y = boss.y - sgn(ndy) * 25
    end
  end
  
  -- 랜덤 이동
  boss.move_timer += 1
  if boss.move_timer > 180 then
    boss.target_x = 64 + rnd(48)
    boss.target_y = 20 + rnd(60)
    boss.move_timer = 0
  end
  
  -- 이동
  boss.vx = (boss.target_x - boss.x) * 0.1 * cfg.boss_speed
  boss.vy = (boss.target_y - boss.y) * 0.1 * cfg.boss_speed
  boss.x += boss.vx
  boss.y += boss.vy
  
  boss.x = mid(16, boss.x, 112)
  boss.y = mid(16, boss.y, 96)
  
  -- 혼문 생성
  boss.portal_timer += 1
  if boss.portal_timer >= cfg.portal_interval and #enemies < cfg.max_enemies then
    create_portal()
    boss.portal_timer = 0
  end
  
  -- 보스 공격 패턴
  boss.attack_timer += 1
  if boss.attack_timer >= 120 then  -- 2초마다 공격
    boss_attack()
    boss.attack_timer = 0
  end
  
  boss.anim_frame = (boss.anim_frame + 1) % 60
end

-- ========================================
-- 보스 공격 패턴
-- ========================================

function boss_attack()
  local pattern = stage  -- 스테이지에 따라 패턴 변경
  
  -- 플레이어 방향 계산
  local dx = player.x - boss.x
  local dy = player.y - boss.y
  local dist = sqrt(dx * dx + dy * dy)
  
  -- 정규화된 방향 벡터
  local dir_x = 0
  local dir_y = 0
  if dist > 0 then
    dir_x = dx / dist
    dir_y = dy / dist
  end

  if pattern == 2 then
    -- 패턴 1: 플레이어를 향한 직선 공격 (1발)
    add(boss_bullets, {
      x = boss.x + 8,
      y = boss.y + 8,
      w = 4,
      h = 4,
      vx = dir_x * 2,
      vy = dir_y * 2,
      damage = 15,
      pattern = 1
    })
    
  elseif pattern == 2 then
    -- 패턴 2: 플레이어 방향 기준 3방향 공격
    local angle = atan2(dx, dy)
    -- 패턴 2: 3방향 공격
    for i=-1,1 do
      local spread_angle = angle + i * 0.1
      add(boss_bullets, {
        x = boss.x + 8,
        y = boss.y + 8,
        w = 4,
        h = 4,
        vx = cos(spread_angle) * 2,
        vy = sin(spread_angle) * 2,
        damage = 15,
        pattern = 2
      })
    end
    
  else
    -- 패턴 3: 플레이어 방향 기준 5방향 부채꼴 공격
    local angle = atan2(dx, dy)
    for i=-2,2 do
      local spread_angle = angle + i * 0.08
      add(boss_bullets, {
        x = boss.x + 8,
        y = boss.y + 8,
        w = 4,
        h = 4,
        vx = cos(spread_angle) * 2.5,
        vy = sin(spread_angle) * 2.5,
        damage = 15,
        pattern = 3
      })
    end
  end
  
  sfx(3)
end

-- ========================================
-- 혼문 생성
-- ========================================

function create_portal()
  local px = 8 + rnd(48)
  local py = 32 + rnd(64)
  
  add(portals, {
    x = px,
    y = py,
    timer = 0,
    spawn_count = flr(1 + rnd(3)),
    lifetime = 300,
    anim = 0
  })
end

-- ========================================
-- 혼문 업데이트
-- ========================================

function update_portals()
  local cfg = stage_config[stage]
  
  for p in all(portals) do
    p.timer += 1
    p.anim = (p.anim + 1) % 60
    
    if p.timer % 30 == 0 and p.spawn_count > 0 and #enemies < cfg.max_enemies then
      spawn_enemy(p.x, p.y)
      p.spawn_count -= 1
    end
    
    p.lifetime -= 1
    if p.lifetime <= 0 or p.spawn_count <= 0 then
      del(portals, p)
    end
  end
end

-- ========================================
-- 악령 생성
-- ========================================

function spawn_enemy(x, y)
  add(enemies, {
    x = x,
    y = y,
    w = 8,
    h = 8,
    vx = -0.5 + rnd(1),
    vy = -0.5 + rnd(1),
    hp = 20,
    damage = 10,
    type = flr(1 + rnd(3)),
    anim_frame = 0
  })
end

-- ========================================
-- 악령 업데이트
-- ========================================

function update_enemies()
  for e in all(enemies) do
    local dx = player.x - e.x
    local dy = player.y - e.y
    local dist = sqrt(dx * dx + dy * dy)
    
    if dist > 0 then
      e.vx = (dx / dist) * 0.5
      e.vy = (dy / dist) * 0.5
    end
    
    e.x += e.vx
    e.y += e.vy
    
    e.anim_frame = (e.anim_frame + 1) % 30
    
    if e.x < -8 or e.x > 136 or e.y < -8 or e.y > 136 then
      del(enemies, e)
    end
  end
end

-- ========================================
-- 투사체 업데이트
-- ========================================

function update_projectiles()
  -- 음표 업데이트
  for n in all(notes) do
    n.x += n.vx
    n.y += n.vy
    
    if n.x < 0 or n.x > 128 or n.y < 0 or n.y > 128 then
      del(notes, n)
    end
  end
  
  -- 보스 공격 업데이트 (플랫폼 충돌 체크)
  for b in all(boss_bullets) do
    b.x += b.vx
    b.y += b.vy
    
    -- 플랫폼에 막힘
    local blocked = false
    for p in all(platforms) do
      if b.x + b.w > p.x and
         b.x < p.x + p.w and
         b.y + b.h > p.y and
         b.y < p.y + p.h then
        blocked = true
        break
      end
    end
    
    if blocked or b.x < 0 or b.x > 128 or b.y < 0 or b.y > 128 then
      del(boss_bullets, b)
    end
  end
end

-- ========================================
-- 충돌 감지
-- ========================================

function check_collisions()
  -- 음표 vs 악령
  for n in all(notes) do
    for e in all(enemies) do
      if collide(n, e) then
        e.hp -= n.damage
        del(notes, n)
        if e.hp <= 0 then
          del(enemies, e)
          player.special = min(100, player.special + 10)
          sfx(2)
        end
        break
      end
    end
  end
  
  -- 음표 vs 보스
  for n in all(notes) do
    if collide(n, boss) then
      boss.hp -= n.damage
      del(notes, n)
      player.special = min(100, player.special + 5)
      sfx(3)
    end
  end
  
  -- 악령 vs 플레이어
  for e in all(enemies) do
    if collide(e, player) then
      player.hp -= e.damage
      del(enemies, e)
      sfx(4)
    end
  end
  
  -- 보스 공격 vs 플레이어
  for b in all(boss_bullets) do
    if collide(b, player) then
      player.hp -= b.damage
      del(boss_bullets, b)
      sfx(4)
    end
  end
end

function collide(a, b)
  return a.x < b.x + b.w and
         a.x + a.w > b.x and
         a.y < b.y + b.h and
         a.y + a.h > b.y
end

-- ========================================
-- 지누 시스템
-- ========================================

function update_jinu()
  if player.special >= 100 and not jinu_active then
    activate_jinu()
  end
  
  if jinu_active then
    jinu_timer -= 1
    if jinu_timer <= 0 then
      jinu_active = false
    end
  end
end

function activate_jinu()
  jinu_active = true
  jinu_timer = 60
  
  enemies = {}
  boss.hp -= boss.max_hp * 0.2
  player.special = 0
  
  sfx(5)
end

-- ========================================
-- 게임 상태 체크
-- ========================================

function check_game_state()
  if player.hp <= 0 then
    game_state = "gameover"
    sfx(7)
  end
  
  if boss.hp <= 0 and not stage_clear then
    stage_clear = true
    stage_clear_timer = 0
    sfx(6)
  end
end

-- ========================================
-- 메인 그리기 루프
-- ========================================

function _draw()
  cls(1)
  
  if game_state == "title" then
    draw_title()
  elseif game_state == "play" then
    draw_game()
  elseif game_state == "gameover" then
    draw_gameover()
  elseif game_state == "win" then
    draw_win()
  end
end

-- ========================================
-- 게임 화면 그리기
-- ========================================

function draw_game()
  rectfill(0, 0, 127, 127, 1)
  
  -- 플랫폼 그리기
  for p in all(platforms) do
    rectfill(p.x, p.y, p.x + p.w - 1, p.y + p.h - 1, 5)
    -- 플랫폼 테두리
    rect(p.x, p.y, p.x + p.w - 1, p.y + p.h - 1, 6)
  end
  
  -- 혼문
  for p in all(portals) do
    draw_portal(p)
  end
  
  -- 악령
  for e in all(enemies) do
    draw_enemy(e)
  end
  
  -- 보스
  draw_boss()
  
  -- 보스 공격
  for b in all(boss_bullets) do
    circfill(b.x, b.y, 2, 8)  -- 빨간 공격
  end
  
  -- 음표
  for n in all(notes) do
    circfill(n.x, n.y, 2, 10)
  end
  
  -- 플레이어
  draw_player()
  
  -- UI
  draw_ui()
  
  -- 지누 이펙트
  if jinu_active then
    draw_jinu_effect()
  end
  
  -- 스테이지 클리어 메시지
  if stage_clear then
    rectfill(20, 50, 108, 70, 0)
    rect(20, 50, 108, 70, 7)
    if stage < 3 then
      print("stage clear!", 38, 56, 11)
      print("press x to next stage", 26, 62, 7)
    else
      print("Congratulations! final clear!", 36, 58, 11)
    end
  end
end

function draw_player()
  local color = 12
  rectfill(player.x, player.y, player.x + 7, player.y + 7, color)
  
  if player.facing > 0 then
    line(player.x + 7, player.y + 3, player.x + 9, player.y + 3, 7)
  else
    line(player.x, player.y + 3, player.x - 2, player.y + 3, 7)
  end
end

function draw_boss()
  rectfill(boss.x, boss.y, boss.x + 15, boss.y + 15, 8)
  circfill(boss.x + 4, boss.y + 6, 1, 7)
  circfill(boss.x + 11, boss.y + 6, 1, 7)
  
  local hp_width = (boss.hp / boss.max_hp) * 16
  rectfill(boss.x, boss.y - 4, boss.x + 15, boss.y - 2, 0)
  rectfill(boss.x, boss.y - 4, boss.x + hp_width - 1, boss.y - 2, 8)
end

function draw_enemy(e)
  local colors = {11, 3, 14}
  circfill(e.x, e.y, 4, colors[e.type])
  pset(e.x - 1, e.y - 1, 0)
  pset(e.x + 1, e.y - 1, 0)
end

function draw_portal(p)
  local frame = flr(p.anim / 15) % 4
  for i = 0, 7 do
    local angle = i / 8 + frame / 16
    local x = p.x + cos(angle) * 8
    local y = p.y + sin(angle) * 8
    circfill(x, y, 2, 13)
  end
  circfill(p.x, p.y, 3, 2)
end

function draw_ui()
  print("hp", 2, 2, 7)
  rectfill(14, 2, 64, 6, 0)
  rectfill(14, 2, 14 + (player.hp / player.max_hp) * 50, 6, 8)
  
  print("special", 2, 10, 7)
  rectfill(30, 10, 80, 14, 0)
  rectfill(30, 10, 30 + (player.special / 100) * 50, 14, 10)
  
  print("stage " .. stage, 90, 2, 7)
  print("enemies: " .. #enemies, 82, 10, 7)
end

function draw_jinu_effect()
  for i = 0, 127, 8 do
    for j = 0, 127, 8 do
      if (i + j) % 16 == jinu_timer % 16 then
        rectfill(i, j, i + 7, j + 7, 10)
      end
    end
  end
  print("jinu!", 48, 60, 7)
end

function draw_title()
  cls(0)
  print("golden", 45, 40, 10)
  print("k-pop demon hunters", 24, 50, 7)
  print("press x or z to start", 18, 70, 6)
end

function draw_gameover()
  cls(0)
  print("game over", 40, 60, 8)
  print("press x to restart", 24, 70, 7)
end

function draw_win()
  cls(0)
  print("you win!", 45, 50, 11)
  print("all stages clear!", 28, 60, 10)
  print("press x to restart", 24, 70, 7)
end