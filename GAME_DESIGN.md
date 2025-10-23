# Golden - 케이팝 데몬 헌터스 컨셉 게임 개발 가이드

## 📋 게임 개요

**게임명**: Golden  
**플랫폼**: PICO-8  
**장르**: 2D 액션 격투 게임  
**컨셉**: 케이팝 데몬 헌터스

### 스토리

주인공 '로미'가 세 단계 스테이지를 거쳐 최종 보스 악당 '귀마'를 물리치는 액션 게임입니다. 찢어진 혼문에서 나오는 악령들과 싸우며, 조력자 '지누'의 도움을 받아 귀마를 무찌릅니다.

---

## 🎮 조작법

| 버튼   | 기능             |
| ------ | ---------------- |
| ←/→    | 좌우 이동        |
| ❎ (X) | 점프 / 이단 점프 |
| ⬇      | 하강 (공중에서)  |
| 🅾️ (Z) | 공격 (음표 발사) |

---

## 👥 캐릭터

### 로미 (주인공)

- 데몬 헌터로, 음표를 발사하여 적을 공격
- 이동, 점프, 이단 점프, 하강, 공격 가능
- 특수 게이지를 모아 지누를 소환 가능

### 지누 (조력자)

- 로미의 특수 게이지가 100% 차면 등장
- 등장 시 효과:
  - 화면의 모든 악령 즉시 제거
  - 귀마의 체력 20% 감소
  - 화려한 이펙트와 함께 등장

### 귀마 (최종 보스)

- 3개 스테이지에 걸쳐 등장
- 각 스테이지마다 강력해짐
- 체력과 공격 패턴이 단계별로 증가
- **회피 행동**: 로미의 공격을 피하기 위해 화면을 돌아다님
- **혼문 생성**: 전투 중 계속해서 새로운 혼문을 만들어냄

### 악령

- 찢어진 혼문에서 지속적으로 생성
- 로미를 방해하는 적 몬스터
- 처치하면 특수 게이지 증가

---

## 🗺️ 스테이지 구성

### 스테이지 1 - 시작의 혼문

- **귀마 체력**: 100
- **귀마 이동 속도**: 느림 (1 픽셀/프레임)
- **최대 동시 악령 수**: 10마리
- **혼문 생성 간격**: 5초
- **혼문 위치**: 랜덤 (화면 좌측 영역)
- **악령 생성 수**: 1-3마리 (랜덤)
- **보스 공격 패턴**: 기본 (단순 직선 공격)

### 스테이지 2 - 균열의 혼문

- **귀마 체력**: 150
- **귀마 이동 속도**: 보통 (1.5 픽셀/프레임)
- **최대 동시 악령 수**: 15마리
- **혼문 생성 간격**: 4초
- **혼문 위치**: 랜덤 (화면 전체 영역)
- **악령 생성 수**: 2-4마리 (랜덤)
- **보스 공격 패턴**: 중급 (직선 + 곡선 공격)

### 스테이지 3 - 최후의 혼문

- **귀마 체력**: 200
- **귀마 이동 속도**: 빠름 (2 픽셀/프레임)
- **최대 동시 악령 수**: 25마리
- **혼문 생성 간격**: 3초
- **혼문 위치**: 랜덤 (화면 전체 영역)
- **악령 생성 수**: 3-5마리 (랜덤)
- **보스 공격 패턴**: 고급 (다중 패턴 믹스)

---

## ⚙️ 게임 시스템 설계

### 1. 플레이어 시스템 (로미)

#### 속성

```lua
player = {
  x = 64,          -- x 좌표
  y = 100,         -- y 좌표
  w = 8,           -- 너비
  h = 8,           -- 높이
  vx = 0,          -- x 속도
  vy = 0,          -- y 속도
  grounded = true, -- 땅에 닿아있는지
  jump_count = 0,  -- 점프 횟수 (이단점프용)
  hp = 100,        -- 체력
  special = 0,     -- 특수 게이지 (0-100)
  facing = 1,      -- 방향 (1: 오른쪽, -1: 왼쪽)
}
```

#### 주요 기능

- **이동**: 속도 2 픽셀/프레임
- **점프**: 초기 속도 -4, 중력 0.2
- **이단 점프**: 점프 횟수 2회까지
- **하강**: 공중에서 ⬇ 입력 시 빠른 낙하 (속도 2배)
- **공격**: 음표 발사 (속도 3, 데미지 10)

