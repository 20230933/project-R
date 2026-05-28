extends Node2D

const WINDOW_SIZE := Vector2(1920, 1080)
const FIELD_RECT := Rect2(480, 0, 960, 1080)

const PLAYER_SPEED := 400.0
const PLAYER_FOCUS_SPEED := 150.0
const PLAYER_HIT_RADIUS := 2.0
const PLAYER_GRAZE_RADIUS := 20.0
const PLAYER_INVULN_TIME := 3.0

const GRAZE_CHARGE := 0.12
const FORMAT_DURATION := 2.0
const FORMAT_GRAZE_LOCK := 2.0
const HIT_GRAZE_LOCK := 5.0
const FORMAT_BOSS_DAMAGE := 500.0

const ENEMY_WAVE_TIME := 120.0
const BOSS_MAX_HP := 6000.0
const BOSS_SEGMENTS := 10
const BOSS_PHASE_TIME := 120.0

const WAVE_1_END := 40.0
const WAVE_2_END := 80.0
const WAVE_3_END := 120.0
const WAVE_1_COUNT := 6
const WAVE_2_COUNT := 6
const WAVE_3_COUNT := 8

const POOL_SIZE_PLAYER_BULLET := 500
const POOL_SIZE_ENEMY_BULLET := 3000
const POOL_SIZE_ITEM := 2000

const COLOR_FIELD := Color(0.02, 0.02, 0.03)
const COLOR_LINE := Color(0.18, 0.82, 1.0)
const COLOR_PLAYER := Color(0.36, 0.91, 1.0)
const COLOR_PLAYER_CORE := Color(1.0, 0.89, 0.43)
const COLOR_PLAYER_BULLET := Color(0.36, 0.91, 1.0)
const COLOR_ENEMY := Color(1.0, 0.3, 0.65)
const COLOR_ENEMY_BULLET := Color(1.0, 0.2, 0.63)
const COLOR_ITEM := Color(0.49, 1.0, 0.65)
const COLOR_BOSS := Color(0.95, 0.2, 0.2)

const BGM_PATH := "res://audio/bgm.ogg"
const DEFAULT_BGM_VOLUME := 0.7
const DEFAULT_SFX_VOLUME := 0.8

var rng := RandomNumberGenerator.new()

class GameState:
	var time := 0.0
	var score := 0
	var best_score := 0
	var life := 3
	var max_life := 5
	var power_point := 0
	var graze := 0.0
	var paused := true
	var game_started := false
	var game_over := false
	var game_cleared := false
	var has_progress := false
	var phase := 1
	var phase_start := 0.0
	var boss_start := 0.0
	var enemy_spawn_cd := 0.0
	var graze_lock_until := 0.0
	var format_until := 0.0
	var post_death_ease_until := 0.0
	var no_hit_timer := 0.0
	var wave_speed_boost := false
	var wave_phase := 1
	var wave_count := 0
	var bgm_volume := DEFAULT_BGM_VOLUME
	var sfx_volume := DEFAULT_SFX_VOLUME
	var fullscreen := false
	var settings_from := "title"

class Bullet:
	var active := false
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var r := 4.0
	var damage := 10.0
	var grazed := false

class Item:
	var active := false
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var r := 4.0
	var value := 1

class Enemy:
	var pos := Vector2.ZERO
	var hp := 40.0
	var speed := 80.0
	var shoot_cd := 1.0
	var shoot_interval := 1.0

class Boss:
	var pos := Vector2.ZERO
	var hp := BOSS_MAX_HP
	var max_hp := BOSS_MAX_HP
	var shoot_cd := 0.0
	var pattern_t := 0.0
	var segment := BOSS_SEGMENTS
	var phase := 1
	var phase_start := 0.0

var state := GameState.new()

class PlayerState:
	var pos := Vector2(FIELD_RECT.position.x + FIELD_RECT.size.x * 0.5, FIELD_RECT.size.y - 150)
	var shoot_cd := 0.0
	var inv_until := 0.0

var player := PlayerState.new()

var enemies: Array[Enemy] = []
var boss: Boss = null

var player_bullets: Array[Bullet] = []
var enemy_bullets: Array[Bullet] = []
var items: Array[Item] = []

var ui := {}
var bgm_player: AudioStreamPlayer = null

func _ready() -> void:
	rng.randomize()
	_ensure_input_actions()
	_load_save()
	_init_pools()
	_build_ui()
	_init_audio()
	_show_title_menu()
	set_process(true)

func _process(delta: float) -> void:
	if state.paused:
		return

	state.time += delta
	_update_player(delta)
	_update_player_shoot(delta)
	_update_enemies(delta)
	_update_boss(delta)
	_update_bullets(delta)
	_update_items(delta)
	_check_collisions()
	_update_ui()
	queue_redraw()

