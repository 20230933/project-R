(() => {
  "use strict";

  const FIELD_WIDTH = 960;
  const FIELD_HEIGHT = 1080;
  const BOSS_MAX_HP = 6000;
  const BOSS_SEGMENTS = 10;

  const POOL_SIZE = {
    playerBullet: 500,
    enemyBullet: 3000,
    item: 2000,
  };

  const COLORS = {
    player: "#5ce8ff",
    hitCore: "#ffe26d",
    enemy: "#ff3ea6",
    enemyBullet: "#ff30a2",
    grazeRing: "rgba(92,232,255,0.16)",
    item: "#7effa5",
    boss: "#d84fff",
  };

  const keys = new Set();
  const DEFAULT_BINDINGS = {
    moveUp: "ArrowUp",
    moveDown: "ArrowDown",
    moveLeft: "ArrowLeft",
    moveRight: "ArrowRight",
    shoot: "KeyZ",
    format: "KeyX",
    focus: "ShiftLeft",
  };

  let keyBindings = {
    ...DEFAULT_BINDINGS,
    ...JSON.parse(localStorage.getItem("rumi_key_bindings") || "{}"),
  };

  const canvas = document.getElementById("gameCanvas");
  const ctx = canvas.getContext("2d");

  const ui = {
    highScore: document.getElementById("highScoreValue"),
    score: document.getElementById("scoreValue"),
    playTime: document.getElementById("playTimeValue"),
    life: document.getElementById("lifeValue"),
    power: document.getElementById("powerValue"),
    graze: document.getElementById("grazeValue"),
    bossHp: document.getElementById("bossHpValue"),
    logList: document.getElementById("logList"),
    ctlMove: document.getElementById("ctlMove"),
    ctlFocus: document.getElementById("ctlFocus"),
    ctlShoot: document.getElementById("ctlShoot"),
    ctlFormat: document.getElementById("ctlFormat"),
    menuOverlay: document.getElementById("menuOverlay"),
    menuTitle: document.getElementById("menuTitle"),
    menuSubtitle: document.getElementById("menuSubtitle"),
    menuButtons: document.getElementById("menuButtons"),
    settingsOverlay: document.getElementById("settingsOverlay"),
    resultOverlay: document.getElementById("resultOverlay"),
    resultTitle: document.getElementById("resultTitle"),
    resultScore: document.getElementById("resultScore"),
    resultTime: document.getElementById("resultTime"),
    retryBtn: document.getElementById("retryBtn"),
    toTitleBtn: document.getElementById("toTitleBtn"),
    bgmVolume: document.getElementById("bgmVolume"),
    sfxVolume: document.getElementById("sfxVolume"),
    voiceVolume: document.getElementById("voiceVolume"),
    displayMode: document.getElementById("displayMode"),
    displayScale: document.getElementById("displayScale"),
    resetBindingBtn: document.getElementById("resetBindingBtn"),
    bindingHint: document.getElementById("bindingHint"),
    applySettingsBtn: document.getElementById("applySettingsBtn"),
    closeSettingsBtn: document.getElementById("closeSettingsBtn"),
  };

  const state = {
    time: 0,
    score: 0,
    bestScore: Number(localStorage.getItem("rumi_best_score") || 0),
    life: 3,
    maxLife: 5,
    oneUpCount: 0,
    next1upScore: 3000000,
    powerPoint: 0,
    grazeGauge: 0,
    player: {
      x: FIELD_WIDTH * 0.5,
      y: FIELD_HEIGHT - 150,
      hitRadius: 2,
      grazeRadius: 20,
      shootCd: 0,
      invUntil: 0,
      blinkTick: 0,
    },
    format: {
      activeUntil: 0,
      grazeLockUntil: 0,
    },
    enemySpawnCd: 0,
    postDeathEaseUntil: 0,
    noHitTimer: 0,
    noHitMilestone: 0,
    waveSpeedBoost: false,
    normalEnemies: [],
    boss: null,
    bossStartTime: 0,
    phaseStartTime: 0,
    phaseEnraged: false,
    phase: 1,
    paused: false,
    gameStarted: false,
    gameOver: false,
    gameCleared: false,
    settingsReturnMenu: "title",
    waitingBindAction: null,
    hasProgressToContinue: false,
    settings: {
      bgm: Number(localStorage.getItem("rumi_bgm") || 60),
      sfx: Number(localStorage.getItem("rumi_sfx") || 80),
      voice: Number(localStorage.getItem("rumi_voice") || 70),
      displayMode: localStorage.getItem("rumi_display_mode") || "window",
      displayScale: localStorage.getItem("rumi_display_scale") || "1",
    },
    logs: [
      "Boot sequence complete.",
      "Blackout core detected.",
      "Avoid bullets and graze to charge Format.",
    ],
  };

  function powerLevel() {
    if (state.powerPoint >= 100) return 5;
    if (state.powerPoint >= 60) return 4;
    if (state.powerPoint >= 30) return 3;
    if (state.powerPoint >= 10) return 2;
    return 1;
  }

  function fireCooldownForLevel(level) {
    return level >= 4 ? 0.044 : 0.066;
  }

  function formatTime(seconds) {
    const s = Math.max(0, Math.floor(seconds));
    const mm = String(Math.floor(s / 60)).padStart(2, "0");
    const ss = String(s % 60).padStart(2, "0");
    return `${mm}:${ss}`;
  }

  function onScoreChanged() {
    if (state.score > state.bestScore) {
      state.bestScore = state.score;
      localStorage.setItem("rumi_best_score", String(state.bestScore));
    }

    while (state.score >= state.next1upScore) {
      if (state.life < state.maxLife) {
        state.life += 1;
        addLog("1UP granted.");
      }
      if (state.oneUpCount === 0) {
        state.next1upScore = 8000000;
      } else if (state.oneUpCount === 1) {
        state.next1upScore = 15000000;
      } else {
        state.next1upScore += 30000000;
      }
      state.oneUpCount += 1;
    }
  }

  function addScore(amount) {
    state.score += amount;
    onScoreChanged();
  }

  function keyLabel(code) {
    if (!code) return "-";
    if (code.startsWith("Key")) return code.slice(3);
    if (code.startsWith("Digit")) return code.slice(5);
    return code;
  }

  function isActionPressed(action) {
    const code = keyBindings[action];
    return code ? keys.has(code) : false;
  }

  function saveBindings() {
    localStorage.setItem("rumi_key_bindings", JSON.stringify(keyBindings));
  }

  function updateControlHints() {
    ui.ctlMove.textContent = `Move: ${keyLabel(keyBindings.moveUp)}/${keyLabel(keyBindings.moveDown)}/${keyLabel(keyBindings.moveLeft)}/${keyLabel(keyBindings.moveRight)}`;
    ui.ctlFocus.textContent = `Focus: ${keyLabel(keyBindings.focus)}`;
    ui.ctlShoot.textContent = `Shoot: ${keyLabel(keyBindings.shoot)}`;
    ui.ctlFormat.textContent = `Format: ${keyLabel(keyBindings.format)}`;

    const buttons = document.querySelectorAll(".bind-btn");
    buttons.forEach((btn) => {
      const action = btn.getAttribute("data-action");
      const actionName = action
        .replace("move", "")
        .replace(/^./, (s) => s.toUpperCase());
      btn.textContent = `${actionName}: ${keyLabel(keyBindings[action])}`;
    });
  }

  function closeSettings() {
    ui.settingsOverlay.classList.add("hidden");
    state.waitingBindAction = null;
    if (state.settingsReturnMenu === "pause") {
      showPauseMenu();
    } else {
      showTitleMenu();
    }
  }

  function openSettings(fromMenu) {
    state.settingsReturnMenu = fromMenu;
    ui.menuOverlay.classList.add("hidden");
    ui.settingsOverlay.classList.remove("hidden");
    ui.bindingHint.textContent = "Select a key action to remap.";
  }

  function applySettings() {
    state.settings.bgm = Number(ui.bgmVolume.value);
    state.settings.sfx = Number(ui.sfxVolume.value);
    state.settings.voice = Number(ui.voiceVolume.value);
    state.settings.displayMode = ui.displayMode.value;
    state.settings.displayScale = ui.displayScale.value;

    localStorage.setItem("rumi_bgm", String(state.settings.bgm));
    localStorage.setItem("rumi_sfx", String(state.settings.sfx));
    localStorage.setItem("rumi_voice", String(state.settings.voice));
    localStorage.setItem("rumi_display_mode", state.settings.displayMode);
    localStorage.setItem("rumi_display_scale", state.settings.displayScale);

    document.documentElement.style.setProperty("--battle-scale", state.settings.displayScale);
    if (state.settings.displayMode === "fullscreen") {
      if (!document.fullscreenElement) {
        document.documentElement.requestFullscreen().catch(() => {});
      }
    } else if (document.fullscreenElement) {
      document.exitFullscreen().catch(() => {});
    }
    addLog("Settings applied.");
    closeSettings();
  }

  function setMenu(title, subtitle, buttonDefs) {
    ui.menuTitle.textContent = title;
    ui.menuSubtitle.textContent = subtitle;
    ui.menuButtons.innerHTML = "";
    buttonDefs.forEach((def) => {
      const btn = document.createElement("button");
      btn.textContent = def.label;
      if (def.ghost) btn.classList.add("ghost");
      if (def.disabled) btn.disabled = true;
      btn.addEventListener("click", def.onClick);
      ui.menuButtons.appendChild(btn);
    });
    ui.resultOverlay.classList.add("hidden");
    ui.settingsOverlay.classList.add("hidden");
    ui.menuOverlay.classList.remove("hidden");
  }

  function showTitleMenu() {
    state.paused = true;
    setMenu("Title", "RUMI & Purifying Bloom", [
      { label: "Game Start", onClick: () => startGame(true) },
      {
        label: "Continue",
        disabled: !state.hasProgressToContinue || state.gameOver,
        onClick: () => continueGame(),
      },
      { label: "Settings", onClick: () => openSettings("title") },
      {
        label: "Game Exit",
        ghost: true,
        onClick: () => {
          window.close();
          addLog("Exit is browser-restricted. Close tab to quit.");
        },
      },
    ]);
  }

  function showPauseMenu() {
    state.paused = true;
    setMenu("Paused", "Simulation halted", [
      { label: "Resume", onClick: () => continueGame() },
      { label: "Restart", onClick: () => startGame(true) },
      { label: "Settings", onClick: () => openSettings("pause") },
      { label: "To Title", ghost: true, onClick: () => showTitleMenu() },
    ]);
  }

  function openResult(clear) {
    state.paused = true;
    state.gameOver = true;
    state.gameCleared = clear;
    state.hasProgressToContinue = false;
    ui.resultTitle.textContent = clear ? "Mission Clear" : "Game Over";
    ui.resultScore.textContent = String(state.score);
    ui.resultTime.textContent = formatTime(state.time);
    ui.menuOverlay.classList.add("hidden");
    ui.settingsOverlay.classList.add("hidden");
    ui.resultOverlay.classList.remove("hidden");
  }

  function resetObjects() {
    state.normalEnemies.length = 0;
    state.boss = null;
    pools.playerBullet.forEach(release);
    pools.enemyBullet.forEach(release);
    pools.item.forEach(release);
  }

  function startGame(fullReset) {
    if (fullReset) {
      state.time = 0;
      state.score = 0;
      state.life = 3;
      state.oneUpCount = 0;
      state.next1upScore = 3000000;
      state.powerPoint = 0;
      state.grazeGauge = 0;
      state.enemySpawnCd = 0;
      state.postDeathEaseUntil = 0;
      state.noHitTimer = 0;
      state.noHitMilestone = 0;
      state.waveSpeedBoost = false;
      state.phase = 1;
      state.phaseEnraged = false;
      state.phaseStartTime = 0;
      state.bossStartTime = 0;
      state.format.activeUntil = 0;
      state.format.grazeLockUntil = 0;
      state.player.x = FIELD_WIDTH * 0.5;
      state.player.y = FIELD_HEIGHT - 150;
      state.player.invUntil = 0;
      resetObjects();
    }
    state.paused = false;
    state.gameStarted = true;
    state.gameOver = false;
    state.gameCleared = false;
    state.hasProgressToContinue = true;
    ui.menuOverlay.classList.add("hidden");
    ui.settingsOverlay.classList.add("hidden");
    ui.resultOverlay.classList.add("hidden");
    addLog("Mission started.");
  }

  function continueGame() {
    if (!state.hasProgressToContinue || state.gameOver) return;
    state.paused = false;
    state.gameStarted = true;
    ui.menuOverlay.classList.add("hidden");
    ui.settingsOverlay.classList.add("hidden");
    addLog("Simulation resumed.");
  }

  function clamp(v, min, max) {
    return Math.max(min, Math.min(max, v));
  }

  function distSq(x1, y1, x2, y2) {
    const dx = x1 - x2;
    const dy = y1 - y2;
    return dx * dx + dy * dy;
  }

  function makePool(size, initFactory) {
    const arr = new Array(size);
    for (let i = 0; i < size; i += 1) {
      arr[i] = initFactory();
    }
    return arr;
  }

  const pools = {
    playerBullet: makePool(POOL_SIZE.playerBullet, () => ({
      active: false,
      x: 0,
      y: 0,
      vx: 0,
      vy: -1000,
      r: 4,
      damage: 10,
      splash: 0,
    })),
    enemyBullet: makePool(POOL_SIZE.enemyBullet, () => ({
      active: false,
      x: 0,
      y: 0,
      vx: 0,
      vy: 0,
      r: 4,
      grazed: false,
    })),
    item: makePool(POOL_SIZE.item, () => ({
      active: false,
      x: 0,
      y: 0,
      vx: 0,
      vy: 90,
      kind: "power",
      attract: false,
    })),
  };

  function spawnFromPool(pool, setup) {
    for (let i = 0; i < pool.length; i += 1) {
      const obj = pool[i];
      if (!obj.active) {
        obj.active = true;
        setup(obj);
        return obj;
      }
    }
    return null;
  }

  function release(obj) {
    obj.active = false;
  }

  function addLog(text) {
    state.logs.unshift(text);
    if (state.logs.length > 6) state.logs.length = 6;
    renderLogs();
  }

  function renderLogs() {
    ui.logList.innerHTML = "";
    for (let i = 0; i < state.logs.length; i += 1) {
      const li = document.createElement("li");
      li.textContent = state.logs[i];
      ui.logList.appendChild(li);
    }
  }

  function spawnPlayerBullet(angleDeg) {
    const rad = (angleDeg * Math.PI) / 180;
    const speed = 1300;
    const lvl = powerLevel();
    spawnFromPool(pools.playerBullet, (b) => {
      b.x = state.player.x;
      b.y = state.player.y - 20;
      b.vx = Math.sin(rad) * speed;
      b.vy = -Math.cos(rad) * speed;
      b.r = lvl >= 4 ? 6 : 4;
      b.damage = lvl === 5 ? 15 : 10;
      b.splash = lvl === 5 ? 30 : 0;
    });
  }

  function firePattern() {
    const lvl = powerLevel();
    if (lvl <= 1) {
      spawnPlayerBullet(0);
      return;
    }
    if (lvl === 2) {
      spawnPlayerBullet(-5);
      spawnPlayerBullet(5);
      return;
    }
    if (lvl <= 4) {
      spawnPlayerBullet(-30);
      spawnPlayerBullet(-5);
      spawnPlayerBullet(5);
      spawnPlayerBullet(30);
      return;
    }
    spawnPlayerBullet(-45);
    spawnPlayerBullet(-15);
    spawnPlayerBullet(0);
    spawnPlayerBullet(15);
    spawnPlayerBullet(45);
  }

  function spawnEnemy() {
    const profile = getStageProfile(state.time);
    const speedBoost = state.waveSpeedBoost ? 1.1 : 1;
    state.normalEnemies.push({
      x: 120 + Math.random() * (FIELD_WIDTH - 240),
      y: -20,
      hp: 30,
      bodyR: 20,
      shotCd: 0.65 + Math.random() * 0.4,
      speed: (80 + Math.random() * 40) * (profile.bulletSpeed / 160),
      bulletSpeed: profile.bulletSpeed * speedBoost,
      dropRate: profile.dropRate,
    });
  }

  function getStageProfile(timeSec) {
    if (timeSec < 60) {
      return { spawnInterval: 2.0, maxEnemies: 3, bulletSpeed: 160, dropRate: 0.35 };
    }
    if (timeSec < 120) {
      return { spawnInterval: 1.6, maxEnemies: 4, bulletSpeed: 190, dropRate: 0.28 };
    }
    if (timeSec < 180) {
      return { spawnInterval: 1.2, maxEnemies: 5, bulletSpeed: 220, dropRate: 0.2 };
    }
    return { spawnInterval: 0.9, maxEnemies: 6, bulletSpeed: 250, dropRate: 0.15 };
  }

  function spawnBoss() {
    state.boss = {
      x: FIELD_WIDTH * 0.5,
      y: 180,
      hp: BOSS_MAX_HP,
      bodyR: 56,
      moveT: 0,
      shotCd: 0,
      rot: 0,
      breakUntil: 0,
    };
    state.bossStartTime = state.time;
    state.phaseStartTime = state.time;
    state.phaseEnraged = false;
    state.phase = 1;
    addLog("System Overseer Alpha engaged.");
  }

  function spawnEnemyBullet(x, y, vx, vy, r) {
    spawnFromPool(pools.enemyBullet, (b) => {
      b.x = x;
      b.y = y;
      b.vx = vx;
      b.vy = vy;
      b.r = r;
      b.grazed = false;
    });
  }

  function enemyShootAtPlayer(enemy, speed = 260) {
    const dx = state.player.x - enemy.x;
    const dy = state.player.y - enemy.y;
    const len = Math.hypot(dx, dy) || 1;
    spawnEnemyBullet(enemy.x, enemy.y, (dx / len) * speed, (dy / len) * speed, 6);
  }

  function bossPattern(dt) {
    const boss = state.boss;
    if (!boss) return;

    const segmentCount = Math.max(1, Math.ceil((boss.hp / BOSS_MAX_HP) * BOSS_SEGMENTS));
    if (segmentCount <= 3) {
      state.phase = 3;
    } else if (segmentCount <= 6) {
      state.phase = 2;
    } else {
      state.phase = 1;
    }

    if (state.time < boss.breakUntil) {
      return;
    }

    const phaseElapsed = state.time - state.phaseStartTime;
    const enrage = phaseElapsed >= 120;
    state.phaseEnraged = enrage;
    const speedMult = enrage ? 1.5 : 1;
    const cadenceMult = enrage ? 1.5 : 1;

    boss.moveT += dt;
    boss.x = FIELD_WIDTH * 0.5 + Math.sin(boss.moveT * 0.9) * 220;

    boss.shotCd -= dt * cadenceMult;
    if (boss.shotCd > 0) return;

    if (state.phase === 1) {
      boss.shotCd = 0.34;
      for (let i = -2; i <= 2; i += 1) {
        const spread = i * 0.1;
        const dx = state.player.x - boss.x + spread * 120;
        const dy = state.player.y - boss.y;
        const len = Math.hypot(dx, dy) || 1;
        const spd = 300 * speedMult;
        spawnEnemyBullet(boss.x, boss.y, (dx / len) * spd, (dy / len) * spd, 5);
      }
      return;
    }

    if (state.phase === 2) {
      boss.shotCd = 0.1;
      boss.rot += 0.2;
      const count = 12;
      for (let i = 0; i < count; i += 1) {
        const a = boss.rot + ((Math.PI * 2) / count) * i;
        const spd = (180 + (i % 2) * 110) * speedMult;
        spawnEnemyBullet(boss.x, boss.y, Math.cos(a) * spd, Math.sin(a) * spd, 4 + (i % 3));
      }
      return;
    }

    boss.shotCd = 0.06;
    boss.rot += 0.3;
    const count = 22;
    for (let i = 0; i < count; i += 1) {
      const a = boss.rot + ((Math.PI * 2) / count) * i;
      const spiral = 220 + ((i * 7) % 60);
      const spd = spiral * speedMult;
      spawnEnemyBullet(boss.x, boss.y, Math.cos(a) * spd, Math.sin(a) * spd, 4);
    }
  }

  function transformAllBulletsToItems() {
    for (let i = 0; i < pools.enemyBullet.length; i += 1) {
      const b = pools.enemyBullet[i];
      if (!b.active) continue;
      spawnFromPool(pools.item, (it) => {
        it.x = b.x;
        it.y = b.y;
        it.vx = 0;
        it.vy = 60;
        it.kind = "score";
        it.attract = true;
      });
      release(b);
    }
  }

  function activateFormat() {
    if (state.grazeGauge < 100) return;

    state.grazeGauge = 0;
    state.format.activeUntil = state.time + 2;
    state.format.grazeLockUntil = Math.max(state.format.grazeLockUntil, state.format.activeUntil + 2);
    state.player.invUntil = Math.max(state.player.invUntil, state.format.activeUntil);
    transformAllBulletsToItems();

    for (let i = state.normalEnemies.length - 1; i >= 0; i -= 1) {
      const e = state.normalEnemies[i];
      spawnFromPool(pools.item, (it) => {
        it.x = e.x;
        it.y = e.y;
        it.vx = 0;
        it.vy = 80;
        it.kind = "power";
        it.attract = true;
      });
      state.normalEnemies.splice(i, 1);
    }

    if (state.boss) {
      applyBossDamage(500, "FORMAT");
    }

    addLog("FORMAT executed. Full purge stream active.");
  }

  function onPlayerHit() {
    if (state.time < state.player.invUntil) return;
    state.life = Math.max(0, state.life - 1);
    state.grazeGauge = 0;
    state.format.grazeLockUntil = Math.max(state.format.grazeLockUntil, state.time + 5);
    state.postDeathEaseUntil = state.time + 10;
    state.noHitTimer = 0;
    state.noHitMilestone = 0;
    state.waveSpeedBoost = false;
    state.player.x = FIELD_WIDTH * 0.5;
    state.player.y = FIELD_HEIGHT - 120;
    state.player.invUntil = state.time + 3;
    state.player.blinkTick = 0;
    addLog("Critical hit detected. Re-deploying...");
    if (state.life <= 0) {
      addLog("Rumi process terminated.");
      openResult(false);
    }
  }

  function phaseTransitionCheck(prevPhase, nextPhase) {
    if (prevPhase === nextPhase) return;
    state.phaseStartTime = state.time;
    state.phaseEnraged = false;
    addLog(`Phase ${nextPhase} engaged.`);
  }

  function applyBossDamage(amount, source) {
    if (!state.boss || amount <= 0) return;
    const beforeHp = state.boss.hp;
    const beforeSeg = Math.ceil((beforeHp / BOSS_MAX_HP) * BOSS_SEGMENTS);
    state.boss.hp = Math.max(0, state.boss.hp - amount);
    const afterSeg = Math.ceil((state.boss.hp / BOSS_MAX_HP) * BOSS_SEGMENTS);

    if (afterSeg < beforeSeg && state.boss.hp > 0) {
      transformAllBulletsToItems();
      state.boss.breakUntil = state.time + 0.7;
      addLog(`Boss guard cell broken by ${source}. Bullet score conversion.`);
    }

    if (state.boss.hp <= 0) {
      addScore(50000);
      addLog("System Overseer Alpha purged.");
      state.boss = null;
      openResult(true);
    }
  }

  function update(dt) {
    if (!state.gameStarted) return;

    if (state.paused) return;

    if (state.life <= 0) {
      return;
    }

    state.time += dt;
    state.noHitTimer += dt;
    while (state.noHitTimer >= 30) {
      state.noHitTimer -= 30;
      state.noHitMilestone += 1;
      if (state.noHitMilestone >= 2 && !state.waveSpeedBoost) {
        state.waveSpeedBoost = true;
        addLog("No-hit chain complete. Next waves get +10% bullet speed.");
      }
    }

    const p = state.player;

    const wasPhase = state.phase;

    const moveX = (isActionPressed("moveRight") ? 1 : 0) - (isActionPressed("moveLeft") ? 1 : 0);
    const moveY = (isActionPressed("moveDown") ? 1 : 0) - (isActionPressed("moveUp") ? 1 : 0);
    const len = Math.hypot(moveX, moveY) || 1;
    const focus = isActionPressed("focus");
    const speed = focus ? 150 : 400;
    p.x = clamp(p.x + (moveX / len) * speed * dt, 0, FIELD_WIDTH);
    p.y = clamp(p.y + (moveY / len) * speed * dt, 0, FIELD_HEIGHT);

    p.shootCd -= dt;
    if (isActionPressed("shoot") && p.shootCd <= 0) {
      p.shootCd = fireCooldownForLevel(powerLevel());
      firePattern();
    }

    if (isActionPressed("format")) {
      activateFormat();
    }

    state.enemySpawnCd -= dt;
    if (!state.boss && state.time < 195 && state.enemySpawnCd <= 0) {
      const profile = getStageProfile(state.time);
      let spawnInterval = profile.spawnInterval;
      if (state.time < state.postDeathEaseUntil) {
        spawnInterval += 0.3;
      }

      if (state.normalEnemies.length < profile.maxEnemies) {
        spawnEnemy();
      }

      state.enemySpawnCd = spawnInterval;
    }

    if (!state.boss && state.time >= 195) {
      spawnBoss();
    }

    for (let i = state.normalEnemies.length - 1; i >= 0; i -= 1) {
      const e = state.normalEnemies[i];
      e.y += e.speed * dt;
      e.shotCd -= dt;
      if (e.shotCd <= 0) {
        e.shotCd = 1.1;
        const ease = state.time < state.postDeathEaseUntil ? 0.85 : 1;
        enemyShootAtPlayer(e, (e.bulletSpeed + Math.random() * 30) * ease);
      }
      if (e.y > FIELD_HEIGHT + 50 || e.hp <= 0) {
        if (e.hp <= 0) {
          addScore(400);
          spawnFromPool(pools.item, (it) => {
            it.x = e.x;
            it.y = e.y;
            it.vx = 0;
            it.vy = 70;
            it.kind = Math.random() < e.dropRate && state.time < 195 ? "power" : "score";
            it.attract = false;
          });
        }
        state.normalEnemies.splice(i, 1);
      }
    }

    bossPattern(dt);
    phaseTransitionCheck(wasPhase, state.phase);

    for (let i = 0; i < pools.playerBullet.length; i += 1) {
      const b = pools.playerBullet[i];
      if (!b.active) continue;
      b.x += b.vx * dt;
      b.y += b.vy * dt;
      if (b.y < -20 || b.x < -30 || b.x > FIELD_WIDTH + 30) {
        release(b);
        continue;
      }

      let hit = false;
      for (let j = state.normalEnemies.length - 1; j >= 0; j -= 1) {
        const e = state.normalEnemies[j];
        if (distSq(b.x, b.y, e.x, e.y) <= (b.r + e.bodyR) ** 2) {
          e.hp -= b.damage;
          if (b.splash > 0) {
            for (let k = 0; k < state.normalEnemies.length; k += 1) {
              const t = state.normalEnemies[k];
              if (distSq(e.x, e.y, t.x, t.y) <= b.splash * b.splash) {
                t.hp -= 5;
              }
            }
          }
          hit = true;
          break;
        }
      }

      if (!hit && state.boss && distSq(b.x, b.y, state.boss.x, state.boss.y) <= (b.r + state.boss.bodyR) ** 2) {
        applyBossDamage(b.damage, "SHOT");
        hit = true;
      }

      if (hit) release(b);
    }

    for (let i = 0; i < pools.enemyBullet.length; i += 1) {
      const b = pools.enemyBullet[i];
      if (!b.active) continue;
      b.x += b.vx * dt;
      b.y += b.vy * dt;
      if (b.x < -40 || b.x > FIELD_WIDTH + 40 || b.y < -40 || b.y > FIELD_HEIGHT + 40) {
        release(b);
        continue;
      }

      const formatActive = state.time <= state.format.activeUntil;
      if (formatActive) {
        spawnFromPool(pools.item, (it) => {
          it.x = b.x;
          it.y = b.y;
          it.vx = 0;
          it.vy = 60;
          it.kind = "score";
          it.attract = true;
        });
        release(b);
        continue;
      }

      if (distSq(b.x, b.y, p.x, p.y) <= (b.r + p.hitRadius) ** 2) {
        release(b);
        onPlayerHit();
        continue;
      }

      const canGraze = state.time > p.invUntil && state.time > state.format.grazeLockUntil;
      if (canGraze && !b.grazed && distSq(b.x, b.y, p.x, p.y) <= (b.r + p.grazeRadius) ** 2) {
        b.grazed = true;
        state.grazeGauge = clamp(state.grazeGauge + 12, 0, 100);
        addScore(12);
      }
    }

    for (let i = 0; i < pools.item.length; i += 1) {
      const it = pools.item[i];
      if (!it.active) continue;

      const attract = it.attract || state.time <= state.format.activeUntil;
      if (attract) {
        const dx = p.x - it.x;
        const dy = p.y - it.y;
        const len2 = Math.hypot(dx, dy) || 1;
        const speed2 = 800;
        it.vx = (dx / len2) * speed2;
        it.vy = (dy / len2) * speed2;
      }

      it.x += it.vx * dt;
      it.y += it.vy * dt;

      if (distSq(it.x, it.y, p.x, p.y) <= 20 * 20) {
        if (it.kind === "power") {
          if (state.powerPoint >= 100) {
            addScore(10000);
          } else {
            state.powerPoint += 1;
          }
        } else {
          addScore(30);
        }
        release(it);
        continue;
      }

      if (it.y > FIELD_HEIGHT + 40 || it.x < -40 || it.x > FIELD_WIDTH + 40) {
        release(it);
      }
    }

    ui.highScore.textContent = String(state.bestScore);
    ui.score.textContent = String(state.score);
    ui.playTime.textContent = formatTime(state.time);
    ui.life.textContent = String(state.life);
    ui.power.textContent = String(powerLevel());
    ui.graze.textContent = `${Math.floor(state.grazeGauge)}%`;
    ui.bossHp.textContent = state.boss
      ? `${Math.max(0, Math.floor(state.boss.hp))} (${Math.ceil((state.boss.hp / BOSS_MAX_HP) * BOSS_SEGMENTS)}/${BOSS_SEGMENTS})`
      : "-";
  }

  function draw() {
    ctx.clearRect(0, 0, FIELD_WIDTH, FIELD_HEIGHT);

    const gridGap = 48;
    ctx.strokeStyle = "rgba(120,140,255,0.08)";
    ctx.lineWidth = 1;
    for (let x = 0; x < FIELD_WIDTH; x += gridGap) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, FIELD_HEIGHT);
      ctx.stroke();
    }
    for (let y = 0; y < FIELD_HEIGHT; y += gridGap) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(FIELD_WIDTH, y);
      ctx.stroke();
    }

    for (let i = 0; i < pools.item.length; i += 1) {
      const it = pools.item[i];
      if (!it.active) continue;
      ctx.fillStyle = it.kind === "power" ? COLORS.item : "#ffd778";
      ctx.beginPath();
      ctx.arc(it.x, it.y, 6, 0, Math.PI * 2);
      ctx.fill();
    }

    for (let i = 0; i < pools.playerBullet.length; i += 1) {
      const b = pools.playerBullet[i];
      if (!b.active) continue;
      ctx.fillStyle = "#6bfff6";
      ctx.beginPath();
      ctx.arc(b.x, b.y, b.r, 0, Math.PI * 2);
      ctx.fill();
    }

    for (let i = 0; i < pools.enemyBullet.length; i += 1) {
      const b = pools.enemyBullet[i];
      if (!b.active) continue;
      ctx.fillStyle = b.grazed ? "#bd79ff" : COLORS.enemyBullet;
      ctx.beginPath();
      ctx.arc(b.x, b.y, b.r, 0, Math.PI * 2);
      ctx.fill();
    }

    for (let i = 0; i < state.normalEnemies.length; i += 1) {
      const e = state.normalEnemies[i];
      ctx.fillStyle = COLORS.enemy;
      ctx.beginPath();
      ctx.rect(e.x - 14, e.y - 14, 28, 28);
      ctx.fill();

      const hpRatio = clamp(e.hp / 30, 0, 1);
      const barW = 34;
      const barX = e.x - barW / 2;
      const barY = e.y + 18;
      ctx.fillStyle = "rgba(255,255,255,0.14)";
      ctx.fillRect(barX, barY, barW, 4);
      ctx.fillStyle = "#7effa5";
      ctx.fillRect(barX, barY, barW * hpRatio, 4);
    }

    if (state.boss) {
      ctx.save();
      ctx.translate(state.boss.x, state.boss.y);
      ctx.rotate(state.time * 0.8);
      ctx.fillStyle = COLORS.boss;
      ctx.beginPath();
      ctx.moveTo(0, -70);
      ctx.lineTo(68, 12);
      ctx.lineTo(0, 70);
      ctx.lineTo(-68, 12);
      ctx.closePath();
      ctx.fill();
      ctx.restore();

      const barX = 140;
      const barY = 26;
      const barW = FIELD_WIDTH - 280;
      const barH = 18;
      const segGap = 4;
      const segW = (barW - segGap * (BOSS_SEGMENTS - 1)) / BOSS_SEGMENTS;
      const filledSeg = Math.ceil((state.boss.hp / BOSS_MAX_HP) * BOSS_SEGMENTS);
      ctx.fillStyle = "rgba(255,255,255,0.12)";
      ctx.fillRect(barX - 8, barY - 8, barW + 16, barH + 16);
      for (let i = 0; i < BOSS_SEGMENTS; i += 1) {
        const sx = barX + i * (segW + segGap);
        ctx.fillStyle = i < filledSeg ? "#ff5ec2" : "rgba(255,94,194,0.24)";
        ctx.fillRect(sx, barY, segW, barH);
      }
      ctx.fillStyle = "#f6f9ff";
      ctx.font = "600 16px Oxanium, sans-serif";
      ctx.fillText("SYSTEM OVERSEER HP", barX, barY - 10);
    }

    const p = state.player;
    const blinking = state.time < p.invUntil && Math.floor(state.time * 14) % 2 === 0;
    if (!blinking) {
      ctx.strokeStyle = COLORS.grazeRing;
      ctx.lineWidth = 1.2;
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.grazeRadius, 0, Math.PI * 2);
      ctx.stroke();

      ctx.fillStyle = COLORS.player;
      ctx.beginPath();
      ctx.moveTo(p.x, p.y - 16);
      ctx.lineTo(p.x + 12, p.y + 12);
      ctx.lineTo(p.x - 12, p.y + 12);
      ctx.closePath();
      ctx.fill();

      ctx.fillStyle = COLORS.hitCore;
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.hitRadius, 0, Math.PI * 2);
      ctx.fill();
    }

    const gx = p.x;
    const gy = p.y + 34;
    const gWidth = 78;
    ctx.strokeStyle = "rgba(45,211,255,0.6)";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(gx, gy, gWidth / 2, Math.PI, Math.PI * 2);
    ctx.stroke();

    ctx.strokeStyle = "#ffe26d";
    ctx.beginPath();
    ctx.arc(gx, gy, gWidth / 2, Math.PI, Math.PI + Math.PI * (state.grazeGauge / 100));
    ctx.stroke();

    if (state.phaseEnraged) {
      ctx.strokeStyle = "rgba(255,48,58,0.8)";
      ctx.lineWidth = 8;
      ctx.strokeRect(4, 4, FIELD_WIDTH - 8, FIELD_HEIGHT - 8);
    }

    if (state.paused) {
      ctx.fillStyle = "rgba(0,0,0,0.45)";
      ctx.fillRect(0, 0, FIELD_WIDTH, FIELD_HEIGHT);
      ctx.fillStyle = "#d8f2ff";
      ctx.font = "700 52px Orbitron, sans-serif";
      ctx.textAlign = "center";
      ctx.fillText("PAUSED", FIELD_WIDTH * 0.5, FIELD_HEIGHT * 0.5);
      ctx.textAlign = "start";
    }
  }

  let prev = performance.now();
  function loop(now) {
    const dt = Math.min((now - prev) / 1000, 0.033);
    prev = now;
    update(dt);
    draw();
    requestAnimationFrame(loop);
  }

  window.addEventListener("keydown", (e) => {
    if (state.waitingBindAction) {
      const usedAction = Object.keys(keyBindings).find((k) => keyBindings[k] === e.code && k !== state.waitingBindAction);
      if (usedAction) {
        ui.bindingHint.textContent = `Duplicate key. Already used by ${usedAction}.`;
      } else {
        keyBindings[state.waitingBindAction] = e.code;
        saveBindings();
        updateControlHints();
        ui.bindingHint.textContent = `${state.waitingBindAction} mapped to ${keyLabel(e.code)}.`;
        state.waitingBindAction = null;
      }
      e.preventDefault();
      return;
    }

    if (e.code === "Escape" && !e.repeat) {
      if (state.gameStarted && !state.gameOver && !state.paused && ui.settingsOverlay.classList.contains("hidden")) {
        showPauseMenu();
      } else if (!ui.settingsOverlay.classList.contains("hidden")) {
        closeSettings();
      }
      e.preventDefault();
      return;
    }
    keys.add(e.code);
  });

  window.addEventListener("keyup", (e) => {
    keys.delete(e.code);
  });

  document.querySelectorAll(".bind-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      state.waitingBindAction = btn.getAttribute("data-action");
      ui.bindingHint.textContent = `Press any key for ${state.waitingBindAction}.`;
    });
  });

  ui.resetBindingBtn.addEventListener("click", () => {
    keyBindings = { ...DEFAULT_BINDINGS };
    saveBindings();
    updateControlHints();
    ui.bindingHint.textContent = "Default key bindings restored.";
  });

  ui.applySettingsBtn.addEventListener("click", applySettings);
  ui.closeSettingsBtn.addEventListener("click", closeSettings);
  ui.retryBtn.addEventListener("click", () => startGame(true));
  ui.toTitleBtn.addEventListener("click", () => showTitleMenu());

  ui.bgmVolume.value = String(state.settings.bgm);
  ui.sfxVolume.value = String(state.settings.sfx);
  ui.voiceVolume.value = String(state.settings.voice);
  ui.displayMode.value = state.settings.displayMode;
  ui.displayScale.value = state.settings.displayScale;
  document.documentElement.style.setProperty("--battle-scale", state.settings.displayScale);

  updateControlHints();
  showTitleMenu();
  onScoreChanged();

  renderLogs();
  requestAnimationFrame(loop);
})();