### 2. 특수 게이지 시스템

#### 게이지 증가 조건

- 악령 처치: +5
- 보스 공격 성공: +10
- 시간 경과: +1 (2초마다)

#### 지누 소환 (게이지 100%)

1. 특수 애니메이션 재생 (1초)
2. 화면의 모든 악령 제거
3. 귀마 체력 20% 감소
4. 게이지 0으로 초기화

### 3. 적 시스템

#### 악령

```lua
enemy = {
  x = 0,           -- x 좌표
  y = 0,           -- y 좌표
  vx = 1,          -- x 속도 (로미를 향해 이동)
  vy = 0,          -- y 속도
  hp = 20,         -- 체력
  damage = 10,     -- 접촉 데미지
  type = 1,        -- 타입 (1-3)
}
```

#### 귀마 (보스)

```lua
boss = {
  x = 96,          -- x 좌표
  y = 32,          -- y 좌표
  vx = 0,          -- x 속도
  vy = 0,          -- y 속도
  hp = 100,        -- 체력 (스테이지별 증가)
  max_hp = 100,    -- 최대 체력
  phase = 1,       -- 현재 스테이지
  pattern = 1,     -- 공격 패턴
  attack_timer = 0,-- 공격 타이머
  portal_timer = 0,-- 혼문 생성 타이머
  move_timer = 0,  -- 이동 패턴 타이머
  target_x = 96,   -- 목표 x 좌표
  target_y = 32,   -- 목표 y 좌표
}
```

**보스 AI 행동**:

- **회피 이동**: 로미가 가까이 오거나 음표가 날아오면 반대 방향으로 이동
- **랜덤 이동**: 일정 시간마다 화면 내 랜덤 위치로 이동
- **혼문 생성**: 스테이지별 간격으로 랜덤 위치에 혼문 생성
- **악령 수 제한**: 현재 악령 수가 최대치 미만일 때만 혼문에서 악령 생성

### 4. 혼문 시스템

```lua
portal = {
  x = 0,           -- x 좌표 (랜덤 생성)
  y = 0,           -- y 좌표 (랜덤 생성)
  timer = 0,       -- 생성 타이머
  spawn_count = 0, -- 생성할 악령 수 (1-5 랜덤)
  lifetime = 300,  -- 혼문 지속 시간 (5초)
  anim = 0,        -- 애니메이션 프레임
}

-- 스테이지별 설정
stage_config = {
  max_enemies = 10,    -- 최대 동시 악령 수
  portal_interval = 300, -- 혼문 생성 간격 (프레임)
  spawn_min = 1,       -- 최소 악령 생성 수
  spawn_max = 3,       -- 최대 악령 생성 수
}
```

**혼문 생성 규칙**:

- 귀마가 일정 시간마다 랜덤 위치에 혼문 생성
- 혼문 위치는 화면 좌측 또는 중앙 영역에 랜덤 배치
- 각 혼문은 생성 시 랜덤 개수(1-5마리)의 악령 생성
- 현재 악령 수가 최대치를 초과하면 생성 중단
- 혼문은 일정 시간 후 소멸 (찢어진 효과 애니메이션)

### 5. 투사체 시스템

#### 음표 (로미 공격)

```lua
note = {
  x = 0,
  y = 0,
  vx = 3,          -- 속도
  vy = 0,
  damage = 10,     -- 데미지
  type = "note",   -- 타입
}
```

#### 보스 공격

```lua
boss_bullet = {
  x = 0,
  y = 0,
  vx = -2,         -- 속도 (왼쪽으로)
  vy = 0,
  damage = 15,     -- 데미지
  pattern = 1,     -- 패턴 번호
}
```

---

## 💻 PICO-8 구현 가이드

### 파일 구조

게임은 단일 `.p8` 파일로 구성됩니다.

### 주요 함수

```lua
-- PICO-8 표준 함수
function _init()
  -- 게임 초기화
end

function _update()
  -- 게임 로직 업데이트 (60fps)
end

function _draw()
  -- 화면 그리기
end
```

### 1. 초기화 (\_init)