func _draw() -> void:
	draw_rect(FIELD_RECT, COLOR_FIELD)
	draw_rect(FIELD_RECT, COLOR_LINE, false, 2.0)

	for b in player_bullets:
		if b.active:
			draw_circle(b.pos, b.r, COLOR_PLAYER_BULLET)

	for b in enemy_bullets:
		if b.active:
			draw_circle(b.pos, b.r, COLOR_ENEMY_BULLET)

	for it in items:
		if it.active:
			draw_circle(it.pos, it.r, COLOR_ITEM)

	for e in enemies:
		draw_circle(e.pos, 18.0, COLOR_ENEMY)

	if boss != null:
		draw_circle(boss.pos, 40.0, COLOR_BOSS)

	var blink := int(Time.get_ticks_msec() / 120) % 2 == 0
	if player.inv_until <= state.time or blink:
		draw_circle(player.pos, PLAYER_GRAZE_RADIUS, Color(0.36, 0.91, 1.0, 0.12))
		draw_circle(player.pos, 10.0, COLOR_PLAYER)
		draw_circle(player.pos, PLAYER_HIT_RADIUS, COLOR_PLAYER_CORE)

func _init_pools() -> void:
	player_bullets = _make_bullet_pool(POOL_SIZE_PLAYER_BULLET, 4.0)
	enemy_bullets = _make_bullet_pool(POOL_SIZE_ENEMY_BULLET, 5.0)
	items = _make_item_pool(POOL_SIZE_ITEM)

func _make_bullet_pool(size: int, radius: float) -> Array[Bullet]:
	var arr: Array[Bullet] = []
	arr.resize(size)
	for i in range(size):
		var b := Bullet.new()
		b.r = radius
		arr[i] = b
	return arr

func _make_item_pool(size: int) -> Array[Item]:
	var arr: Array[Item] = []
	arr.resize(size)
	for i in range(size):
		arr[i] = Item.new()
	return arr

func _ensure_input_actions() -> void:
	_ensure_action("move_up", [Key.KEY_UP, Key.KEY_W])
	_ensure_action("move_down", [Key.KEY_DOWN, Key.KEY_S])
	_ensure_action("move_left", [Key.KEY_LEFT, Key.KEY_A])
	_ensure_action("move_right", [Key.KEY_RIGHT, Key.KEY_D])
	_ensure_action("shoot", [Key.KEY_Z])
	_ensure_action("format", [Key.KEY_X])
	_ensure_action("focus", [Key.KEY_SHIFT])
	_ensure_action("pause", [Key.KEY_ESCAPE])

