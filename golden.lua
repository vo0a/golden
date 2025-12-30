-- golden - 케이팝 데몬 헌터스
-- 지팡이 든 로미 버전 v2.2

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
  
  -- 플랫폼 생성 타이머
  platform_spawn_timer = 0

  music(-1)
  music(1)
end

-- ========================================
-- 플랫폼 초기화 (구조물) - 동적 생성
-- ========================================

function init_platforms()
  platforms = {}
  
  -- 기본 땅 (영구적) - 179, 180, 181번 스프라이트로 그려짐
  add(platforms, {x=0, y=120, w=128, h=8, permanent=true})
  
  -- 초기 플랫폼 생성 (4-5개)
  local num_platforms = 4 + flr(rnd(2))
  for i=1,num_platforms do
    spawn_random_platform()
  end
end

-- ========================================
-- 랜덤 위치에 플랫폼 생성
-- ========================================

function spawn_random_platform()
  local px = 10 + rnd(90)
  local py = 40 + rnd(70)
  local pw = 15 + rnd(25)
  
  -- 기존 플랫폼과 너무 가까우면 위치 조정
  local attempts = 0
  local too_close = true
  
  while too_close and attempts < 10 do
    too_close = false
    for p in all(platforms) do
      if abs(px - p.x) < 30 and abs(py - p.y) < 20 then
        too_close = true
        px = 10 + rnd(90)
        py = 40 + rnd(70)
        break
      end
    end
    attempts += 1
  end
  
  add(platforms, {
    x = px,
    y = py,
    w = pw,
    h = 4
  })
end

-- ========================================
-- 플랫폼 업데이트 (7초마다 전체 교체)
-- ========================================

function update_platforms()
  -- 7초마다 (420프레임) 모든 플랫폼 교체
  platform_spawn_timer += 1
  if platform_spawn_timer >= 420 then
    platform_spawn_timer = 0
    
    -- 땅을 제외한 모든 플랫폼 제거
    local temp_platforms = {}
    for p in all(platforms) do
      if p.permanent then
        add(temp_platforms, p)
      else
        del(platforms, p)
      end
    end
    platforms = temp_platforms
    
    -- 새로운 플랫폼 생성 (4-5개)
    local num_platforms = 4 + flr(rnd(2))
    for i=1,num_platforms do
      spawn_random_platform()
    end
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
    shoot_cooldown = 0,
    attack_anim = 0,  -- 공격 애니메이션 카운터
    sprite = 100  -- 003번 스프라이트 (지팡이 든 로미)
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
    w = 32,  -- 4x4 스프라이트 = 32픽셀
    h = 32,  -- 4x4 스프라이트 = 32픽셀
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
    anim_frame = 0,
    dodge_cooldown = 0,
    sprite = 200  -- 귀마 스프라이트 200번부터 시작
  }
end

-- ========================================
-- 메인 업데이트 루프
-- ========================================

function _update60()
  frame += 1
  
  if game_state == "play" then
    if stat(54) != 1 then  -- 현재 Music이 1번이 아니면
      music(1)  -- Music 1 재생
    end

    if stage_clear then
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
      update_platforms()
      update_projectiles()
      check_collisions()
      update_jinu()
    end
    
  check_game_state()

  elseif game_state == "title" then
    if btnp(4) or btnp(5) then
      music(-1)  -- 음악 정지
      game_state = "play"
      music(1)
    end
  elseif game_state == "gameover" then
    if btnp(4) or btnp(5) then
      music(-1)  -- 음악 정지
      _init()
    end
  elseif game_state == "win" then
    if stat(54) != 0 and stat(54) != -1 then
        music(-1)  -- 다른 Music이 재생되면 정지
    end
    
    if btnp(4) or btnp(5) then
        music(-1)  -- 음악 정지
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
    music(-1)  -- 음악 정지
    music(0) -- 승리 음악
  else
    stage_clear = false
    stage_clear_timer = 0
    platform_spawn_timer = 0

    -- 체력/게이지 저장
    local saved_special = player.special
    local saved_hp = player.hp
    
    init_player()
    init_boss()
    init_platforms()

    -- 체력/게이지 복원
    player.special = saved_special
    player.hp = saved_hp

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
    sfx(3)
  end
  
  -- 아래 점프 (구조물 통과)
  if btnp(3) and player.grounded then
    player.y += 8
    player.grounded = false
    player.vy = 1
  end
  
  -- 하강 (공중에서)
  if btn(3) and not player.grounded then
    player.vy = 4
  end
  
  -- 공격 (지팡이 휘두르기)
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
  
  -- 공격 애니메이션 카운터 감소
  if player.attack_anim > 0 then
    player.attack_anim -= 1
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
  
  -- 애니메이션 프레임 업데이트
  if player.vx != 0 then
    player.anim_frame = (player.anim_frame + 1) % 32
  else
    player.anim_frame = 0
  end
  
  -- 스프라이트는 항상 003번 (지팡이 든 로미)
  player.sprite = 100