```lua
function _init()
  -- 게임 상태
  game_state = "title"  -- title, play, gameover, win
  stage = 1             -- 현재 스테이지

  -- 스테이지별 설정
  stage_configs = {
    {max_enemies=10, portal_interval=300, spawn_min=1, spawn_max=3, boss_speed=1},
    {max_enemies=15, portal_interval=240, spawn_min=2, spawn_max=4, boss_speed=1.5},
    {max_enemies=25, portal_interval=180, spawn_min=3, spawn_max=5, boss_speed=2}
  }

  -- 플레이어 초기화
  init_player()

  -- 보스 초기화
  init_boss()

  -- 배열 초기화
  enemies = {}
  portals = {}
  notes = {}
  boss_bullets = {}
end
```

### 2. 업데이트 (\_update)

```lua
function _update()
  if game_state == "play" then
    -- 입력 처리
    update_input()

    -- 플레이어 업데이트
    update_player()

    -- 특수 게이지 업데이트
    update_special()

    -- 보스 업데이트 (이동 및 혼문 생성)
    update_boss()

    -- 적 업데이트
    update_enemies()

    -- 혼문 업데이트
    update_portals()

    -- 투사체 업데이트
    update_projectiles()

    -- 충돌 감지
    check_collisions()

    -- 게임 상태 체크
    check_game_state()
  end
end

-- 보스 업데이트 함수
function update_boss()
  local cfg = stage_configs[stage]

  -- 회피 이동 (로미에게서 멀어지기)
  local dx = boss.x - player.x
  local dy = boss.y - player.y
  local dist = sqrt(dx*dx + dy*dy)

  if dist < 40 then  -- 로미가 가까우면 도망
    boss.target_x = boss.x + sgn(dx) * 20
    boss.target_y = boss.y + sgn(dy) * 20
  end

  -- 음표 회피
  for n in all(notes) do
    local ndx = n.x - boss.x
    local ndy = n.y - boss.y
    local ndist = sqrt(ndx*ndx + ndy*ndy)
    if ndist < 30 then  -- 음표가 가까우면 회피
      boss.target_x = boss.x - sgn(ndx) * 25
      boss.target_y = boss.y - sgn(ndy) * 25
    end
  end

  -- 랜덤 이동 (3초마다)
  boss.move_timer += 1
  if boss.move_timer > 180 then
    boss.target_x = 64 + rnd(64)  -- 화면 우측 영역
    boss.target_y = 16 + rnd(80)
    boss.move_timer = 0
  end

  -- 목표 지점으로 이동
  boss.vx = (boss.target_x - boss.x) * 0.1 * cfg.boss_speed
  boss.vy = (boss.target_y - boss.y) * 0.1 * cfg.boss_speed
  boss.x += boss.vx
  boss.y += boss.vy

  -- 화면 경계 제한
  boss.x = mid(16, boss.x, 112)
  boss.y = mid(16, boss.y, 96)

  -- 혼문 생성
  boss.portal_timer += 1
  if boss.portal_timer >= cfg.portal_interval and #enemies < cfg.max_enemies then
    create_portal()
    boss.portal_timer = 0
  end
end

-- 혼문 생성 함수
function create_portal()
  local cfg = stage_configs[stage]
  local px, py

  -- 랜덤 위치 결정
  if stage == 1 then
    px = 8 + rnd(48)  -- 좌측 영역
    py = 32 + rnd(64)
  else
    px = 8 + rnd(96)  -- 전체 영역
    py = 16 + rnd(80)
  end

  add(portals, {
    x = px,
    y = py,
    timer = 0,
    spawn_count = flr(cfg.spawn_min + rnd(cfg.spawn_max - cfg.spawn_min + 1)),
    lifetime = 300,
    anim = 0
  })
end
```

### 3. 그리기 (\_draw)

```lua
function _draw()
  cls()  -- 화면 지우기

  if game_state == "title" then
    draw_title()
  elseif game_state == "play" then
    -- 배경
    draw_background()

    -- 혼문
    draw_portals()

    -- 적
    draw_enemies()

    -- 보스
    draw_boss()

    -- 투사체
    draw_projectiles()

    -- 플레이어
    draw_player()

    -- UI
    draw_ui()

    -- 지누 이펙트
    if jinu_active then
      draw_jinu_effect()
    end
  elseif game_state == "gameover" then
    draw_gameover()
  elseif game_state == "win" then
    draw_win()
  end
end
```

### 4. 입력 처리