func _ensure_action(action: String, keys: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.keycode = key
		InputMap.action_add_event(action, ev)

func _build_ui() -> void:
	var ui_layer := CanvasLayer.new()
	ui_layer.name = "UI"
	add_child(ui_layer)

	var hud := Control.new()
	hud.name = "Hud"
	hud.size = WINDOW_SIZE
	hud.anchor_right = 1.0
	hud.anchor_bottom = 1.0
	ui_layer.add_child(hud)

	var left_panel := ColorRect.new()
	left_panel.color = Color(0.02, 0.05, 0.09, 0.85)
	left_panel.size = Vector2(480, 1080)
	left_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(left_panel)


	var right_panel := ColorRect.new()
	right_panel.color = Color(0.02, 0.05, 0.09, 0.85)
	right_panel.size = Vector2(480, 1080)
	right_panel.position = Vector2(1440, 0)
	right_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(right_panel)

	var right_title := Label.new()
	right_title.text = "Mission Data"
	right_title.position = Vector2(24, 24)
	right_title.add_theme_font_size_override("font_size", 20)
	right_panel.add_child(right_title)

	var stats := VBoxContainer.new()
	stats.position = Vector2(24, 70)
	stats.size = Vector2(430, 800)
	stats.add_theme_constant_override("separation", 12)
	right_panel.add_child(stats)

	ui["high_score"] = _make_stat_row(stats, "HI-SCORE", "0")
	ui["score"] = _make_stat_row(stats, "SCORE", "0")
	ui["time"] = _make_stat_row(stats, "TIME", "00:00")
	ui["life"] = _make_stat_row(stats, "LIFE", "3")
	ui["power"] = _make_stat_row(stats, "PWR", "1")

	var boss_bar := ColorRect.new()
	boss_bar.color = Color(0.3, 0.05, 0.08, 0.9)
	boss_bar.size = Vector2(700, 16)
	boss_bar.position = Vector2((WINDOW_SIZE.x - 700) * 0.5, 16)
	boss_bar.visible = false
	boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(boss_bar)

	var boss_name := Label.new()
	boss_name.text = "BLACKOUT"
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name.size = Vector2(700, 18)
	boss_name.position = Vector2(boss_bar.position.x, boss_bar.position.y + 18)
	boss_name.visible = false
	hud.add_child(boss_name)

	var boss_fill := ColorRect.new()
	boss_fill.name = "BossFill"
	boss_fill.color = Color(0.85, 0.1, 0.2)
	boss_fill.size = Vector2(700, 16)
	boss_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_bar.add_child(boss_fill)

	for i in range(1, BOSS_SEGMENTS):
		var divider := ColorRect.new()
		divider.color = Color(0.05, 0.02, 0.02, 0.9)
		divider.size = Vector2(2, 16)
		divider.position = Vector2((boss_bar.size.x / float(BOSS_SEGMENTS)) * i - 1.0, 0)
		boss_bar.add_child(divider)

	ui["boss_bar"] = boss_bar
	ui["boss_fill"] = boss_fill
	ui["boss_name"] = boss_name

	var graze_bar := ColorRect.new()
	graze_bar.color = Color(0.0, 0.2, 0.25, 0.35)
	graze_bar.size = Vector2(120, 6)
	graze_bar.position = Vector2(FIELD_RECT.position.x + (FIELD_RECT.size.x - 240) * 0.5, 1040)
	graze_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(graze_bar)

	var graze_fill := ColorRect.new()
	graze_fill.name = "GrazeFill"
	graze_fill.color = Color(0.2, 0.85, 1.0)
	graze_fill.size = Vector2(0, 6)
	graze_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	graze_bar.add_child(graze_fill)

	ui["graze_bar"] = graze_bar
	ui["graze_fill"] = graze_fill

	ui["title_overlay"] = _make_overlay(ui_layer, "TITLE", [
		{"label": "Game Start", "action": "start"},
		{"label": "Continue", "action": "continue"},
		{"label": "Settings", "action": "settings"},
		{"label": "Exit", "action": "exit"}
	])

	ui["pause_overlay"] = _make_overlay(ui_layer, "PAUSED", [
		{"label": "Resume", "action": "resume"},
		{"label": "Restart", "action": "restart"},
		{"label": "Settings", "action": "settings"},
		{"label": "To Title", "action": "title"}
	])

	ui["result_overlay"] = _make_overlay(ui_layer, "RESULT", [
		{"label": "Retry", "action": "retry"},
		{"label": "To Title", "action": "title"}
	])

	ui["settings_overlay"] = _make_settings_overlay(ui_layer)


func _make_stat_row(parent: Control, label_text: String, value_text: String) -> Label:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(value)

	return value

func _make_overlay(parent: CanvasLayer, title: String, buttons: Array) -> Control:
	var overlay := Control.new()
	overlay.name = title + "Overlay"
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.size = WINDOW_SIZE
	overlay.visible = false
	parent.add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.04, 0.75)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)

	var panel := ColorRect.new()
	panel.color = Color(0.05, 0.08, 0.14, 0.95)
	panel.size = Vector2(520, 360)
	panel.position = Vector2((WINDOW_SIZE.x - panel.size.x) * 0.5, (WINDOW_SIZE.y - panel.size.y) * 0.5)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(panel)

	var title_label := Label.new()
	title_label.text = title
	title_label.position = Vector2(24, 18)
	title_label.add_theme_font_size_override("font_size", 24)
	panel.add_child(title_label)

	var list := VBoxContainer.new()
	list.position = Vector2(24, 72)
	list.size = Vector2(460, 260)
	list.add_theme_constant_override("separation", 12)
	panel.add_child(list)

	for b in buttons:
		var btn := Button.new()
		btn.text = b.label
		btn.name = b.action
		btn.pressed.connect(_on_menu_action.bind(b.action))
		list.add_child(btn)

	return overlay

func _on_menu_action(action: String) -> void:
	match action:
		"start":
			_start_game(true)
		"continue":
			_start_game(false)
		"settings":
			_open_settings()
		"exit":
			get_tree().quit()
		"resume":
			_resume_game()
		"restart":
			_start_game(true)
		"title":
			_show_title_menu()
		"retry":
			_start_game(true)

func _show_title_menu() -> void:
	state.paused = true
	state.settings_from = "title"
	ui["title_overlay"].visible = true
	ui["pause_overlay"].visible = false
	ui["result_overlay"].visible = false
	ui["settings_overlay"].visible = false
	_update_continue_button()

func _show_pause_menu() -> void:
	state.paused = true
	state.settings_from = "pause"
	ui["pause_overlay"].visible = true

func _show_result(clear: bool) -> void:
	state.paused = true
	state.game_over = true
	state.game_cleared = clear
	state.has_progress = false
	ui["result_overlay"].visible = true
	ui["pause_overlay"].visible = false
	ui["title_overlay"].visible = false
	ui["settings_overlay"].visible = false

func _update_continue_button() -> void:
	var overlay: Control = ui["title_overlay"]
	if overlay == null:
		return
	var btn := overlay.find_child("continue", true, false) as Button
	if btn != null:
		btn.disabled = not state.has_progress or state.game_over

