function _init()
  -- 게임 상태 (title, play, gameover, win)
  game_state = "play"
  
  -- 현재 스테이지 (1-3)
  stage = 1
  
  -- 프레임 카운터
  frame = 0
  
  -- 플레이어 초기화
  init_player()
  
  -- 보스 초기화
  init_boss()
  
  -- 배열 초기화
  enemies = {}      -- 악령 배열
  portals = {}      -- 혼문 배열
  notes = {}        -- 음표(플레이어 공격) 배열
  boss_bullets = {} -- 보스 공격 배열
  
  -- 지누 시스템
  jinu_active = false
  jinu_timer = 0
end

-- ========================================
-- 플레이어 초기화
-- ========================================

function init_player()
  player = {
    x = 32,           -- x 좌표
    y = 100,          -- y 좌표
    w = 8,            -- 너비
    h = 8,            -- 높이
    vx = 0,           -- x 속도
    vy = 0,           -- y 속도
    grounded = true,  -- 땅에 닿아있는지
    jump_count = 0,   -- 점프 횟수 (이단점프용)
    hp = 100,         -- 체력
    max_hp = 100,     -- 최대 체력
    special = 0,      -- 특수 게이지 (0-100)
    facing = 1,       -- 방향 (1: 오른쪽, -1: 왼쪽)
    anim_frame = 0,   -- 애니메이션 프레임
    shoot_cooldown = 0 -- 공격 쿨다운
  }
end

-- ========================================
-- 보스 초기화
-- ========================================

function init_boss()
  boss = {
    x = 96,           -- x 좌표
    y = 40,           -- y 좌표
    w = 16,           -- 너비
    h = 16,           -- 높이
    vx = 0,           -- x 속도
    vy = 0,           -- y 속도
    hp = 100,         -- 현재 체력
    max_hp = 100,     -- 최대 체력
    phase = 1,        -- 현재 페이즈
    portal_timer = 0, -- 혼문 생성 타이머
    move_timer = 0,   -- 이동 패턴 타이머
    target_x = 96,    -- 목표 x 좌표
    target_y = 40,    -- 목표 y 좌표
    anim_frame = 0    -- 애니메이션 프레임
  }
end

-- ========================================
-- 메인 업데이트 루프
-- ========================================

function _update60()
  frame += 1
  
  if game_state == "play" then
    -- 입력 처리
    update_input()
    
    -- 플레이어 업데이트
    update_player()
    
    -- 보스 업데이트
    update_boss()
    
    -- 적 업데이트
    update_enemies()
    
    -- 혼문 업데이트
    update_portals()
    
    -- 투사체 업데이트
    update_projectiles()
    
    -- 충돌 감지
    check_collisions()
    
    -- 지누 시스템 업데이트
    update_jinu()
    
    -- 게임 상태 체크
    check_game_state()
    
  elseif game_state == "title" then
    -- 타이틀 화면 입력
    if btnp(4) or btnp(5) then
      game_state = "play"
    end
  end
end

-- ========================================
-- 입력 처리
-- ========================================

function update_input()
  -- 좌우 이동
  if btn(0) then  -- 왼쪽
    player.vx = -2
    player.facing = -1
  elseif btn(1) then  -- 오른쪽
    player.vx = 2
    player.facing = 1
  else
    player.vx = 0
  end
  
  -- 점프 (이단 점프 가능)
  if btnp(4) and player.jump_count < 2 then
    player.vy = -4
    player.jump_count += 1
    sfx(0)  -- 점프 사운드
  end
  
  -- 하강 (공중에서)
  if btn(3) and not player.grounded then
    player.vy = 4
  end
  
  -- 공격
  if btnp(5) and player.shoot_cooldown <= 0 then
    shoot_note()
    player.shoot_cooldown = 15  -- 0.25초 쿨다운
  end
end

-- ========================================
-- 플레이어 업데이트
-- ========================================

function update_player()
  -- 쿨다운 감소
  if player.shoot_cooldown > 0 then
    player.shoot_cooldown -= 1
  end
  
  -- 중력 적용
  if not player.grounded then
    player.vy += 0.3  -- 중력
    if player.vy > 4 then
      player.vy = 4  -- 최대 낙하 속도
    end
  end
  
  -- 위치 업데이트
  player.x += player.vx
  player.y += player.vy
  
  -- 화면 경계 체크 (좌우)
  if player.x < 0 then
    player.x = 0
  elseif player.x > 120 then
    player.x = 120
  end
  
  -- 땅 체크 (y = 112)
  if player.y >= 112 then
    player.y = 112
    player.vy = 0
    player.grounded = true
    player.jump_count = 0
  else
    player.grounded = false
  end
  
  -- 천장 체크
  if player.y < 8 then
    player.y = 8
    player.vy = 0
  end
  
  -- 애니메이션 프레임 업데이트
  if player.vx != 0 then
    player.anim_frame = (player.anim_frame + 1) % 32
  else
    player.anim_frame = 0
  end
end

-- ========================================
-- 음표 발사 (플레이어 공격)
-- ========================================