```lua
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

  -- 점프
  if btnp(4) and player.jump_count < 2 then
    player.vy = -4
    player.jump_count += 1
    sfx(0)  -- 점프 사운드
  end

  -- 하강
  if btn(3) and not player.grounded then
    player.vy = 4
  end

  -- 공격
  if btnp(5) then
    shoot_note()
    sfx(1)  -- 공격 사운드
  end
end
```

### 5. 충돌 감지

```lua
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
      end
    end

    -- 음표 vs 보스
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

  -- 보스 공격 vs 플레이어
  for b in all(boss_bullets) do
    if collide(b, player) then
      player.hp -= b.damage
      del(boss_bullets, b)
      sfx(4)  -- 피격 사운드
    end
  end
end

function collide(a, b)
  return a.x < b.x + b.w and
         a.x + a.w > b.x and
         a.y < b.y + b.h and
         a.y + a.h > b.y
end
```

### 6. 지누 시스템

```lua
function activate_jinu()
  if player.special >= 100 then
    -- 지누 활성화
    jinu_active = true
    jinu_timer = 60  -- 1초 애니메이션

    -- 모든 악령 제거
    enemies = {}

    -- 보스 체력 20% 감소
    boss.hp -= boss.max_hp * 0.2

    -- 게이지 초기화
    player.special = 0

    -- 사운드 재생
    sfx(5)  -- 지누 등장 사운드
  end
end

function update_jinu()
  if jinu_active then
    jinu_timer -= 1
    if jinu_timer <= 0 then
      jinu_active = false
    end
  end

  -- 자동 발동 (게이지 100%)
  if player.special >= 100 then
    activate_jinu()
  end
end

-- 혼문 업데이트 함수
function update_portals()
  local cfg = stage_configs[stage]

  for p in all(portals) do
    p.timer += 1
    p.anim = (p.anim + 1) % 60

    -- 일정 간격으로 악령 생성
    if p.timer % 30 == 0 and p.spawn_count > 0 and #enemies < cfg.max_enemies then
      -- 악령 생성
      local enemy_type = flr(1 + rnd(3))  -- 타입 1-3 랜덤
      add(enemies, {
        x = p.x,
        y = p.y,
        vx = -1 + rnd(2),
        vy = -1 + rnd(2),
        hp = 20 + (enemy_type - 1) * 10,
        damage = 10,
        type = enemy_type
      })
      p.spawn_count -= 1
    end

    -- 수명 종료 시 제거
    p.lifetime -= 1
    if p.lifetime <= 0 or p.spawn_count <= 0 then
      del(portals, p)
    end
  end
end
```

---

## 🎨 스프라이트 및 애니메이션

### PICO-8 스프라이트 인덱스

| 스프라이트  | 인덱스 | 설명                      |
| ----------- | ------ | ------------------------- |
| 로미 (정지) | 1-2    | 좌우 방향                 |
| 로미 (이동) | 3-6    | 걷기 애니메이션 (4프레임) |
| 로미 (점프) | 7      | 점프/공중                 |
| 지누        | 8-11   | 등장 애니메이션 (4프레임) |
| 귀마        | 16-19  | 보스 기본 (4프레임)       |
| 악령 타입1  | 32-33  | 기본 악령                 |
| 악령 타입2  | 34-35  | 빠른 악령                 |
| 악령 타입3  | 36-37  | 강한 악령                 |
| 음표        | 48     | 공격 투사체               |
| 보스 공격   | 49-51  | 보스 투사체               |
| 혼문        | 64-67  | 찢어진 혼문 (4프레임)     |

### 애니메이션 타이밍

- 걷기: 8프레임마다 변경
- 혼문: 15프레임마다 변경
- 지누: 15프레임마다 변경

---

## 🎵 사운드 및 음악

### 효과음 (SFX)

| 인덱스 | 효과음          | 설명          |
| ------ | --------------- | ------------- |
| 0      | 점프            | 짧은 상승음   |
| 1      | 공격            | 음표 발사     |
| 2      | 악령 처치       | 폭발음        |
| 3      | 보스 피격       | 묵직한 타격음 |
| 4      | 피격            | 플레이어 피해 |
| 5      | 지누 등장       | 화려한 효과음 |
| 6      | 스테이지 클리어 | 승리 팡파레   |
| 7      | 게임 오버       | 슬픈 음악     |