end

-- ========================================
-- 음표 발사 (지팡이 공격 - 000번 스프라이트)
-- ========================================

function shoot_note()
  -- 공격 애니메이션 시작 (지팡이 휘두르기)
  player.attack_anim = 10  -- 10프레임 동안 공격 모션
  
  -- 000번 스프라이트 발사
  -- 오른쪽 보면 오른쪽에서, 왼쪽 보면 왼쪽에서 지팡이이 나감
  add(notes, {
    x = player.x + (player.facing > 0 and 10 or -10),  -- 오른쪽: +10, 왼쪽: -10
    y = player.y,
    w = 8,
    h = 8,
    vx = player.facing * 3,
    vy = 0,
    damage = 10,
    sprite = 0  -- 000번 스프라이트 사용
  })
end

-- ========================================
-- 보스 업데이트
-- ========================================

function update_boss()
  local cfg = stage_config[stage]
  
  -- 회피 쿨다운 감소
  if boss.dodge_cooldown > 0 then
    boss.dodge_cooldown -= 1
  end
  
  -- 스테이지별 회피 확률
  local dodge_chance = 0
  if stage == 2 then
    dodge_chance = 0.5
  elseif stage == 3 then
    dodge_chance = 0.7
  end
  
  -- 플레이어 회피
  if boss.dodge_cooldown <= 0 then
    local dx = boss.x - player.x
    local dy = boss.y - player.y
    local dist = sqrt(dx * dx + dy * dy)
    
    if dist < 30 and rnd(1) < dodge_chance then
      boss.target_x = boss.x + sgn(dx) * 15
      boss.target_y = boss.y + sgn(dy) * 15
      boss.dodge_cooldown = 60
    end
  end
  
  -- 음표 회피
  if boss.dodge_cooldown <= 0 then
    for n in all(notes) do
      local ndx = n.x - boss.x
      local ndy = n.y - boss.y
      local ndist = sqrt(ndx * ndx + ndy * ndy)
      if ndist < 20 and rnd(1) < dodge_chance then
        boss.target_x = boss.x - sgn(ndx) * 15
        boss.target_y = boss.y - sgn(ndy) * 15
        boss.dodge_cooldown = 60
        break
      end
    end
  end
  
  -- 랜덤 이동
  boss.move_timer += 1
  if boss.move_timer > 180 then
    boss.target_x = 32 + rnd(64)  -- 화면 내 랜덤 (4x4 크기 고려)
    boss.target_y = 16 + rnd(48)
    boss.move_timer = 0
  end
  
  -- 이동
  boss.vx = (boss.target_x - boss.x) * 0.1 * cfg.boss_speed
  boss.vy = (boss.target_y - boss.y) * 0.1 * cfg.boss_speed
  boss.x += boss.vx
  boss.y += boss.vy
  
  -- 화면 경계 제한 (4x4 크기 고려)
  boss.x = mid(8, boss.x, 96)   -- 32픽셀 크기 고려
  boss.y = mid(8, boss.y, 80)
  
  -- 혼문 생성
  boss.portal_timer += 1
  if boss.portal_timer >= cfg.portal_interval and #enemies < cfg.max_enemies then
    create_portal()
    boss.portal_timer = 0
  end
  
  -- 보스 공격 패턴
  boss.attack_timer += 1
  if boss.attack_timer >= 120 then
    boss_attack()
    boss.attack_timer = 0
  end
  
  -- 애니메이션
  boss.anim_frame = (boss.anim_frame + 1) % 60
end