func _start_game(full_reset: bool) -> void:
	if full_reset:
		_reset_state()
	state.paused = false
	state.game_started = true
	state.game_over = false
	state.game_cleared = false
	state.has_progress = true
	ui["title_overlay"].visible = false
	ui["pause_overlay"].visible = false
	ui["result_overlay"].visible = false
	_add_log("Mission started.")
	_ensure_bgm_playing()

func _resume_game() -> void:
	if not state.has_progress or state.game_over:
		return
	state.paused = false
	ui["pause_overlay"].visible = false
	ui["title_overlay"].visible = false
	_add_log("Simulation resumed.")
	_ensure_bgm_playing()

func _open_settings() -> void:
	state.paused = true
	ui["title_overlay"].visible = false
	ui["pause_overlay"].visible = false
	ui["result_overlay"].visible = false
	ui["settings_overlay"].visible = true
	_sync_settings_ui()

func _close_settings() -> void:
	ui["settings_overlay"].visible = false
	if state.settings_from == "pause":
		_show_pause_menu()
	else:
		_show_title_menu()

func _apply_settings() -> void:
	var bgm_slider: HSlider = ui["settings_bgm"]
	var sfx_slider: HSlider = ui["settings_sfx"]
	var display_mode: OptionButton = ui["settings_display"]
	state.bgm_volume = bgm_slider.value / 100.0
	state.sfx_volume = sfx_slider.value / 100.0
	state.fullscreen = display_mode.selected == 1
	_apply_audio_settings()
	_apply_display_settings()
	_close_settings()

func _sync_settings_ui() -> void:
	var bgm_slider: HSlider = ui["settings_bgm"]
	var sfx_slider: HSlider = ui["settings_sfx"]
	var display_mode: OptionButton = ui["settings_display"]
	bgm_slider.value = state.bgm_volume * 100.0
	sfx_slider.value = state.sfx_volume * 100.0
	display_mode.select(state.fullscreen ? 1 : 0)

func _make_settings_overlay(parent: CanvasLayer) -> Control:
	var overlay := Control.new()
	overlay.name = "SettingsOverlay"
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.size = WINDOW_SIZE
	overlay.visible = false
	parent.add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.04, 0.75)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)

	var panel := ColorRect.new()
	panel.color = Color(0.05, 0.08, 0.14, 0.95)
	panel.size = Vector2(620, 420)
	panel.position = Vector2((WINDOW_SIZE.x - panel.size.x) * 0.5, (WINDOW_SIZE.y - panel.size.y) * 0.5)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(panel)

	var title_label := Label.new()
	title_label.text = "SETTINGS"
	title_label.position = Vector2(24, 18)
	title_label.add_theme_font_size_override("font_size", 24)
	panel.add_child(title_label)

	var list := VBoxContainer.new()
	list.position = Vector2(24, 70)
	list.size = Vector2(560, 260)
	list.add_theme_constant_override("separation", 16)
	panel.add_child(list)

	var bgm_row := HBoxContainer.new()
	bgm_row.add_theme_constant_override("separation", 12)
	list.add_child(bgm_row)
	var bgm_label := Label.new()
	bgm_label.text = "BGM"
	bgm_label.custom_minimum_size = Vector2(120, 0)
	bgm_row.add_child(bgm_label)
	var bgm_slider := HSlider.new()
	bgm_slider.min_value = 0
	bgm_slider.max_value = 100
	bgm_slider.step = 1
	bgm_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bgm_row.add_child(bgm_slider)
	ui["settings_bgm"] = bgm_slider

	var sfx_row := HBoxContainer.new()
	sfx_row.add_theme_constant_override("separation", 12)
	list.add_child(sfx_row)
	var sfx_label := Label.new()
	sfx_label.text = "SFX"
	sfx_label.custom_minimum_size = Vector2(120, 0)
	sfx_row.add_child(sfx_label)
	var sfx_slider := HSlider.new()
	sfx_slider.min_value = 0
	sfx_slider.max_value = 100
	sfx_slider.step = 1
	sfx_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sfx_row.add_child(sfx_slider)
	ui["settings_sfx"] = sfx_slider

	var display_row := HBoxContainer.new()
	display_row.add_theme_constant_override("separation", 12)
	list.add_child(display_row)
	var display_label := Label.new()
	display_label.text = "DISPLAY"
	display_label.custom_minimum_size = Vector2(120, 0)
	display_row.add_child(display_label)
	var display_mode := OptionButton.new()
	display_mode.add_item("Windowed", 0)
	display_mode.add_item("Fullscreen", 1)
	display_mode.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	display_row.add_child(display_mode)
	ui["settings_display"] = display_mode

	var buttons := HBoxContainer.new()
	buttons.position = Vector2(24, 350)
	buttons.size = Vector2(560, 50)
	buttons.add_theme_constant_override("separation", 12)
	panel.add_child(buttons)

	var apply_btn := Button.new()
	apply_btn.text = "Apply"
	apply_btn.pressed.connect(_apply_settings)
	buttons.add_child(apply_btn)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.pressed.connect(_close_settings)
	buttons.add_child(back_btn)

	return overlay