### 배경 음악 (Music)

| 패턴 | 용도        | 설명                         |
| ---- | ----------- | ---------------------------- |
| 0    | 타이틀      | 밝고 경쾌한 케이팝 스타일    |
| 1    | 스테이지 1  | 긴장감 있는 전투 음악 (저음) |
| 2    | 스테이지 2  | 더 빠른 전투 음악 (중음)     |
| 3    | 스테이지 3  | 최고 긴장감 전투 음악 (고음) |
| 4    | 게임 클리어 | 승리 음악                    |

---

## 📊 게임 밸런스

### 데미지 설정

| 대상               | 데미지               |
| ------------------ | -------------------- |
| 로미 공격 → 악령   | 10                   |
| 로미 공격 → 보스   | 10                   |
| 악령 → 로미        | 10                   |
| 보스 공격 → 로미   | 15                   |
| 지누 특수기 → 보스 | 보스 최대 체력의 20% |

### 체력 설정

| 캐릭터     | 스테이지 1 | 스테이지 2 | 스테이지 3 |
| ---------- | ---------- | ---------- | ---------- |
| 로미       | 100        | 100        | 100        |
| 악령 타입1 | 20         | 20         | 20         |
| 악령 타입2 | 30         | 30         | 30         |
| 악령 타입3 | 40         | 40         | 40         |
| 귀마       | 100        | 150        | 200        |

### 특수 게이지 획득량

| 행동            | 게이지 증가 |
| --------------- | ----------- |
| 악령 처치       | +10         |
| 보스 공격 성공  | +5          |
| 시간 경과 (2초) | +1          |

---

## 🔄 게임 진행 흐름

```
타이틀 화면
    ↓
[스테이지 1 시작]
    ↓
악령 등장 (혼문 2개)
    ↓
보스 '귀마' 공격 (체력 100)
    ↓
게이지 충전 → 지누 소환 가능
    ↓
스테이지 1 클리어
    ↓
[스테이지 2 시작]
    ↓
악령 등장 (혼문 3개, 더 빠름)
    ↓
보스 '귀마' 강화 (체력 150)
    ↓
스테이지 2 클리어
    ↓
[스테이지 3 시작]
    ↓
악령 등장 (혼문 4개, 매우 빠름)
    ↓
보스 '귀마' 최종 형태 (체력 200)
    ↓
최종 승리!
    ↓
엔딩 화면
```

---

## 🛠️ 개발 단계

### Phase 1: 기본 시스템 (1-2일)

- [ ] 플레이어 이동 및 점프
- [ ] 기본 공격 시스템
- [ ] 화면 경계 처리
- [ ] 중력 및 물리

### Phase 2: 적 시스템 (1-2일)

- [ ] 악령 생성 및 이동
- [ ] 동적 혼문 시스템 (랜덤 위치, 랜덤 생성 수)
- [ ] 혼문 애니메이션 및 수명 관리
- [ ] 충돌 감지
- [ ] 기본 AI

### Phase 3: 보스 시스템 (2-3일)

- [ ] 보스 등장
- [ ] 회피 이동 AI (플레이어/투사체 회피)
- [ ] 랜덤 이동 패턴
- [ ] 혼문 생성 능력
- [ ] 공격 패턴 (3종)
- [ ] 체력 바
- [ ] 단계별 강화 (속도, 최대 악령 수)

### Phase 4: 특수 시스템 (1-2일)

- [ ] 특수 게이지 시스템
- [ ] 지누 소환 메커니즘
- [ ] 특수기 이펙트

### Phase 5: UI 및 게임플로우 (1-2일)

- [ ] 타이틀 화면
- [ ] 스테이지 전환
- [ ] 게임 오버/클리어 화면
- [ ] UI 요소 (체력, 게이지 등)

### Phase 6: 폴리싱 (2-3일)

- [ ] 스프라이트 및 애니메이션
- [ ] 사운드 및 음악
- [ ] 파티클 이펙트
- [ ] 게임 밸런싱
- [ ] 버그 수정

---

## 📝 PICO-8 토큰 최적화 팁

PICO-8은 8192 토큰 제한이 있으므로 최적화가 중요합니다.

1. **짧은 변수명 사용**

   ```lua
   -- 나쁨
   player_x_position = 64

   -- 좋음
   px = 64
   ```