function shoot_note()
  add(notes, {
    x = player.x + (player.facing > 0 and 8 or 0),
    y = player.y + 3,
    w = 4,
    h = 4,
    vx = player.facing * 3,  -- 방향에 따라 속도
    vy = 0,
    damage = 10
  })
  sfx(1)  -- 공격 사운드
end

-- ========================================
-- 보스 업데이트
-- ========================================

function update_boss()
  -- 회피 이동 (플레이어에게서 멀어지기)
  local dx = boss.x - player.x
  local dy = boss.y - player.y
  local dist = sqrt(dx * dx + dy * dy)
  
  -- 플레이어가 가까우면 도망
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
  
  -- 랜덤 이동 (3초마다)
  boss.move_timer += 1
  if boss.move_timer > 180 then
    boss.target_x = 64 + rnd(48)  -- 화면 우측 영역
    boss.target_y = 20 + rnd(60)
    boss.move_timer = 0
  end
  
  -- 목표 지점으로 부드럽게 이동
  boss.vx = (boss.target_x - boss.x) * 0.1
  boss.vy = (boss.target_y - boss.y) * 0.1
  boss.x += boss.vx
  boss.y += boss.vy
  
  -- 화면 경계 제한
  boss.x = mid(16, boss.x, 112)
  boss.y = mid(16, boss.y, 96)
  
  -- 혼문 생성 (5초마다)
  boss.portal_timer += 1
  if boss.portal_timer >= 300 and #enemies < 10 then
    create_portal()
    boss.portal_timer = 0
  end
  
  -- 애니메이션
  boss.anim_frame = (boss.anim_frame + 1) % 60
end

-- ========================================
-- 혼문 생성
-- ========================================

function create_portal()
  -- 화면 좌측에 랜덤 위치 생성
  local px = 8 + rnd(48)
  local py = 32 + rnd(64)
  
  add(portals, {
    x = px,
    y = py,
    timer = 0,
    spawn_count = flr(1 + rnd(3)),  -- 1-3마리 생성
    lifetime = 300,  -- 5초 수명
    anim = 0
  })
end

-- ========================================
-- 혼문 업데이트
-- ========================================

function update_portals()
  for p in all(portals) do
    p.timer += 1
    p.anim = (p.anim + 1) % 60
    
    -- 0.5초마다 악령 생성
    if p.timer % 30 == 0 and p.spawn_count > 0 and #enemies < 10 then
      spawn_enemy(p.x, p.y)
      p.spawn_count -= 1
    end
    
    -- 수명 감소
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
    vx = -0.5 + rnd(1),  -- 랜덤 x 속도
    vy = -0.5 + rnd(1),  -- 랜덤 y 속도
    hp = 20,
    damage = 10,
    type = flr(1 + rnd(3)),  -- 타입 1-3
    anim_frame = 0
  })
end

-- ========================================
-- 악령 업데이트
-- ========================================

function update_enemies()
  for e in all(enemies) do
    -- 플레이어를 향해 이동
    local dx = player.x - e.x
    local dy = player.y - e.y
    local dist = sqrt(dx * dx + dy * dy)
    
    if dist > 0 then
      e.vx = (dx / dist) * 0.5
      e.vy = (dy / dist) * 0.5
    end
    
    e.x += e.vx
    e.y += e.vy
    
    -- 애니메이션
    e.anim_frame = (e.anim_frame + 1) % 30
    
    -- 화면 밖으로 나가면 제거
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
    
    -- 화면 밖으로 나가면 제거
    if n.x < 0 or n.x > 128 or n.y < 0 or n.y > 128 then
      del(notes, n)
    end
  end
  
  -- 보스 공격 업데이트
  for b in all(boss_bullets) do
    b.x += b.vx
    b.y += b.vy
    
    -- 화면 밖으로 나가면 제거
    if b.x < 0 or b.x > 128 or b.y < 0 or b.y > 128 then
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
          sfx(2)  -- 처치 사운드
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
      sfx(3)  -- 보스 피격 사운드
    end
  end
  
  -- 악령 vs 플레이어
  for e in all(enemies) do
    if collide(e, player) then
      player.hp -= e.damage
      del(enemies, e)
      sfx(4)  -- 피격 사운드
    end
  end
end

-- ========================================
-- 충돌 체크 함수
-- ========================================

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
  -- 자동 발동 (게이지 100%)
  if player.special >= 100 and not jinu_active then
    activate_jinu()
  end
  
  -- 지누 활성화 타이머
  if jinu_active then
    jinu_timer -= 1
    if jinu_timer <= 0 then
      jinu_active = false
    end
  end
end

function activate_jinu()
  jinu_active = true
  jinu_timer = 60  -- 1초 애니메이션
  
  -- 모든 악령 제거
  enemies = {}
  
  -- 보스 체력 20% 감소
  boss.hp -= boss.max_hp * 0.2
  
  -- 게이지 초기화
  player.special = 0
  
  sfx(5)  -- 지누 등장 사운드
end

-- ========================================
-- 게임 상태 체크
-- ========================================