func _init_audio() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGM"
	bgm_player.bus = "Master"
	add_child(bgm_player)
	var stream := load(BGM_PATH)
	if stream:
		bgm_player.stream = stream
		_apply_audio_settings()
		bgm_player.play()
	else:
		_add_log("BGM not found: " + BGM_PATH)

func _apply_audio_settings() -> void:
	if bgm_player == null:
		return
	bgm_player.volume_db = linear_to_db(max(state.bgm_volume, 0.001))

func _apply_display_settings() -> void:
	if state.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(int(WINDOW_SIZE.x), int(WINDOW_SIZE.y)))

func _ensure_bgm_playing() -> void:
	if bgm_player != null and bgm_player.stream != null and not bgm_player.playing:
		bgm_player.play()

func _reset_state() -> void:
	state.time = 0.0
	state.score = 0
	state.life = 3
	state.power_point = 0
	state.graze = 0.0
	state.phase = 1
	state.phase_start = 0.0
	state.boss_start = 0.0
	state.enemy_spawn_cd = 0.0
	state.graze_lock_until = 0.0
	state.format_until = 0.0
	state.post_death_ease_until = 0.0
	state.no_hit_timer = 0.0
	state.wave_speed_boost = false
	state.wave_phase = 1
	state.wave_count = 0

	player.pos = Vector2(FIELD_RECT.position.x + FIELD_RECT.size.x * 0.5, FIELD_RECT.size.y - 150)
	player.shoot_cd = 0.0
	player.inv_until = 0.0

	enemies.clear()
	boss = null
	_release_pool(player_bullets)
	_release_pool(enemy_bullets)
	_release_pool(items)

	if ui.has("log_box"):
		ui["log_box"].clear()
	_add_log("Boot sequence complete.")
	_add_log("Blackout core detected.")
	_add_log("Graze bullets to charge Format.")

func _release_pool(pool: Array) -> void:
	for item in pool:
		item.active = false

func _update_player(delta: float) -> void:
	var speed := PLAYER_SPEED
	if Input.is_action_pressed("focus"):
		speed = PLAYER_FOCUS_SPEED

	var dir: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		dir.y -= 1
	if Input.is_action_pressed("move_down"):
		dir.y += 1
	if Input.is_action_pressed("move_left"):
		dir.x -= 1
	if Input.is_action_pressed("move_right"):
		dir.x += 1

	if dir.length() > 0.0:
		dir = dir.normalized()
	player.pos += dir * speed * delta
	player.pos.x = clamp(player.pos.x, FIELD_RECT.position.x + 10, FIELD_RECT.position.x + FIELD_RECT.size.x - 10)
	player.pos.y = clamp(player.pos.y, FIELD_RECT.position.y + 10, FIELD_RECT.position.y + FIELD_RECT.size.y - 10)

	if Input.is_action_just_pressed("pause"):
		_show_pause_menu()

	if Input.is_action_just_pressed("format") and state.graze >= 1.0:
		_activate_format()

func _activate_format() -> void:
	state.graze = 0.0
	state.format_until = state.time + FORMAT_DURATION
	_apply_graze_lock(FORMAT_GRAZE_LOCK)
	_convert_bullets_to_items()
	if boss != null:
		boss.hp = max(boss.hp - FORMAT_BOSS_DAMAGE, 0.0)
		_check_boss_breaks()

func _update_player_shoot(delta: float) -> void:
	if not Input.is_action_pressed("shoot"):
		return

	var level := _power_level()
	var base_cd := 0.066
	if level >= 4:
		base_cd = 0.044
	if _format_active():
		base_cd /= 1.5

	player.shoot_cd -= delta
	if player.shoot_cd > 0.0:
		return

	player.shoot_cd = base_cd
	var spread: Array = _shot_angles(level)
	var damage: float = 10.0
	if level == 5:
		damage = 15.0
	if _format_active():
		damage *= 2.0

	for angle in spread:
		var dir: Vector2 = Vector2.UP.rotated(deg_to_rad(float(angle)))
		_spawn_player_bullet(player.pos + dir * 12.0, dir * 1000.0, damage)

func _shot_angles(level: int) -> Array:
	match level:
		1:
			return [0.0]
		2:
			return [-5.0, 5.0]
		3:
			return [-30.0, -5.0, 5.0, 30.0]
		4:
			return [-30.0, -5.0, 5.0, 30.0]
		5:
			return [-45.0, -15.0, 0.0, 15.0, 45.0]
		_:
			return [0.0]