2. **함수 재사용**

   ```lua
   -- 공통 함수로 추출
   function spr_anim(s,x,y,t,n)
     spr(s+flr(t/8)%n,x,y)
   end
   ```

3. **테이블 최소화**

   ```lua
   -- 필요한 속성만 저장
   p={x=64,y=100,vx=0,vy=0}
   ```

4. **조건문 단축**

   ```lua
   -- 나쁨
   if x > 0 then
     return true
   else
     return false
   end

   -- 좋음
   return x > 0
   ```

---

## 🎯 핵심 게임플레이 목표

1. **생존**: 악령과 보스 공격을 피하며 체력 유지
2. **공격**: 음표로 악령과 보스 공격
3. **게이지 관리**: 특수 게이지를 채워 지누 소환 타이밍 조절
4. **진행**: 3개 스테이지를 모두 클리어

---

## 🚀 시작하기

1. PICO-8 실행
2. 새 카트 생성: `NEW`
3. 스프라이트 에디터에서 캐릭터 디자인
4. 코드 에디터에서 게임 로직 작성
5. 테스트: `RUN`
6. 저장: `SAVE GOLDEN`

---

## 📚 추가 자료

- PICO-8 매뉴얼: https://www.lexaloffle.com/pico-8.php
- PICO-8 치트시트: https://www.lexaloffle.com/bbs/?tid=28207
- Lua 튜토리얼: https://www.lua.org/manual/5.2/

---

## 🎲 랜덤 시스템 상세

### 혼문 생성 메커니즘

귀마는 전투 중 지속적으로 혼문을 생성하여 악령을 소환합니다:

1. **생성 타이밍**

   - 스테이지 1: 5초마다 (300 프레임)
   - 스테이지 2: 4초마다 (240 프레임)
   - 스테이지 3: 3초마다 (180 프레임)

2. **생성 위치** (랜덤)

   - 스테이지 1: 화면 좌측 영역 (X: 8-56, Y: 32-96)
   - 스테이지 2-3: 화면 전체 영역 (X: 8-104, Y: 16-96)

3. **악령 생성 수** (랜덤)

   - 스테이지 1: 1-3마리
   - 스테이지 2: 2-4마리
   - 스테이지 3: 3-5마리

4. **최대 악령 제한**
   - 스테이지 1: 최대 10마리
   - 스테이지 2: 최대 15마리
   - 스테이지 3: 최대 25마리
   - 현재 악령 수가 최대치에 도달하면 혼문이 생성되지 않음

### 보스 회피 AI

귀마는 다음과 같은 상황에서 회피 행동을 합니다:

1. **플레이어 근접 회피**

   - 로미가 40픽셀 이내로 접근하면 반대 방향으로 이동
   - 거리 비례 회피 속도

2. **투사체 회피**

   - 음표가 30픽셀 이내로 접근하면 즉시 회피
   - 음표의 궤적을 피하는 방향으로 이동

3. **랜덤 이동**

   - 3초마다 화면 내 랜덤 위치로 자동 이동
   - 전투를 역동적으로 만드는 요소

4. **이동 속도**
   - 스테이지 1: 1 픽셀/프레임
   - 스테이지 2: 1.5 픽셀/프레임
   - 스테이지 3: 2 픽셀/프레임

### 게임플레이 팁

**플레이어 전략**:

- 귀마가 도망다니므로 예측 사격이 중요합니다
- 악령을 처치하여 특수 게이지를 빠르게 채우세요
- 지누 소환 타이밍을 잘 활용하면 많은 악령을 한번에 제거할 수 있습니다
- 스테이지가 진행될수록 악령이 많아지므로 위치 선정이 중요합니다
- 혼문이 열릴 때마다 대비하여 공격 준비를 하세요

---

**개발 시작일**: 2025-10-12  
**목표 완성일**: 2주 이내  
**버전**: 1.0.0

좋은 게임 만들기를 응원합니다! 화이팅! 🎮✨

**점수 시스템**

- 보스를 물리칠 때마다 점수를 획득합니다.
- 보스를 물리치는 시간, 피해량 등에 따라 추가 보너스 점수가 주어질 수 있습니다.

**기술 스택**

- 언어: lua 기반으로 개발합니다.
- 프레임워크: pico-8을 사용하여 구조와 상태 관리를 구현합니다.