-- ========================================
-- 보스 공격 패턴
-- ========================================
function boss_attack()
  local pattern = stage
  
  -- 플레이어 방향 계산
  local dx = player.x - boss.x
  local dy = player.y - boss.y
  local dist = sqrt(dx * dx + dy * dy)
  
  local dir_x = 0
  local dir_y = 0
  if dist > 0 then
    dir_x = dx / dist
    dir_y = dy / dist
  end
  
  if pattern == 1 then
    -- 패턴 1: 단일 공격 (속도 감소)
    add(boss_bullets, {
      x = boss.x + 16,
      y = boss.y + 16,
      w = 8,  -- 크기 증가
      h = 8,
      vx = dir_x * 1,  -- 속도 2 → 1로 감소
      vy = dir_y * 1,
      damage = 15,
      pattern = 1,
      sprite = 69  -- 69번 스프라이트
    })
    
  elseif pattern == 2 then
    -- 패턴 2: 3방향 (속도 감소)
    local angle = atan2(dx, dy)
    for i=-1,1 do
      local spread_angle = angle + i * 0.1
      add(boss_bullets, {
        x = boss.x + 16,
        y = boss.y + 16,
        w = 8,
        h = 8,
        vx = cos(spread_angle) * 2,  -- 속도 2 
        vy = sin(spread_angle) * 2,
        damage = 15,
        pattern = 2,
        sprite = 69
      })
    end
    
  else
    -- 패턴 3: 5방향 (속도 감소)
    local angle = atan2(dx, dy)
    for i=-2,2 do
      local spread_angle = angle + i * 0.08
      add(boss_bullets, {
        x = boss.x + 16,
        y = boss.y + 16,
        w = 8,
        h = 8,
        vx = cos(spread_angle) * 2.5,  -- 속도 2.5
        vy = sin(spread_angle) * 2.5,
        damage = 15,
        pattern = 3,
        sprite = 69
      })
    end
  end
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
  local enemy_type = flr(1 + rnd(3))  -- 1-3 타입 랜덤
  
  -- 몬스터 스프라이트 번호
  -- 타입 1: 027/028
  -- 타입 2: 043/044  
  -- 타입 3: 059/060
  local sprite_numbers = {27, 43, 59}
  
  add(enemies, {
    x = x,
    y = y,
    w = 8,
    h = 8,
    vx = -0.5 + rnd(1),
    vy = -0.5 + rnd(1),
    hp = 20,
    damage = 10,
    type = enemy_type,
    anim_frame = 0,
    facing = 1,
    sprite = sprite_numbers[enemy_type]  -- 27, 43, 59 중 하나
  })
end

-- ========================================
-- 악령 그리기 (타입별 스프라이트, 좌우 반전)
-- ========================================

function draw_enemy(e)
  -- facing에 따라 스프라이트 선택
  -- 오른쪽(facing=1): 27, 43, 59
  -- 왼쪽(facing=-1): 28, 44, 60
  local sprite_num = e.sprite
  if e.facing < 0 then
    sprite_num = e.sprite + 1  -- 27→28, 43→44, 59→60
  end
  
  spr(sprite_num, e.x, e.y)
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
      e.vx = (dx / dist) * 0.8
      e.vy = (dy / dist) * 0.8
      
      -- 이동 방향에 따라 facing 업데이트
      if e.vx > 0.1 then
        e.facing = 1
      elseif e.vx < -0.1 then
        e.facing = -1
      end
    end
    
    e.x += e.vx
    e.y += e.vy
    
    if abs(e.vx) > 0.1 or abs(e.vy) > 0.1 then
      e.anim_frame = (e.anim_frame + 1) % 30
    else
      e.anim_frame = 0
    end
    
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
  
  -- 보스 공격 업데이트
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
          sfx(1)
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
      sfx(1)
    end
  end
  
  -- 악령 vs 플레이어
  for e in all(enemies) do
    if collide(e, player) then
      player.hp -= e.damage
      del(enemies, e)
      sfx(0)
    end
  end
  
  -- 보스 공격 vs 플레이어
  for b in all(boss_bullets) do
    if collide(b, player) then
      player.hp -= b.damage
      del(boss_bullets, b)
      sfx(0)
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
  
  sfx(2)
end

-- ========================================
-- 게임 상태 체크
-- ========================================