func _spawn_player_bullet(pos: Vector2, vel: Vector2, damage: float) -> void:
	var b := _get_free(player_bullets) as Bullet
	if b == null:
		return
	b.active = true
	b.pos = pos
	b.vel = vel
	b.r = 4.0
	b.damage = damage

func _spawn_enemy_bullet(pos: Vector2, vel: Vector2, radius: float) -> void:
	var b := _get_free(enemy_bullets) as Bullet
	if b == null:
		return
	b.active = true
	b.pos = pos
	b.vel = vel
	b.r = radius
	b.grazed = false

func _spawn_item(pos: Vector2, value: int) -> void:
	var it := _get_free(items) as Item
	if it == null:
		return
	it.active = true
	it.pos = pos
	it.vel = Vector2(0, 60)
	it.r = 4.0
	it.value = value

func _get_free(pool: Array) -> Object:
	for item in pool:
		if not item.active:
			return item
	return null

func _update_bullets(delta: float) -> void:
	for b: Bullet in player_bullets:
		if not b.active:
			continue
		b.pos += b.vel * delta
		if not FIELD_RECT.has_point(b.pos):
			b.active = false

	for b: Bullet in enemy_bullets:
		if not b.active:
			continue
		b.pos += b.vel * delta
		if not FIELD_RECT.has_point(b.pos):
			b.active = false

func _update_items(delta: float) -> void:
	var attract: bool = _format_active()
	for it: Item in items:
		if not it.active:
			continue
		if attract:
			var dir: Vector2 = (player.pos - it.pos)
			var dist: float = max(dir.length(), 1.0)
			it.vel = dir / dist * 800.0
		it.pos += it.vel * delta
		if it.pos.y > FIELD_RECT.position.y + FIELD_RECT.size.y + 40:
			it.active = false

func _update_enemies(delta: float) -> void:
	if state.time >= ENEMY_WAVE_TIME and boss == null:
		_spawn_boss()

	if state.time < ENEMY_WAVE_TIME:
		var phase := _current_wave_phase(state.time)
		if phase != state.wave_phase:
			state.wave_phase = phase
			state.wave_count = 0
			state.enemy_spawn_cd = 0.3
		if phase > 0 and state.wave_count < _max_waves_for_phase(phase):
			state.enemy_spawn_cd -= delta
			if state.enemy_spawn_cd <= 0.0:
				state.enemy_spawn_cd = _current_wave_interval(state.time)
				_spawn_wave_pattern(phase, state.time, state.wave_count)
				state.wave_count += 1

	for e: Enemy in enemies:
		e.pos.y += e.speed * delta
		e.shoot_cd -= delta
		if e.shoot_cd <= 0.0:
			e.shoot_cd = e.shoot_interval
			var dir: Vector2 = (player.pos - e.pos).normalized()
			_spawn_enemy_bullet(e.pos, dir * 220.0, 6.0)

	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i].pos.y > FIELD_RECT.position.y + FIELD_RECT.size.y + 40:
			enemies.remove_at(i)

func _spawn_enemy_at(pos: Vector2, speed: float, shoot_interval: float) -> void:
	var e := Enemy.new()
	e.pos = pos
	e.hp = 40.0
	e.speed = speed
	e.shoot_interval = shoot_interval
	e.shoot_cd = shoot_interval
	enemies.append(e)

func _current_wave_interval(time_sec: float) -> float:
	if time_sec < WAVE_1_END:
		return 1.4
	if time_sec < WAVE_2_END:
		return 1.1
	return 0.9

func _current_wave_phase(time_sec: float) -> int:
	if time_sec < WAVE_1_END:
		return 1
	if time_sec < WAVE_2_END:
		return 2
	if time_sec < WAVE_3_END:
		return 3
	return 0

func _max_waves_for_phase(phase: int) -> int:
	match phase:
		1:
			return WAVE_1_COUNT
		2:
			return WAVE_2_COUNT
		3:
			return WAVE_3_COUNT
		_:
			return 0