function check_game_state()
  -- 플레이어 사망
  if player.hp <= 0 then
    game_state = "gameover"
    sfx(7)
  end
  
  -- 보스 처치
  if boss.hp <= 0 then
    game_state = "win"
    sfx(6)
  end
end

-- ========================================
-- 메인 그리기 루프
-- ========================================

function _draw()
  cls(1)  -- 배경색 (진한 파란색)
  
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
  -- 배경
  rectfill(0, 0, 127, 127, 1)
  
  -- 땅
  rectfill(0, 120, 127, 127, 3)
  
  -- 혼문 그리기
  for p in all(portals) do
    draw_portal(p)
  end
  
  -- 악령 그리기
  for e in all(enemies) do
    draw_enemy(e)
  end
  
  -- 보스 그리기
  draw_boss()
  
  -- 투사체 그리기
  for n in all(notes) do
    circfill(n.x, n.y, 2, 10)  -- 노란색 음표
  end
  
  -- 플레이어 그리기
  draw_player()
  
  -- UI 그리기
  draw_ui()
  
  -- 지누 이펙트
  if jinu_active then
    draw_jinu_effect()
  end
end

-- ========================================
-- 플레이어 그리기
-- ========================================

function draw_player()
  -- 간단한 사각형으로 표현
  local color = 12  -- 하늘색
  rectfill(player.x, player.y, player.x + 7, player.y + 7, color)
  
  -- 방향 표시 (작은 삼각형)
  if player.facing > 0 then
    line(player.x + 7, player.y + 3, player.x + 9, player.y + 3, 7)
  else
    line(player.x, player.y + 3, player.x - 2, player.y + 3, 7)
  end
end

-- ========================================
-- 보스 그리기
-- ========================================

function draw_boss()
  -- 큰 사각형으로 표현
  rectfill(boss.x, boss.y, boss.x + 15, boss.y + 15, 8)  -- 빨간색
  
  -- 눈
  circfill(boss.x + 4, boss.y + 6, 1, 7)
  circfill(boss.x + 11, boss.y + 6, 1, 7)
  
  -- 체력바
  local hp_width = (boss.hp / boss.max_hp) * 16
  rectfill(boss.x, boss.y - 4, boss.x + 15, boss.y - 2, 0)
  rectfill(boss.x, boss.y - 4, boss.x + hp_width - 1, boss.y - 2, 8)
end

-- ========================================
-- 악령 그리기
-- ========================================

function draw_enemy(e)
  -- 타입별 색상
  local colors = {11, 3, 14}  -- 연두, 진녹색, 보라
  circfill(e.x, e.y, 4, colors[e.type])
  
  -- 눈
  pset(e.x - 1, e.y - 1, 0)
  pset(e.x + 1, e.y - 1, 0)
end

-- ========================================
-- 혼문 그리기
-- ========================================

function draw_portal(p)
  -- 회전하는 원형 효과
  local frame = flr(p.anim / 15) % 4
  for i = 0, 7 do
    local angle = i / 8 + frame / 16
    local x = p.x + cos(angle) * 8
    local y = p.y + sin(angle) * 8
    circfill(x, y, 2, 13)  -- 연보라색
  end
  
  -- 중앙
  circfill(p.x, p.y, 3, 2)  -- 진보라색
end

-- ========================================
-- UI 그리기
-- ========================================

function draw_ui()
  -- 플레이어 체력바
  print("hp", 2, 2, 7)
  rectfill(14, 2, 64, 6, 0)
  rectfill(14, 2, 14 + (player.hp / player.max_hp) * 50, 6, 8)
  
  -- 특수 게이지
  print("special", 2, 10, 7)
  rectfill(30, 10, 80, 14, 0)
  rectfill(30, 10, 30 + (player.special / 100) * 50, 14, 10)
  
  -- 스테이지 정보
  print("stage " .. stage, 90, 2, 7)
  
  -- 악령 수
  print("enemies: " .. #enemies, 90, 10, 7)
end

-- ========================================
-- 지누 이펙트
-- ========================================

function draw_jinu_effect()
  -- 화면 전체 플래시
  for i = 0, 127, 8 do
    for j = 0, 127, 8 do
      if (i + j) % 16 == jinu_timer % 16 then
        rectfill(i, j, i + 7, j + 7, 10)
      end
    end
  end
  
  -- 중앙 텍스트
  print("jinu!", 48, 60, 7)
end

-- ========================================
-- 타이틀 화면
-- ========================================

function draw_title()
  cls(0)
  print("golden", 45, 40, 10)
  print("k-pop demon hunters", 24, 50, 7)
  print("press x or z to start", 18, 70, 6)
end

-- ========================================
-- 게임 오버 화면
-- ========================================

function draw_gameover()
  cls(0)
  print("game over", 40, 60, 8)
  print("press x to restart", 24, 70, 7)
  
  if btnp(4) then
    _init()
  end
end

-- ========================================
-- 승리 화면
-- ========================================

function draw_win()
  cls(0)
  print("you win!", 45, 60, 11)
  print("press x to restart", 24, 70, 7)
  
  if btnp(4) then
    _init()
  end
end