function check_game_state()
  if player.hp <= 0 then
    game_state = "gameover"
    music(-1)  -- 음악 정지
    music(-1)  -- 음악 정지
    music(2) -- 게임오버 음악
  end
  
  if boss.hp <= 0 and not stage_clear then
    stage_clear = true
    stage_clear_timer = 0
    music(-1)  -- 음악 정지
    music(-1)  -- 음악 정지
    music(0) -- 승리 음악
  end
end

-- ========================================
-- 메인 그리기 루프
-- ========================================

function _draw()
  cls(1)
  map()
  
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
  -- 배경색 제거 (map으로 대체)
  -- rectfill(0, 0, 127, 127, 1)
  
  -- 플랫폼 그리기
  for p in all(platforms) do
    if p.permanent then
      -- 영구 플랫폼 (기본 땅) - 179, 180, 181번 스프라이트로 채우기
      -- 왼쪽: 179, 중간: 180 (반복), 오른쪽: 181
      spr(179, p.x, p.y)  -- 왼쪽 끝
      for i = 8, p.w - 8, 8 do
        spr(180, p.x + i, p.y)  -- 중간 타일 반복
      end
      spr(181, p.x + p.w - 8, p.y)  -- 오른쪽 끝
    else
      -- 일반 플랫폼 (스프라이트 177번 사용)
      local remaining = 420 - platform_spawn_timer
      -- 남은 시간이 60프레임 미만이면 깜빡이는 효과
      if remaining < 60 then
        -- 깜빡이는 효과: 5프레임마다 번갈아가며 표시
        if flr(remaining / 5) % 2 == 0 then
          -- 플랫폼을 8픽셀 단위로 스프라이트 타일링
          for i = 0, p.w - 1, 8 do
            spr(177, p.x + i, p.y)
          end
        end
        -- 깜빡일 때는 그리지 않음 (다음 프레임에 다시 그려짐)
      else
        -- 정상 상태: 항상 그리기
        for i = 0, p.w - 1, 8 do
          spr(177, p.x + i, p.y)
        end
      end
    end
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
    spr(b.sprite, b.x, b.y)
  end
  
  -- 플레이어 공격 (000번 스프라이트)
  for n in all(notes) do
    spr(n.sprite, n.x, n.y)
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
      print("press x to next stage", 20, 62, 7)
    else
      print("final clear!", 36, 56, 11)
      print("press x to finish", 28, 62, 7)
    end
  end
end

-- ========================================
-- 플레이어 그리기 (로미 본체 100-103 + 지팡이 3번 분리)
-- ========================================

function draw_player()
  -- 1. 로미 본체 그리기 (100-103번 중 현재 애니메이션 스프라이트)
  -- update_player()에서 이미 올바른 sprite 번호가 설정되어 있음
  
  if not player.grounded then
    -- 점프/공중
    if player.facing > 0 then
      spr(100, player.x, player.y)  -- 오른쪽 기본
    else
      spr(102, player.x, player.y)  -- 왼쪽 기본
    end
  elseif player.vx != 0 then
    -- 이동 애니메이션
    if player.facing > 0 then
      spr(100 + flr(player.anim_frame / 8) % 2, player.x, player.y)  -- 100, 101
    else
      spr(102 + flr(player.anim_frame / 8) % 2, player.x, player.y)  -- 102, 103
    end
  else
    -- 기본 자세
    if player.facing > 0 then
      spr(100, player.x, player.y)  -- 오른쪽 기본
    else
      spr(102, player.x, player.y)  -- 왼쪽 기본
    end
  end
  
  -- 2. 지팡이를를 방향에 따라 로미 옆에 그리기 (1번 스프라이트)
  local flip_x = player.facing < 0
  if player.facing > 0 then
    -- 오른쪽 볼 때: 로미 오른쪽에 지팡이
    spr(1, player.x + 6, player.y, 1, 1, false)
  else
    -- 왼쪽 볼 때: 로미 왼쪽에 지팡이
    spr(1, player.x - 6, player.y, 1, 1, true)
  end
  
  -- 공격 애니메이션 중이면 지팡이 휘두르기 이펙트 추가
  if player.attack_anim > 0 then
    local sword_x = player.x + (player.facing > 0 and 8 or -4)
    local sword_y = player.y + 2
    local offset = (10 - player.attack_anim) * 2
    
    -- 지팡이 궤적 이펙트 (하얀색 선)
    line(
      sword_x, 
      sword_y, 
      sword_x + player.facing * offset, 
      sword_y - offset / 2, 
      7
    )
  end