func _spawn_wave_pattern(phase: int, time_sec: float, wave_index: int) -> void:
	var center_x := FIELD_RECT.position.x + FIELD_RECT.size.x * 0.5
	var spawn_y := -30.0
	if phase == 1:
		match wave_index % 3:
			0:
				var xs := [center_x - 160.0, center_x, center_x + 160.0]
				for x in xs:
					_spawn_enemy_at(Vector2(x, spawn_y), 70.0, 1.1)
			1:
				var xs := [center_x - 220.0, center_x - 80.0, center_x + 80.0, center_x + 220.0]
				for x in xs:
					_spawn_enemy_at(Vector2(x, spawn_y), 65.0, 1.2)
			2:
				_spawn_enemy_at(Vector2(center_x, spawn_y), 80.0, 0.9)
		return
	if phase == 2:
		match wave_index % 2:
			0:
				var left_x := FIELD_RECT.position.x + 120.0
				var right_x := FIELD_RECT.position.x + FIELD_RECT.size.x - 120.0
				_spawn_enemy_at(Vector2(left_x, spawn_y), 85.0, 0.9)
				_spawn_enemy_at(Vector2(right_x, spawn_y), 85.0, 0.9)
			1:
				var mid_left := center_x - 120.0
				var mid_right := center_x + 120.0
				_spawn_enemy_at(Vector2(mid_left, spawn_y), 90.0, 0.8)
				_spawn_enemy_at(Vector2(mid_right, spawn_y), 90.0, 0.8)
		return
	if phase != 3:
		return
	var wave_t := time_sec * 1.2
	if wave_index % 2 == 0:
		var offset := sin(wave_t) * 220.0
		var offset2 := sin(wave_t + 1.2) * 220.0
		var offset3 := sin(wave_t + 2.4) * 220.0
		_spawn_enemy_at(Vector2(center_x + offset, spawn_y), 95.0, 0.8)
		_spawn_enemy_at(Vector2(center_x + offset2, spawn_y), 95.0, 0.8)
		_spawn_enemy_at(Vector2(center_x + offset3, spawn_y), 95.0, 0.8)
	else:
		_spawn_enemy_at(Vector2(center_x - 200.0, spawn_y), 100.0, 0.7)
		_spawn_enemy_at(Vector2(center_x, spawn_y), 100.0, 0.7)
		_spawn_enemy_at(Vector2(center_x + 200.0, spawn_y), 100.0, 0.7)

func _spawn_boss() -> void:
	enemies.clear()
	var b := Boss.new()
	b.pos = Vector2(FIELD_RECT.position.x + FIELD_RECT.size.x * 0.5, 180)
	b.hp = BOSS_MAX_HP
	b.max_hp = BOSS_MAX_HP
	b.shoot_cd = 0.0
	b.pattern_t = 0.0
	b.segment = BOSS_SEGMENTS
	b.phase = 1
	b.phase_start = state.time
	boss = b
	state.phase = 1
	state.phase_start = state.time
	_add_log("Boss detected: Blackout.")

func _update_boss(delta: float) -> void:
	if boss == null:
		return

	boss.pattern_t += delta
	boss.pos.x = FIELD_RECT.position.x + FIELD_RECT.size.x * 0.5 + sin(boss.pattern_t * 0.7) * 120.0

	_update_boss_phase()

	var speed_mul: float = 1.0
	if state.time - state.phase_start > BOSS_PHASE_TIME:
		speed_mul = 1.5

	boss.shoot_cd -= delta
	if boss.shoot_cd > 0.0:
		return

	match boss.phase:
		1:
			boss.shoot_cd = 0.35
			var dir: Vector2 = (player.pos - boss.pos).normalized()
			for angle in [-12.0, 0.0, 12.0]:
				_spawn_enemy_bullet(boss.pos, dir.rotated(deg_to_rad(angle)) * 240.0 * speed_mul, 6.0)
		2:
			boss.shoot_cd = 0.2
			var count: int = 14
			for i in range(count):
				var angle: float = boss.pattern_t * 1.8 + (TAU / count) * i
				var dir: Vector2 = Vector2(cos(angle), sin(angle))
				_spawn_enemy_bullet(boss.pos, dir * 220.0 * speed_mul, 5.0)
		3:
			boss.shoot_cd = 0.18
			var base: float = (player.pos - boss.pos).angle()
			for angle in [-20.0, -8.0, 0.0, 8.0, 20.0]:
				var dir3 := Vector2.RIGHT.rotated(base + deg_to_rad(angle))
				_spawn_enemy_bullet(boss.pos, dir3 * 260.0 * speed_mul, 6.0)
			var ring: int = 10
			for i in range(ring):
				var ang: float = boss.pattern_t * 2.0 + (TAU / ring) * i
				var dir_ring: Vector2 = Vector2(cos(ang), sin(ang))
				_spawn_enemy_bullet(boss.pos, dir_ring * 200.0 * speed_mul, 4.0)

func _update_boss_phase() -> void:
	if boss == null:
		return

	var segment_value: float = boss.max_hp / float(BOSS_SEGMENTS)
	var new_segment: int = int(ceil(boss.hp / segment_value))
	if new_segment < boss.segment:
		boss.segment = new_segment
		_on_boss_break()

	if boss.segment <= 7 and boss.phase == 1:
		boss.phase = 2
		state.phase = 2
		state.phase_start = state.time
	if boss.segment <= 3 and boss.phase == 2:
		boss.phase = 3
		state.phase = 3
		state.phase_start = state.time

	if boss.hp <= 0.0:
		_on_boss_defeated()

func _on_boss_break() -> void:
	_convert_bullets_to_items()
	_add_score(5000)

func _check_boss_breaks() -> void:
	_update_boss_phase()

func _on_boss_defeated() -> void:
	boss = null
	_add_score(50000)
	_show_result(true)

func _convert_bullets_to_items() -> void:
	for b: Bullet in enemy_bullets:
		if b.active:
			b.active = false
			_spawn_item(b.pos, 1)

func _check_collisions() -> void:
	var hit_allowed: bool = player.inv_until <= state.time

	for b: Bullet in enemy_bullets:
		if not b.active:
			continue
		var dist: float = player.pos.distance_to(b.pos)
		if hit_allowed and dist <= PLAYER_HIT_RADIUS + b.r:
			_on_player_hit()
			b.active = false
			continue

		if dist <= PLAYER_GRAZE_RADIUS + b.r and not b.grazed:
			if state.time >= state.graze_lock_until:
				state.graze = min(state.graze + GRAZE_CHARGE, 1.0)
			b.grazed = true

	for it: Item in items:
		if not it.active:
			continue
		if player.pos.distance_to(it.pos) <= PLAYER_GRAZE_RADIUS:
			it.active = false
			state.power_point += it.value
			_add_score(200)

	for b: Bullet in player_bullets:
		if not b.active:
			continue

		var hit: bool = false
		for e: Enemy in enemies:
			if b.pos.distance_to(e.pos) <= 18.0 + b.r:
				e.hp -= b.damage
				hit = true
				break

		if hit:
			b.active = false

	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i].hp <= 0.0:
			_spawn_item(enemies[i].pos, 2)
			_add_score(800)
			enemies.remove_at(i)

	if boss != null:
		for b: Bullet in player_bullets:
			if not b.active:
				continue
			if b.pos.distance_to(boss.pos) <= 40.0 + b.r:
				boss.hp = max(boss.hp - b.damage, 0.0)
				b.active = false
				_check_boss_breaks()

func _on_player_hit() -> void:
	state.life -= 1
	state.graze = 0.0
	_apply_graze_lock(HIT_GRAZE_LOCK)
	player.inv_until = state.time + PLAYER_INVULN_TIME
	player.pos = Vector2(FIELD_RECT.position.x + FIELD_RECT.size.x * 0.5, FIELD_RECT.size.y - 150)
	_add_log("System damaged. Life -1.")

	if state.life <= 0:
		_show_result(false)

func _apply_graze_lock(duration: float) -> void:
	state.graze_lock_until = max(state.graze_lock_until, state.time + duration)

func _format_active() -> bool:
	return state.time <= state.format_until

func _power_level() -> int:
	if state.power_point >= 100:
		return 5
	if state.power_point >= 60:
		return 4
	if state.power_point >= 30:
		return 3
	if state.power_point >= 10:
		return 2
	return 1

func _update_ui() -> void:
	var boss_fill: ColorRect = ui["boss_fill"]
	var boss_bar: ColorRect = ui["boss_bar"]
	var boss_name: Label = ui["boss_name"]
	var graze_fill: ColorRect = ui["graze_fill"]
	var graze_bar: ColorRect = ui["graze_bar"]

	ui["score"].text = str(state.score)
	ui["high_score"].text = str(state.best_score)
	ui["time"].text = _format_time(state.time)
	ui["life"].text = str(state.life)
	ui["power"].text = str(_power_level())

	if boss == null:
		boss_bar.visible = false
		boss_name.visible = false
		boss_fill.size.x = 0
	else:
		boss_bar.visible = true
		boss_name.visible = true
		var ratio: float = boss.hp / boss.max_hp
		boss_fill.size.x = boss_bar.size.x * ratio

	graze_fill.size.x = graze_bar.size.x * state.graze
	var bar_pos := Vector2(player.pos.x - graze_bar.size.x * 0.5, player.pos.y + 26.0)
	bar_pos.x = clamp(bar_pos.x, FIELD_RECT.position.x, FIELD_RECT.position.x + FIELD_RECT.size.x - graze_bar.size.x)
	bar_pos.y = clamp(bar_pos.y, FIELD_RECT.position.y + 12.0, FIELD_RECT.position.y + FIELD_RECT.size.y - 20.0)
	graze_bar.position = bar_pos

func _format_time(seconds: float) -> String:
	var s: int = max(0, int(seconds))
	var mm: String = String.num_int64(s / 60).pad_zeros(2)
	var ss: String = String.num_int64(s % 60).pad_zeros(2)
	return mm + ":" + ss

func _add_score(amount: int) -> void:
	state.score += amount
	if state.score > state.best_score:
		state.best_score = state.score
		_save_score()

func _add_log(text: String) -> void:
	if ui.has("log_box"):
		ui["log_box"].append_text(text + "\n")

func _load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://save.cfg") == OK:
		state.best_score = int(cfg.get_value("score", "best", 0))

func _save_score() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best", state.best_score)
	cfg.save("user://save.cfg")