end

-- ========================================
-- 보스 그리기 (2x2 스프라이트)
-- ========================================

function draw_boss()
  -- 4x4 크기로 귀마 그리기 (sprite: 200번부터)
  spr(boss.sprite, boss.x, boss.y, 4, 4)
  
  -- 체력 바 (더 길게)
  local hp_width = (boss.hp / boss.max_hp) * 32
  rectfill(boss.x, boss.y - 4, boss.x + 31, boss.y - 2, 0)
  rectfill(boss.x, boss.y - 4, boss.x + hp_width - 1, boss.y - 2, 8)
end

-- ========================================
-- 혼문 그리기
-- ========================================

function draw_portal(p)
  local frame = flr(p.anim / 15) % 4
  for i = 0, 7 do
    local angle = i / 8 + frame / 16
    local x = p.x + cos(angle) * 8
    local y = p.y + sin(angle) * 8
    -- 주변 원형 애니메이션도 143번 스프라이트 사용
    spr(159, x - 4, y - 4)  -- 스프라이트 중심 정렬 (8x8 스프라이트)
  end
  -- 중심 143번 스프라이트
  spr(159, p.x - 4, p.y - 4)
end

-- ========================================
-- UI 그리기
-- ========================================

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

-- ========================================
-- 지누 이펙트 (스프라이트 사용)
-- ========================================

function draw_jinu_effect()
  -- 화면 중앙에 큰 지누 스프라이트 (4x4 크기)
  local jinu_x = 64 - 16  -- 중앙 정렬 (32픽셀의 절반 = 16)
  local jinu_y = 64 - 16
  
  -- 지누 스프라이트: 기본(192) <-> 윙크(196) 번갈아가며
  local jinu_sprite = 192  -- 기본 지누
  if flr(jinu_timer / 10) % 2 == 0 then
    jinu_sprite = 196  -- 윙크 지누
  end
  
  -- 배경 이펙트 (번쩍이는 효과 - 더 화려하게)
  -- 효과 1: 체크무늬 번쩍임
  for i = 0, 127, 8 do
    for j = 0, 127, 8 do
      if (i + j) % 16 == jinu_timer % 16 then
        rectfill(i, j, i + 7, j + 7, 10)  -- 노란색
      end
    end
  end
  
  -- 효과 2: 방사형 라인 (선택사항)
  for i = 0, 7 do
    local angle = (i / 8) + (jinu_timer / 60)
    local x1 = 64 + cos(angle) * 20
    local y1 = 64 + sin(angle) * 20
    local x2 = 64 + cos(angle) * 50
    local y2 = 64 + sin(angle) * 50
    line(x1, y1, x2, y2, 7)  -- 흰색 라인
  end
  
  -- 효과 3: 반짝이는 별 (선택사항)
  for i = 1, 10 do
    local star_x = 10 + rnd(108)
    local star_y = 10 + rnd(108)
    if (jinu_timer + i * 6) % 12 < 6 then
      pset(star_x, star_y, 7)  -- 흰색 별
      pset(star_x + 1, star_y, 10)  -- 노란색 별
    end
  end
  
  -- 지누 스프라이트 (4x4 크기로 크게)
  spr(jinu_sprite, jinu_x, jinu_y, 4, 4)
  
  -- 텍스트 (지누 아래쪽에, 반짝이는 효과)
  local text_color = 7
  if jinu_timer % 10 < 5 then
    text_color = 10  -- 노란색으로 반짝
  end
  print("jinu!", 48, 88, text_color)
end

-- ========================================
-- 타이틀 화면
-- ========================================

function draw_title()
  cls(0)
  print("golden", 45, 40, 10)
  print("k-pop demon hunters", 24, 50, 7)
  print("press x to start", 18, 70, 6)
end

-- ========================================
-- 게임 오버 화면
-- ========================================

function draw_gameover()
  cls(0)
  print("game over", 40, 60, 8)
  print("press x to restart", 24, 70, 7)
end

-- ========================================
-- 승리 화면
-- ========================================

function draw_win()
  cls(0)
  print("you win!", 45, 50, 11)
  print("all stages clear!", 28, 60, 10)
  print("press x to restart", 24, 70, 7)
end