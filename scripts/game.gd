extends Node2D

const WINDOW_SIZE := Vector2(1920, 1080)
const FIELD_RECT := Rect2(480, 0, 960, 1080)

const PLAYER_SPEED := 400.0
const PLAYER_FOCUS_SPEED := 150.0
const PLAYER_HIT_RADIUS := 1.5
const PLAYER_GRAZE_RADIUS := 46.0
const PLAYER_INVULN_TIME := 3.0

const GRAZE_CHARGE := 0.22
const FORMAT_DURATION := 2.0
const FORMAT_GRAZE_LOCK := 2.0
const HIT_GRAZE_LOCK := 5.0
const FORMAT_BOSS_DAMAGE := 500.0

const ENEMY_WAVE_TIME := 90.0
const BOSS_MAX_HP := 22000.0
const BOSS_SEGMENTS := 10
const BOSS_PHASE_TIME := 120.0

const BOSS_ADD_SPAWN_INTERVAL := 2.4
const BOSS_LAST_SEGMENT := 1
const BOSS_BULLET_HOMING := 0.06

const TEX_BG := "res://배경.png"
const TEX_TITLE_SCREEN := "res://타이틀 화면.png"
const TEX_CONTROLS := "res://조작키.png"
const TEX_ENEMY_SPRITE := "res://잡몹.png"
const TEX_RESULT_FAIL := "res://게임 실패.png"
const TEX_RESULT_SUCCESS := "res://게임 성공.png"

const TEX_LUMI_UI_NORMAL := "res://루미 기본.png"
const TEX_LUMI_UI_HURT := "res://루미 다침.png"
const TEX_LUMI_UI_CHARGE := "res://루미 차징.png"

const PLAYER_SHOT_SFX_CANDIDATES := [
	"res://공격 효과음.mp3",
	"res://공격효과음.mp3",
]
const PLAYER_SHOT_SFX_MIN_INTERVAL := 0.12

const ENEMY_POST_FIRE_HANG := 0.65
const HP_SCORE_INITIAL := 2500
const HP_SCORE_STEP_BASE := 1500
const HP_SCORE_MULT := 1.6

const ENEMY_PATTERN_ADD_AIMED := 0
const ENEMY_PATTERN_ADD_FAN := 1
const ENEMY_PATTERN_ADD_RING := 2
const ENEMY_PATTERN_AIMED := 10
const ENEMY_PATTERN_FAN := 11
const ENEMY_PATTERN_RING := 12
const ENEMY_PATTERN_SPIRAL := 13
const ENEMY_PATTERN_CROSS := 14

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

const BGM_PATH := "res://base bgm.mp3"
const BOSS_BGM_PATH := "res://boss bgm.wav"
const DEFAULT_BGM_VOLUME := 0.7
const DEFAULT_SFX_VOLUME := 0.8

const TEX_LUMI_IDLE_SHEET := "res://lumi_idle_sheet.png"
const TEX_BOSS_IDLE_SHEET := "res://boss_idle_sheet.png"
const TEX_BOSS_STUN_SHEET := "res://boss_stun_sheet.png"
const TEX_BOSS_DEATH_SHEET := "res://boss_death_sheet.png"

const TEX_BULLET_PLAYER := "res://플레이어 공격.png"
const TEX_BULLET_ENEMY := "res://잡몹 공격.png"
const TEX_BULLET_BOSS := "res://보스 공격.png"

const TEX_UI_BLUE := "res://UI_blue.png"
const TEX_UI_RED := "res://UI_red.png"
const TEX_ICON_HP_ON := "res://hp_on.png"
const TEX_ICON_HP_OFF := "res://hp_off.png"
const TEX_ICON_LV_ON := "res://lv_on.png"
const TEX_ICON_LV_OFF := "res://lv_off.png"

const PLAYER_DRAW_HEIGHT := 140.0
const BOSS_DRAW_HEIGHT := 320.0
const PLAYER_BULLET_SIZE_MUL := 4.5
const ENEMY_BULLET_SIZE_MUL := 3.0
const BOSS_BULLET_SIZE_MUL := 3.0
const BULLET_ROT_OFFSET_PLAYER := PI * 0.5
const BULLET_ROT_OFFSET_ENEMY := PI * 0.5
const BULLET_ROT_OFFSET_BOSS := PI * 0.5
const BOSS_STUN_TIME := 0.8

const PLAYER_MUZZLE_OFFSET := 26.0
const PLAYER_STREAM_SPACING := 12.0
const ENEMY_MUZZLE_OFFSET := 18.0
const BOSS_MUZZLE_OFFSET := 34.0

const FORMAT_FLASH_DURATION := 0.18
const FORMAT_FLASH_ALPHA := 0.35

const HUD_PANEL_SIZE := Vector2(430, 150)
const HUD_PANEL_X := 24.0
const HUD_PANEL_Y := 40.0
const HUD_PANEL_GAP := 34.0
const HUD_TITLE_FS := 22
const HUD_VALUE_FS := 38
const HUD_ICON_SIZE := 44.0

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
	var format_flash_until := 0.0
	var hp_score_next := 0
	var hp_score_step := 0
	var item_attract_until := 0.0

class Bullet:
	var active := false
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var r := 4.0
	var damage := 10.0
	var grazed := false
	var source := 0

class Item:
	var active := false
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var r := 4.0
	var value := 1

class Enemy:
	var pos := Vector2.ZERO
	var hp := 40.0
	var shoot_cd := 1.0
	var shoot_interval := 1.0
	var state := 0 # 0 enter, 1 attack, 2 exit
	var t := 0.0
	var target := Vector2.ZERO
	var exit_vel := Vector2.ZERO
	var enter_speed := 260.0
	var attack_time := 2.4
	var pattern := 0
	var fired := false
	var repeat_left := 0
	var repeat_cd := 0.0
	var repeat_interval := 1.0
	var spiral_angle := 0.0
	var fixed_dir := Vector2.DOWN

class Boss:
	var pos := Vector2.ZERO
	var hp := BOSS_MAX_HP
	var max_hp := BOSS_MAX_HP
	var shoot_cd := 0.0
	var pattern_t := 0.0
	var segment := BOSS_SEGMENTS
	var phase := 1
	var phase_start := 0.0
	var mix_cd := 1.5

var state := GameState.new()

class PlayerState:
	var pos := Vector2(FIELD_RECT.position.x + FIELD_RECT.size.x * 0.5, FIELD_RECT.size.y - 150)
	var shoot_cd := 0.0
	var inv_until := 0.0
	var shot_sfx_last_t := -999.0

var player := PlayerState.new()

var enemies: Array[Enemy] = []
var boss: Boss = null

var player_bullets: Array[Bullet] = []
var enemy_bullets: Array[Bullet] = []
var items: Array[Item] = []

var ui := {}
var bgm_player: AudioStreamPlayer = null
var sfx_shot_player: AudioStreamPlayer = null

var ui_life_icons: Array[TextureRect] = []
var ui_power_icons: Array[TextureRect] = []

enum BulletSource { ENEMY, BOSS }
enum Facing { DOWN, UP, LEFT, RIGHT }

var tex_lumi_sheet: Texture2D = null
var tex_boss_idle_sheet: Texture2D = null
var tex_boss_stun_sheet: Texture2D = null
var tex_boss_death_sheet: Texture2D = null

var tex_bullet_player: Texture2D = null
var tex_bullet_enemy: Texture2D = null
var tex_bullet_boss: Texture2D = null

var tex_ui_blue: Texture2D = null
var tex_ui_red: Texture2D = null
var tex_hp_on: Texture2D = null
var tex_hp_off: Texture2D = null
var tex_lv_on: Texture2D = null
var tex_lv_off: Texture2D = null
var tex_bg: Texture2D = null
var tex_title_screen: Texture2D = null
var tex_controls: Texture2D = null
var tex_enemy: Texture2D = null

var tex_result_fail: Texture2D = null
var tex_result_success: Texture2D = null

var tex_lumi_ui_normal: Texture2D = null
var tex_lumi_ui_hurt: Texture2D = null
var tex_lumi_ui_charge: Texture2D = null

var player_frames: Array[Texture2D] = []
var boss_idle_frames: Array[Texture2D] = []
var boss_stun_frames: Array[Texture2D] = []
var boss_death_frames: Array[Texture2D] = []

var player_facing := Facing.DOWN
var player_anim_t := 0.0

var boss_anim := "idle" # idle | stun | death
var boss_anim_t := 0.0
var boss_stun_until := 0.0
var boss_death_playing := false

func _ready() -> void:
	rng.randomize()
	# Prevent atlas bleeding (sheet neighbors showing)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	_ensure_input_actions()
	_load_save()
	_init_pools()
	_load_textures()
	_build_ui()
	_init_audio()
	_show_title_menu()
	queue_redraw()
	set_process(true)

func _process(delta: float) -> void:
	# Even while paused (title/result/settings), keep drawing the background/UI.
	if state.paused:
		queue_redraw()
		return

	player_anim_t += delta

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
	# Title screen background
	if ui.has("title_overlay") and ui["title_overlay"].visible and tex_title_screen != null:
		_draw_tex_cover(tex_title_screen, WINDOW_SIZE * 0.5, WINDOW_SIZE)
		return

	if tex_bg != null:
		var center := FIELD_RECT.position + FIELD_RECT.size * 0.5
		_draw_tex_cover(tex_bg, center, FIELD_RECT.size)
	else:
		draw_rect(FIELD_RECT, COLOR_FIELD)
	draw_rect(FIELD_RECT, COLOR_LINE, false, 2.0)

	for b in player_bullets:
		if b.active:
			_draw_bullet(tex_bullet_player, b.pos, b.vel, b.r, PLAYER_BULLET_SIZE_MUL, BULLET_ROT_OFFSET_PLAYER)

	for b in enemy_bullets:
		if b.active:
			var tex: Texture2D = tex_bullet_enemy
			var mul: float = ENEMY_BULLET_SIZE_MUL
			var rot_off: float = BULLET_ROT_OFFSET_ENEMY
			if b.source == BulletSource.BOSS:
				tex = tex_bullet_boss
				mul = BOSS_BULLET_SIZE_MUL
				rot_off = BULLET_ROT_OFFSET_BOSS
			_draw_bullet(tex, b.pos, b.vel, b.r, mul, rot_off)

	for it in items:
		if it.active:
			draw_circle(it.pos, it.r, COLOR_ITEM)

	for e in enemies:
		if tex_enemy != null:
			_draw_tex_centered(tex_enemy, e.pos, 90.0)
		else:
			draw_circle(e.pos, 18.0, COLOR_ENEMY)

	if boss != null:
		_draw_boss_sprite()

	var blink := int(Time.get_ticks_msec() / 120) % 2 == 0
	if player.inv_until <= state.time or blink:
		_draw_player_sprite()
		draw_circle(player.pos, PLAYER_GRAZE_RADIUS, Color(0.36, 0.91, 1.0, 0.12))
		draw_circle(player.pos, PLAYER_HIT_RADIUS, COLOR_PLAYER_CORE)

	# Format flash (purification effect)
	if state.time < state.format_flash_until:
		var t := (state.format_flash_until - state.time) / FORMAT_FLASH_DURATION
		var a: float = clampf(t, 0.0, 1.0) * FORMAT_FLASH_ALPHA
		draw_rect(Rect2(Vector2.ZERO, WINDOW_SIZE), Color(1, 1, 1, a), true)

func _load_textures() -> void:
	tex_lumi_sheet = load(TEX_LUMI_IDLE_SHEET) as Texture2D
	tex_boss_idle_sheet = load(TEX_BOSS_IDLE_SHEET) as Texture2D
	tex_boss_stun_sheet = load(TEX_BOSS_STUN_SHEET) as Texture2D
	tex_boss_death_sheet = load(TEX_BOSS_DEATH_SHEET) as Texture2D

	tex_bullet_player = load(TEX_BULLET_PLAYER) as Texture2D
	tex_bullet_enemy = load(TEX_BULLET_ENEMY) as Texture2D
	tex_bullet_boss = load(TEX_BULLET_BOSS) as Texture2D

	tex_ui_blue = load(TEX_UI_BLUE) as Texture2D
	tex_ui_red = load(TEX_UI_RED) as Texture2D
	tex_hp_on = load(TEX_ICON_HP_ON) as Texture2D
	tex_hp_off = load(TEX_ICON_HP_OFF) as Texture2D
	tex_lv_on = load(TEX_ICON_LV_ON) as Texture2D
	tex_lv_off = load(TEX_ICON_LV_OFF) as Texture2D
	tex_bg = load(TEX_BG) as Texture2D
	tex_title_screen = load(TEX_TITLE_SCREEN) as Texture2D
	tex_controls = load(TEX_CONTROLS) as Texture2D
	tex_enemy = load(TEX_ENEMY_SPRITE) as Texture2D
	tex_result_fail = load(TEX_RESULT_FAIL) as Texture2D
	tex_result_success = load(TEX_RESULT_SUCCESS) as Texture2D
	tex_lumi_ui_normal = load(TEX_LUMI_UI_NORMAL) as Texture2D
	tex_lumi_ui_hurt = load(TEX_LUMI_UI_HURT) as Texture2D
	tex_lumi_ui_charge = load(TEX_LUMI_UI_CHARGE) as Texture2D

	player_frames = _split_sheet_columns(tex_lumi_sheet, 5)
	boss_idle_frames = _split_sheet_columns(tex_boss_idle_sheet, 5)
	boss_stun_frames = _split_sheet_columns(tex_boss_stun_sheet, 2)
	boss_death_frames = _split_sheet_columns(tex_boss_death_sheet, 4)

func _split_sheet_columns(sheet: Texture2D, columns: int) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	if sheet == null or columns <= 0:
		return frames
	var sz: Vector2i = sheet.get_size()
	if sz.x <= 0 or sz.y <= 0:
		return frames
	var w: int = int(sz.x / columns)
	var h: int = int(sz.y)
	for i in range(columns):
		var at := AtlasTexture.new()
		at.atlas = sheet
		at.region = Rect2(i * w, 0, w, h)
		at.filter_clip = true
		frames.append(at)
	return frames

func _draw_tex_centered(tex: Texture2D, pos: Vector2, desired_height: float) -> void:
	if tex == null:
		return
	var sz: Vector2 = Vector2(tex.get_size())
	if sz.y <= 0:
		return
	var scale := desired_height / float(sz.y)
	draw_set_transform(pos, 0.0, Vector2(scale, scale))
	draw_texture(tex, -sz * 0.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_tex_cover(tex: Texture2D, pos: Vector2, desired_size: Vector2) -> void:
	if tex == null:
		return
	var sz: Vector2 = Vector2(tex.get_size())
	if sz.x <= 0.0 or sz.y <= 0.0:
		return
	var scale_x := desired_size.x / sz.x
	var scale_y := desired_size.y / sz.y
	var scale := maxf(scale_x, scale_y)
	draw_set_transform(pos, 0.0, Vector2(scale, scale))
	draw_texture(tex, -sz * 0.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_tex_rotated(tex: Texture2D, pos: Vector2, angle: float, desired_size: float) -> void:
	if tex == null:
		return
	var sz: Vector2 = Vector2(tex.get_size())
	var base: float = maxf(1.0, maxf(sz.x, sz.y))
	var scale: float = desired_size / base
	draw_set_transform(pos, angle, Vector2(scale, scale))
	draw_texture(tex, -sz * 0.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _player_frame() -> Texture2D:
	if player_frames.is_empty():
		return null
	match player_facing:
		Facing.UP:
			return player_frames[min(1, player_frames.size() - 1)]
		Facing.RIGHT:
			return player_frames[min(3, player_frames.size() - 1)]
		Facing.LEFT:
			return player_frames[min(4, player_frames.size() - 1)]
		_:
			# DOWN: subtle 2-frame loop (0 <-> 2) when available
			if player_frames.size() >= 3:
				var idx := int(floor(player_anim_t * 4.0)) % 2
				return player_frames[0] if idx == 0 else player_frames[2]
			return player_frames[0]

func _draw_player_sprite() -> void:
	var f := _player_frame()
	if f == null:
		# Fallback
		draw_circle(player.pos, 10.0, COLOR_PLAYER)
		return
	_draw_tex_centered(f, player.pos, PLAYER_DRAW_HEIGHT)

func _boss_frame() -> Texture2D:
	match boss_anim:
		"stun":
			if boss_stun_frames.is_empty():
				return null
			var idx_s := int(floor(boss_anim_t * 8.0)) % boss_stun_frames.size()
			return boss_stun_frames[idx_s]
		"death":
			if boss_death_frames.is_empty():
				return null
			var idx_d := int(floor(boss_anim_t * 7.0))
			idx_d = clamp(idx_d, 0, boss_death_frames.size() - 1)
			return boss_death_frames[idx_d]
		_:
			if boss_idle_frames.is_empty():
				return null
			var idx := int(floor(boss_anim_t * 6.0)) % boss_idle_frames.size()
			return boss_idle_frames[idx]

func _draw_boss_sprite() -> void:
	if boss == null:
		return
	var f := _boss_frame()
	if f == null:
		draw_circle(boss.pos, 40.0, COLOR_BOSS)
		return
	_draw_tex_centered(f, boss.pos, BOSS_DRAW_HEIGHT)

func _draw_bullet(tex: Texture2D, pos: Vector2, vel: Vector2, r: float, size_mul: float, angle_offset: float) -> void:
	if tex == null:
		draw_circle(pos, r, Color.WHITE)
		return
	var angle: float = vel.angle() + angle_offset
	_draw_tex_rotated(tex, pos, angle, r * size_mul * 2.0)

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
	ui["hud_root"] = hud

	var left_panel := ColorRect.new()
	left_panel.color = Color(0.02, 0.05, 0.09, 1.0)
	left_panel.size = Vector2(480, 1080)
	left_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(left_panel)

	# Lumi portrait (left UI) - clipped to a square frame
	var portrait_frame := Control.new()
	portrait_frame.name = "LumiPortraitFrame"
	portrait_frame.position = Vector2(24, 24)
	portrait_frame.size = Vector2(432, 432)
	portrait_frame.clip_contents = true
	portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_panel.add_child(portrait_frame)

	var portrait := TextureRect.new()
	portrait.name = "LumiPortrait"
	portrait.texture = tex_lumi_ui_normal
	portrait.anchor_right = 1.0
	portrait.anchor_bottom = 1.0
	portrait.size = portrait_frame.size
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_frame.add_child(portrait)
	ui["lumi_portrait"] = portrait


	var right_panel := ColorRect.new()
	right_panel.color = Color(0.02, 0.05, 0.09, 1.0)
	right_panel.size = Vector2(480, 1080)
	right_panel.position = Vector2(1440, 0)
	right_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(right_panel)

	var stats := VBoxContainer.new()
	stats.position = Vector2(HUD_PANEL_X, HUD_PANEL_Y)
	stats.size = Vector2(430, 900)
	stats.add_theme_constant_override("separation", int(HUD_PANEL_GAP))
	right_panel.add_child(stats)

	ui["high_score"] = _make_value_panel(stats, tex_ui_red, "최고 점수", "0", COLOR_ENEMY_BULLET)
	ui["score"] = _make_value_panel(stats, tex_ui_red, "점수", "0", COLOR_ENEMY_BULLET)
	ui["time"] = _make_value_panel(stats, tex_ui_blue, "시간", "00:00.00", COLOR_LINE)
	_make_life_panel(stats)
	_make_power_panel(stats)

	# Compatibility placeholders (avoid null lookups in older code paths)
	ui["life"] = Label.new()
	ui["power"] = Label.new()

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

	ui["title_overlay"] = _make_title_overlay(ui_layer)

	ui["pause_overlay"] = _make_overlay(ui_layer, "PAUSED", [
		{"label": "Resume", "action": "resume"},
		{"label": "Restart", "action": "restart"},
		{"label": "Settings", "action": "settings"},
		{"label": "To Title", "action": "title"}
	])

	ui["result_overlay"] = _make_result_overlay(ui_layer)

	ui["settings_overlay"] = _make_settings_overlay(ui_layer)
	ui["controls_overlay"] = _make_controls_overlay(ui_layer)


func _make_value_panel(parent: Control, bg_tex: Texture2D, title_text: String, value_text: String, title_color: Color) -> Label:
	var panel := Control.new()
	panel.custom_minimum_size = HUD_PANEL_SIZE
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var bg := TextureRect.new()
	bg.texture = bg_tex
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)

	var title := Label.new()
	title.text = title_text
	title.position = Vector2(34, 24)
	title.add_theme_font_size_override("font_size", HUD_TITLE_FS)
	title.add_theme_color_override("font_color", title_color)
	panel.add_child(title)

	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.size = Vector2(HUD_PANEL_SIZE.x, 70)
	value.position = Vector2(0, 66)
	value.add_theme_font_size_override("font_size", HUD_VALUE_FS)
	panel.add_child(value)

	return value


func _make_life_panel(parent: Control) -> void:
	ui_life_icons.clear()
	var panel := Control.new()
	panel.custom_minimum_size = HUD_PANEL_SIZE
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var bg := TextureRect.new()
	bg.texture = tex_ui_red
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)

	var title := Label.new()
	title.text = "잔기"
	title.position = Vector2(34, 24)
	title.add_theme_font_size_override("font_size", HUD_TITLE_FS)
	title.add_theme_color_override("font_color", COLOR_ENEMY_BULLET)
	panel.add_child(title)

	var icons := HBoxContainer.new()
	icons.position = Vector2(34, 76)
	icons.size = Vector2(HUD_PANEL_SIZE.x - 68.0, 60)
	icons.add_theme_constant_override("separation", 12)
	panel.add_child(icons)

	for i in range(state.max_life):
		var icon := TextureRect.new()
		icon.texture = tex_hp_off
		icon.custom_minimum_size = Vector2(HUD_ICON_SIZE, HUD_ICON_SIZE)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icons.add_child(icon)
		ui_life_icons.append(icon)


func _make_power_panel(parent: Control) -> void:
	ui_power_icons.clear()
	var panel := Control.new()
	panel.custom_minimum_size = Vector2(HUD_PANEL_SIZE.x, 170)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var bg := TextureRect.new()
	bg.texture = tex_ui_blue
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)

	var title := Label.new()
	title.text = "파워 레벨"
	title.position = Vector2(34, 24)
	title.add_theme_font_size_override("font_size", HUD_TITLE_FS)
	title.add_theme_color_override("font_color", COLOR_LINE)
	panel.add_child(title)

	var icons := HBoxContainer.new()
	icons.position = Vector2(34, 86)
	icons.size = Vector2(HUD_PANEL_SIZE.x - 68.0, 70)
	icons.add_theme_constant_override("separation", 10)
	panel.add_child(icons)

	var display_max := 5
	for i in range(display_max):
		var icon := TextureRect.new()
		icon.texture = tex_lv_off
		icon.custom_minimum_size = Vector2(HUD_ICON_SIZE, HUD_ICON_SIZE)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icons.add_child(icon)
		ui_power_icons.append(icon)


func _make_stat_row(parent: Control, label_text: String, value_text: String, icon_key: String = "", icon_initial: Texture2D = null) -> Label:
	var row := Control.new()
	row.custom_minimum_size = Vector2(430, 64)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)

	var bg := TextureRect.new()
	bg.texture = tex_ui_blue
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(bg)

	var content := HBoxContainer.new()
	content.anchor_right = 1.0
	content.anchor_bottom = 1.0
	content.position = Vector2(20, 14)
	content.size = Vector2(390, 36)
	content.add_theme_constant_override("separation", 12)
	row.add_child(content)

	if icon_key != "":
		var icon := TextureRect.new()
		icon.texture = icon_initial
		icon.custom_minimum_size = Vector2(28, 28)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(icon)
		ui[icon_key] = icon

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 18)
	content.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.add_theme_font_size_override("font_size", 18)
	content.add_child(value)

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
		var label_text := ""
		var action := ""
		if b is Dictionary:
			label_text = str((b as Dictionary).get("label", ""))
			action = str((b as Dictionary).get("action", ""))
		else:
			# Fallback
			label_text = str(b)
			action = ""

		var btn := Button.new()
		btn.text = label_text
		btn.name = action
		btn.pressed.connect(_on_menu_action.bind(action))
		list.add_child(btn)

	# Special-case: result overlay gets an info label for score/time/messages
	if title == "RESULT":
		var info := Label.new()
		info.name = "ResultInfo"
		info.position = Vector2(34, 52)
		info.size = Vector2(460, 80)
		info.add_theme_font_size_override("font_size", 18)
		info.autowrap_mode = TextServer.AUTOWRAP_WORD
		panel.add_child(info)
		ui["result_text"] = info

	return overlay

func _make_title_overlay(parent: CanvasLayer) -> Control:
	# Example-style title: full-screen background + left-side text menu (no dim/panel)
	var overlay := Control.new()
	overlay.name = "TITLEOverlay"
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.size = WINDOW_SIZE
	overlay.visible = false
	parent.add_child(overlay)

	var menu := VBoxContainer.new()
	menu.name = "TitleMenu"
	# Match the example: move slightly to the right.
	menu.position = Vector2(150, 560)
	menu.size = Vector2(520, 360)
	menu.add_theme_constant_override("separation", 22)
	overlay.add_child(menu)

	var entries := [
		{"label": "게임 시작", "action": "start"},
		{"label": "이어하기", "action": "continue"},
		{"label": "조작법", "action": "controls"},
		{"label": "설정", "action": "settings"},
		{"label": "게임 종료", "action": "exit"}
	]

	for e in entries:
		var btn := Button.new()
		btn.text = str(e.get("label", ""))
		btn.name = str(e.get("action", ""))
		btn.flat = true
		btn.focus_mode = Control.FOCUS_ALL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 44)
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
		btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 0.88))
		btn.pressed.connect(_on_menu_action.bind(btn.name))
		menu.add_child(btn)

	return overlay

func _on_menu_action(action: String) -> void:
	match action:
		"start":
			_start_game(true)
		"continue":
			_start_game(false)
		"controls":
			_open_controls()
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
	# Title screen must be silent (no music yet)
	_stop_bgm()
	if ui.has("hud_root"):
		(ui["hud_root"] as Control).visible = false
	ui["title_overlay"].visible = true
	ui["pause_overlay"].visible = false
	ui["result_overlay"].visible = false
	ui["settings_overlay"].visible = false
	ui["controls_overlay"].visible = false
	_update_continue_button()
	queue_redraw()

func _show_pause_menu() -> void:
	state.paused = true
	state.settings_from = "pause"
	ui["pause_overlay"].visible = true

func _show_result(clear: bool) -> void:
	state.paused = true
	state.game_over = true
	state.game_cleared = clear
	state.has_progress = false
	if bgm_player != null and bgm_player.playing:
		bgm_player.stop()
	_stop_bgm()
	# Hide gameplay HUD; show the example-style result overlay.
	if ui.has("hud_root"):
		(ui["hud_root"] as Control).visible = false

	if ui.has("result_bg"):
		var bg: TextureRect = ui["result_bg"]
		bg.texture = tex_result_success if clear else tex_result_fail
	if ui.has("result_best"):
		(ui["result_best"] as Label).text = _format_int_with_commas(state.best_score)
	if ui.has("result_score"):
		(ui["result_score"] as Label).text = _format_int_with_commas(state.score)
	if ui.has("result_time"):
		(ui["result_time"] as Label).text = _format_time(state.time)
	ui["result_overlay"].visible = true
	ui["pause_overlay"].visible = false
	ui["title_overlay"].visible = false
	ui["settings_overlay"].visible = false
	queue_redraw()
	queue_redraw()

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
	ui["settings_overlay"].visible = false
	ui["controls_overlay"].visible = false
	if ui.has("hud_root"):
		(ui["hud_root"] as Control).visible = true
	_add_log("Mission started.")
	# Gameplay must always use base BGM
	_switch_bgm(BGM_PATH, true)
	_ensure_bgm_playing()
	queue_redraw()

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
	# Show only the settings box on top of the current screen (do not hide underlying overlays)
	ui["settings_overlay"].visible = true
	_sync_settings_ui()
	queue_redraw()

func _close_settings() -> void:
	ui["settings_overlay"].visible = false
	if state.settings_from == "pause":
		_show_pause_menu()
	else:
		_show_title_menu()

func _open_controls() -> void:
	state.paused = true
	ui["title_overlay"].visible = false
	ui["pause_overlay"].visible = false
	ui["result_overlay"].visible = false
	ui["settings_overlay"].visible = false
	ui["controls_overlay"].visible = true
	queue_redraw()

func _close_controls() -> void:
	ui["controls_overlay"].visible = false
	_show_title_menu()

func _apply_settings() -> void:
	var bgm_slider: HSlider = ui["settings_bgm"]
	var sfx_slider: HSlider = ui["settings_sfx"]
	var display_mode: OptionButton = ui["settings_display"]
	state.bgm_volume = bgm_slider.value / 100.0
	state.sfx_volume = sfx_slider.value / 100.0
	state.fullscreen = display_mode.get_selected_id() == 1
	_apply_audio_settings()
	_apply_display_settings()
	_close_settings()

func _unhandled_input(event: InputEvent) -> void:
	# ESC closes controls overlay
	if ui.has("controls_overlay") and ui["controls_overlay"].visible:
		if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == Key.KEY_ESCAPE:
			_close_controls()
			return

func _sync_settings_ui() -> void:
	var bgm_slider: HSlider = ui["settings_bgm"]
	var sfx_slider: HSlider = ui["settings_sfx"]
	var display_mode: OptionButton = ui["settings_display"]
	bgm_slider.value = state.bgm_volume * 100.0
	sfx_slider.value = state.sfx_volume * 100.0
	display_mode.select(1 if state.fullscreen else 0)

func _make_settings_overlay(parent: CanvasLayer) -> Control:
	var overlay := Control.new()
	overlay.name = "SettingsOverlay"
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.size = WINDOW_SIZE
	overlay.visible = false
	parent.add_child(overlay)

	# No dim: keep current screen visible, show only the settings box.
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.0)
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

func _make_controls_overlay(parent: CanvasLayer) -> Control:
	var overlay := Control.new()
	overlay.name = "ControlsOverlay"
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.size = WINDOW_SIZE
	overlay.visible = false
	parent.add_child(overlay)

	# Fullscreen controls image
	var img := TextureRect.new()
	img.name = "ControlsImage"
	img.texture = tex_controls
	img.anchor_right = 1.0
	img.anchor_bottom = 1.0
	img.size = WINDOW_SIZE
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(img)

	# Exit button (bottom-left)
	var exit_btn := Button.new()
	exit_btn.name = "ControlsExit"
	exit_btn.text = "나가기"
	exit_btn.position = Vector2(36, WINDOW_SIZE.y - 92)
	exit_btn.size = Vector2(180, 56)
	exit_btn.pressed.connect(_close_controls)
	overlay.add_child(exit_btn)

	return overlay

func _make_result_overlay(parent: CanvasLayer) -> Control:
	# Example-style result screen: fullscreen image + values + two buttons
	var overlay := Control.new()
	overlay.name = "RESULTOverlay"
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.size = WINDOW_SIZE
	overlay.visible = false
	parent.add_child(overlay)

	var bg := TextureRect.new()
	bg.name = "ResultBG"
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.size = WINDOW_SIZE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(bg)
	ui["result_bg"] = bg

	# Values are right-aligned over the image's value slots
	var best := Label.new()
	best.name = "BestScore"
	best.text = "0"
	best.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	best.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	best.position = Vector2(1080, 575)
	best.size = Vector2(720, 60)
	best.add_theme_font_size_override("font_size", 44)
	overlay.add_child(best)
	ui["result_best"] = best

	var score := Label.new()
	score.name = "RunScore"
	score.text = "0"
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score.position = Vector2(1080, 695)
	score.size = Vector2(720, 60)
	score.add_theme_font_size_override("font_size", 44)
	overlay.add_child(score)
	ui["result_score"] = score

	var time := Label.new()
	time.name = "RunTime"
	time.text = "00:00.00"
	time.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time.position = Vector2(1080, 815)
	time.size = Vector2(720, 60)
	time.add_theme_font_size_override("font_size", 44)
	overlay.add_child(time)
	ui["result_time"] = time

	# Buttons
	var retry := Button.new()
	retry.name = "retry"
	retry.text = "다시하기"
	retry.position = Vector2(340, 930)
	retry.size = Vector2(520, 90)
	retry.flat = true
	retry.pressed.connect(_on_menu_action.bind("retry"))
	overlay.add_child(retry)

	var to_title := Button.new()
	to_title.name = "title"
	to_title.text = "타이틀로 이동"
	to_title.position = Vector2(1060, 930)
	to_title.size = Vector2(520, 90)
	to_title.flat = true
	to_title.pressed.connect(_on_menu_action.bind("title"))
	overlay.add_child(to_title)

	return overlay

func _init_audio() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGM"
	bgm_player.bus = "Master"
	add_child(bgm_player)

	sfx_shot_player = AudioStreamPlayer.new()
	sfx_shot_player.name = "SFX_Shot"
	sfx_shot_player.bus = "Master"
	add_child(sfx_shot_player)
	var shot_stream: AudioStream = null
	var chosen_path := ""
	for p in PLAYER_SHOT_SFX_CANDIDATES:
		var s := load(p)
		if s != null:
			shot_stream = s as AudioStream
			chosen_path = p
			break
	if shot_stream == null:
		_add_log("SFX not found: player shot (tried candidates)")
	else:
		sfx_shot_player.stream = shot_stream
		_add_log("SFX loaded: " + chosen_path)

	# Do not start any BGM here; title screen must be silent.

func _switch_bgm(path: String, restart: bool) -> void:
	if bgm_player == null:
		return
	if path == "":
		_stop_bgm()
		return
	var stream := load(path)
	if stream == null:
		_add_log("BGM not found: " + path)
		return
	var should_restart := restart
	if bgm_player.stream == stream:
		should_restart = false
	bgm_player.stream = stream
	_apply_audio_settings()
	if should_restart:
		bgm_player.play()

func _stop_bgm() -> void:
	if bgm_player == null:
		return
	if bgm_player.playing:
		bgm_player.stop()
	bgm_player.stream = null

func _apply_audio_settings() -> void:
	if bgm_player != null:
		bgm_player.volume_db = linear_to_db(max(state.bgm_volume, 0.001))
	if sfx_shot_player != null:
		sfx_shot_player.volume_db = linear_to_db(max(state.sfx_volume, 0.001))

func _apply_display_settings() -> void:
	var window_id := 0
	if state.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN, window_id)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, window_id)
		DisplayServer.window_set_size(Vector2i(int(WINDOW_SIZE.x), int(WINDOW_SIZE.y)), window_id)

func _ensure_bgm_playing() -> void:
	if bgm_player != null and bgm_player.stream != null and not bgm_player.playing:
		bgm_player.play()

func _reset_state() -> void:
	# Reset to base BGM for a new run.
	_switch_bgm(BGM_PATH, false)
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
	state.format_flash_until = 0.0
	state.hp_score_next = 0
	state.hp_score_step = 0

	player.pos = Vector2(FIELD_RECT.position.x + FIELD_RECT.size.x * 0.5, FIELD_RECT.size.y - 150)
	player.shoot_cd = 0.0
	player.inv_until = 0.0

	enemies.clear()
	boss = null
	boss_anim = "idle"
	boss_anim_t = 0.0
	boss_stun_until = 0.0
	boss_death_playing = false
	player_facing = Facing.DOWN
	player_anim_t = 0.0
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
		# Update facing from last movement input
		if abs(dir.x) > abs(dir.y):
			player_facing = Facing.RIGHT if dir.x > 0.0 else Facing.LEFT
		else:
			player_facing = Facing.DOWN if dir.y > 0.0 else Facing.UP
	else:
		# When idle, always revert to default facing.
		player_facing = Facing.DOWN
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
	state.format_flash_until = state.time + FORMAT_FLASH_DURATION
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
	_play_player_shot_sfx()
	var spread: Array = _shot_angles(level)
	var damage: float = 7.0
	if level >= 4:
		damage = 8.0
	if level == 5:
		damage = 11.0
	if _format_active():
		damage *= 2.0

	var count := spread.size()
	var center := float(count - 1) * 0.5
	for i in range(count):
		var angle := float(spread[i])
		var dir: Vector2 = Vector2.UP.rotated(deg_to_rad(angle)).normalized()
		var perp := Vector2(-dir.y, dir.x)
		var lateral := (float(i) - center) * PLAYER_STREAM_SPACING
		var start_pos := player.pos + dir * PLAYER_MUZZLE_OFFSET + perp * lateral
		_spawn_player_bullet(start_pos, dir * 1000.0, damage)

func _play_player_shot_sfx() -> void:
	if sfx_shot_player == null or sfx_shot_player.stream == null:
		return
	# One player for SFX to prevent overlap; throttle so rapid-fire doesn't constantly restart the sound.
	if state.time - player.shot_sfx_last_t < PLAYER_SHOT_SFX_MIN_INTERVAL:
		return
	player.shot_sfx_last_t = state.time
	sfx_shot_player.play()

func _shot_angles(level: int) -> Array:
	match level:
		1:
			return [0.0]
		2:
			# Two straight shots (same direction), spaced laterally.
			return [0.0, 0.0]
		3:
			# Straight + slight curves left/right.
			return [-12.0, 0.0, 12.0]
		4:
			# Two center shots straight, plus two outer angles.
			# outer-left, two centers, outer-right so centers sit in the middle
			return [-12.0, 0.0, 0.0, 12.0]
		5:
			# Same pattern as level 4, but stronger damage.
			return [-12.0, 0.0, 0.0, 12.0]
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
	b.source = BulletSource.ENEMY

func _spawn_boss_bullet(pos: Vector2, vel: Vector2, radius: float) -> void:
	var b := _get_free(enemy_bullets) as Bullet
	if b == null:
		return
	b.active = true
	b.pos = pos
	b.vel = vel
	b.r = radius
	b.grazed = false
	b.source = BulletSource.BOSS

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
	# Items are always auto-attracted (base behavior)
	var attract: bool = true
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

	# Continuous spawns from start until boss defeat (result screen pauses processing).
	# Do not spawn during boss death animation.
	if not boss_death_playing:
		state.enemy_spawn_cd -= delta
		if state.enemy_spawn_cd <= 0.0:
			var boss_mode := boss != null
			state.enemy_spawn_cd = _enemy_spawn_interval(boss_mode)
			if boss_mode:
				_spawn_attack_enemy(true)
				if rng.randf() < 0.35:
					_spawn_attack_enemy(true)
			else:
				_spawn_preboss_pattern(state.time)

	if state.time < ENEMY_WAVE_TIME:
		var phase := _current_wave_phase(state.time)
		if phase != state.wave_phase:
			state.wave_phase = phase

	for e: Enemy in enemies:
		e.t += delta
		match e.state:
			0:
				var d0 := e.target - e.pos
				var dist0: float = d0.length()
				if dist0 <= 8.0 or e.t > 2.0:
					e.state = 1
					e.t = 0.0
					e.fired = false
					e.shoot_cd = rng.randf_range(0.08, 0.18)
					e.repeat_cd = 0.0
				else:
					e.pos += (d0 / max(dist0, 1.0)) * e.enter_speed * delta
			1:
				if not e.fired:
					e.shoot_cd -= delta
					if e.shoot_cd <= 0.0:
						e.fired = true
						e.t = 0.0
				else:
					e.repeat_cd -= delta
					if e.repeat_left > 0 and e.repeat_cd <= 0.0:
						_enemy_fire(e)
						e.repeat_left -= 1
						e.repeat_cd = e.repeat_interval
					if e.repeat_left <= 0 and e.t >= e.attack_time:
						e.state = 2
			2:
				e.pos += e.exit_vel * delta

	for i in range(enemies.size() - 1, -1, -1):
		var p := enemies[i].pos
		if p.y < -120 or p.y > WINDOW_SIZE.y + 120 or p.x < FIELD_RECT.position.x - 220 or p.x > FIELD_RECT.position.x + FIELD_RECT.size.x + 220:
			enemies.remove_at(i)

func _enemy_spawn_interval(boss_mode: bool) -> float:
	if boss_mode:
		return BOSS_ADD_SPAWN_INTERVAL
	if state.time < 60.0:
		return 1.2
	if state.time < 75.0:
		return 1.0
	return 0.9

func _spawn_attack_enemy(is_boss_add: bool) -> void:
	var e := Enemy.new()
	e.hp = 34.0 if is_boss_add else 26.0
	e.state = 0
	e.t = 0.0
	e.fired = false
	e.enter_speed = 320.0 if is_boss_add else 260.0
	e.attack_time = 3.0 if is_boss_add else 2.4

	# Spawn from left/right/front, then retreat.
	var mode := rng.randi_range(0, 2)
	if mode == 0:
		# Front in
		var x := rng.randf_range(FIELD_RECT.position.x + 120.0, FIELD_RECT.position.x + FIELD_RECT.size.x - 120.0)
		e.pos = Vector2(x, -60.0)
		e.target = Vector2(x, rng.randf_range(140.0, 260.0))
		e.exit_vel = Vector2(0, -240.0)
	elif mode == 1:
		# Left side
		var y := rng.randf_range(140.0, 420.0)
		e.pos = Vector2(FIELD_RECT.position.x - 120.0, y)
		e.target = Vector2(FIELD_RECT.position.x + 90.0, y)
		e.exit_vel = Vector2(-250.0, -30.0)
	else:
		# Right side
		var y2 := rng.randf_range(140.0, 420.0)
		e.pos = Vector2(FIELD_RECT.position.x + FIELD_RECT.size.x + 120.0, y2)
		e.target = Vector2(FIELD_RECT.position.x + FIELD_RECT.size.x - 90.0, y2)
		e.exit_vel = Vector2(250.0, -30.0)

	e.pattern = rng.randi_range(0, 2)
	match e.pattern:
		0:
			e.pattern = ENEMY_PATTERN_ADD_AIMED
			_set_enemy_repeat(e, 1, 1.0, ENEMY_POST_FIRE_HANG)
		1:
			e.pattern = ENEMY_PATTERN_ADD_FAN
			_set_enemy_repeat(e, 1, 1.0, ENEMY_POST_FIRE_HANG)
		2:
			e.pattern = ENEMY_PATTERN_ADD_RING
			_set_enemy_repeat(e, 1, 1.0, ENEMY_POST_FIRE_HANG)
	enemies.append(e)

func _spawn_enemy_at(pos: Vector2, speed: float, shoot_interval: float) -> void:
	# Legacy helper used by _spawn_wave_pattern().
	# Spawns an enemy that moves into position, fires briefly, then retreats.
	var e := Enemy.new()
	e.hp = 26.0
	e.state = 0
	e.t = 0.0
	e.pos = pos
	e.fired = false
	# Map old downward speed values into enter speed.
	e.enter_speed = max(220.0, speed * 3.0)
	e.attack_time = 2.2
	e.shoot_interval = shoot_interval
	e.shoot_cd = shoot_interval
	e.pattern = ENEMY_PATTERN_AIMED
	_set_enemy_repeat(e, 1, 1.0, ENEMY_POST_FIRE_HANG)

	var tx: float = clampf(pos.x, FIELD_RECT.position.x + 90.0, FIELD_RECT.position.x + FIELD_RECT.size.x - 90.0)
	var ty := rng.randf_range(140.0, 260.0)
	e.target = Vector2(tx, ty)
	e.exit_vel = Vector2(0, -240.0)
	enemies.append(e)

func _set_enemy_repeat(e: Enemy, shots: int, interval: float, hang: float) -> void:
	e.repeat_left = shots
	e.repeat_interval = interval
	e.repeat_cd = 0.0
	e.attack_time = float(shots) * interval + hang

func _spawn_preboss_pattern(time_sec: float) -> void:
	state.wave_count += 1
	var r := rng.randf()
	if time_sec < 60.0:
		if r < 0.65:
			_spawn_pattern_aimed()
		else:
			_spawn_pattern_fan()
		if rng.randf() < 0.25:
			_spawn_preboss_extra(time_sec)
		return
	if time_sec < 75.0:
		if r < 0.45:
			_spawn_pattern_aimed()
		elif r < 0.75:
			_spawn_pattern_ring()
		else:
			_spawn_pattern_cross()
		if rng.randf() < 0.3:
			_spawn_preboss_extra(time_sec)
		return
	# 75~90s: push spiral + cross, with a little aimed for rhythm.
	if r < 0.45:
		_spawn_pattern_spiral()
	elif r < 0.8:
		_spawn_pattern_cross()
	else:
		_spawn_pattern_aimed()
	if rng.randf() < 0.35:
		_spawn_preboss_extra(time_sec)

func _spawn_preboss_extra(time_sec: float) -> void:
	var r := rng.randf()
	if time_sec < 60.0:
		if r < 0.6:
			_spawn_pattern_aimed()
		else:
			_spawn_pattern_fan()
		return
	if time_sec < 75.0:
		if r < 0.4:
			_spawn_pattern_ring()
		else:
			_spawn_pattern_aimed()
		return
	if r < 0.5:
		_spawn_pattern_spiral()
	else:
		_spawn_pattern_cross()

func _spawn_pattern_aimed() -> void:
	var e := _spawn_pattern_base(Vector2(rng.randf_range(FIELD_RECT.position.x + 120.0, FIELD_RECT.position.x + FIELD_RECT.size.x - 120.0), -60.0))
	e.pattern = ENEMY_PATTERN_AIMED
	_set_enemy_repeat(e, 1, 1.0, ENEMY_POST_FIRE_HANG)

func _spawn_pattern_fan() -> void:
	var mode := rng.randi_range(0, 2)
	var e: Enemy
	if mode == 0:
		e = _spawn_pattern_base(Vector2(rng.randf_range(FIELD_RECT.position.x + 140.0, FIELD_RECT.position.x + FIELD_RECT.size.x - 140.0), -60.0))
		e.fixed_dir = Vector2.DOWN
	else:
		var y := rng.randf_range(160.0, 420.0)
		if mode == 1:
			e = _spawn_pattern_base(Vector2(FIELD_RECT.position.x - 120.0, y))
			e.fixed_dir = Vector2.RIGHT
		else:
			e = _spawn_pattern_base(Vector2(FIELD_RECT.position.x + FIELD_RECT.size.x + 120.0, y))
			e.fixed_dir = Vector2.LEFT
	e.pattern = ENEMY_PATTERN_FAN
	_set_enemy_repeat(e, 1, 1.0, ENEMY_POST_FIRE_HANG)

func _spawn_pattern_ring() -> void:
	var e := _spawn_pattern_base(Vector2(FIELD_RECT.position.x + FIELD_RECT.size.x * 0.5, -60.0))
	e.pattern = ENEMY_PATTERN_RING
	_set_enemy_repeat(e, 1, 1.0, ENEMY_POST_FIRE_HANG)

func _spawn_pattern_spiral() -> void:
	var e := _spawn_pattern_base(Vector2(FIELD_RECT.position.x + FIELD_RECT.size.x * 0.5, -60.0))
	e.pattern = ENEMY_PATTERN_SPIRAL
	e.spiral_angle = rng.randf_range(0.0, 360.0)
	_set_enemy_repeat(e, 20, 0.12, 0.4)

func _spawn_pattern_cross() -> void:
	_spawn_cross_unit(Vector2(FIELD_RECT.position.x - 120.0, rng.randf_range(180.0, 420.0)), Vector2(1, 1))
	_spawn_cross_unit(Vector2(FIELD_RECT.position.x + FIELD_RECT.size.x + 120.0, rng.randf_range(180.0, 420.0)), Vector2(-1, 1))

func _spawn_cross_unit(pos: Vector2, dir: Vector2) -> void:
	var e := _spawn_pattern_base(pos)
	e.pattern = ENEMY_PATTERN_CROSS
	e.fixed_dir = dir.normalized()
	_set_enemy_repeat(e, 5, 0.8, 0.4)

func _spawn_pattern_base(start_pos: Vector2) -> Enemy:
	var e := Enemy.new()
	e.hp = 26.0
	e.state = 0
	e.t = 0.0
	e.pos = start_pos
	e.fired = false
	e.enter_speed = 260.0

	if start_pos.y < 0.0:
		var tx := clampf(start_pos.x, FIELD_RECT.position.x + 90.0, FIELD_RECT.position.x + FIELD_RECT.size.x - 90.0)
		var ty := rng.randf_range(140.0, 260.0)
		e.target = Vector2(tx, ty)
		e.exit_vel = Vector2(0, -240.0)
	else:
		var ty2 := clampf(start_pos.y, 160.0, 420.0)
		if start_pos.x < FIELD_RECT.position.x:
			e.target = Vector2(FIELD_RECT.position.x + 90.0, ty2)
			e.exit_vel = Vector2(-250.0, -30.0)
		else:
			e.target = Vector2(FIELD_RECT.position.x + FIELD_RECT.size.x - 90.0, ty2)
			e.exit_vel = Vector2(250.0, -30.0)

	enemies.append(e)
	return e

func _enemy_fire(e: Enemy) -> void:
	var dir: Vector2 = (player.pos - e.pos).normalized()
	var start_pos := e.pos + dir * ENEMY_MUZZLE_OFFSET
	var base_speed: float = rng.randf_range(380.0, 440.0)
	match e.pattern:
		ENEMY_PATTERN_ADD_AIMED:
			_spawn_enemy_bullet(start_pos, dir * base_speed, 6.0)
		ENEMY_PATTERN_ADD_FAN:
			for a2 in [-7.0, 7.0]:
				var d2 := dir.rotated(deg_to_rad(a2)).normalized()
				_spawn_enemy_bullet(e.pos + d2 * ENEMY_MUZZLE_OFFSET, d2 * (base_speed - 20.0), 6.0)
		ENEMY_PATTERN_ADD_RING:
			for a3 in [-9.0, 0.0, 9.0]:
				var d3 := dir.rotated(deg_to_rad(a3)).normalized()
				_spawn_enemy_bullet(e.pos + d3 * ENEMY_MUZZLE_OFFSET, d3 * (base_speed - 40.0), 5.5)
		ENEMY_PATTERN_AIMED:
			for a in [-10.0, 0.0, 10.0]:
				var d := dir.rotated(deg_to_rad(a)).normalized()
				var spd := rng.randf_range(140.0, 220.0)
				if rng.randf() < 0.18:
					spd = rng.randf_range(280.0, 340.0)
				elif rng.randf() < 0.18:
					spd = rng.randf_range(110.0, 140.0)
				_spawn_enemy_bullet(e.pos + d * ENEMY_MUZZLE_OFFSET, d * spd, 6.0)
			if rng.randf() < 0.22:
				var fast_dir := (player.pos - e.pos).normalized()
				_spawn_enemy_bullet(e.pos + fast_dir * ENEMY_MUZZLE_OFFSET, fast_dir * 360.0, 6.0)
		ENEMY_PATTERN_FAN:
			var base_dir := e.fixed_dir
			for ang in [-45.0, -30.0, -15.0, 0.0, 15.0, 30.0, 45.0]:
				var d2 := base_dir.rotated(deg_to_rad(ang)).normalized()
				var spd2 := rng.randf_range(150.0, 190.0)
				if rng.randf() < 0.15:
					spd2 = rng.randf_range(260.0, 310.0)
				elif rng.randf() < 0.15:
					spd2 = rng.randf_range(110.0, 140.0)
				_spawn_enemy_bullet(e.pos + d2 * ENEMY_MUZZLE_OFFSET, d2 * spd2, 6.0)
		ENEMY_PATTERN_RING:
			var n := rng.randi_range(16, 24)
			for i in range(n):
				var ang2 := (TAU / float(n)) * float(i)
				var d3 := Vector2(cos(ang2), sin(ang2))
				var spd3 := rng.randf_range(140.0, 200.0)
				if rng.randf() < 0.12:
					spd3 = rng.randf_range(240.0, 300.0)
				elif rng.randf() < 0.12:
					spd3 = rng.randf_range(110.0, 140.0)
				_spawn_enemy_bullet(e.pos + d3 * ENEMY_MUZZLE_OFFSET, d3 * spd3, 5.5)
		ENEMY_PATTERN_SPIRAL:
			var ang3 := deg_to_rad(e.spiral_angle)
			var d4 := Vector2(cos(ang3), sin(ang3))
			e.spiral_angle += 12.0
			var spd4 := rng.randf_range(140.0, 200.0)
			if rng.randf() < 0.12:
				spd4 = rng.randf_range(240.0, 290.0)
			elif rng.randf() < 0.12:
				spd4 = rng.randf_range(110.0, 140.0)
			_spawn_enemy_bullet(e.pos + d4 * ENEMY_MUZZLE_OFFSET, d4 * spd4, 5.5)
		ENEMY_PATTERN_CROSS:
			var d5 := e.fixed_dir.normalized()
			var spd5 := rng.randf_range(180.0, 220.0)
			if rng.randf() < 0.2:
				spd5 = rng.randf_range(260.0, 320.0)
			elif rng.randf() < 0.2:
				spd5 = rng.randf_range(120.0, 150.0)
			_spawn_enemy_bullet(e.pos + d5 * ENEMY_MUZZLE_OFFSET, d5 * spd5, 6.0)

func _current_wave_interval(time_sec: float) -> float:
	if time_sec < WAVE_1_END:
		return 0.85
	if time_sec < WAVE_2_END:
		return 0.72
	return 0.62

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
	# Keep some enemies alive; boss fight also spawns adds.
	_switch_bgm(BOSS_BGM_PATH, true)
	var b := Boss.new()
	b.pos = Vector2(FIELD_RECT.position.x + FIELD_RECT.size.x * 0.5, 180)
	b.hp = BOSS_MAX_HP
	b.max_hp = BOSS_MAX_HP
	b.shoot_cd = 0.0
	b.pattern_t = 0.0
	b.segment = BOSS_SEGMENTS
	b.phase = 1
	b.phase_start = state.time
	b.mix_cd = 1.5
	boss = b
	boss_anim = "idle"
	boss_anim_t = 0.0
	boss_stun_until = 0.0
	boss_death_playing = false
	state.phase = 1
	state.phase_start = state.time
	_add_log("Boss detected: Blackout.")

func _update_boss(delta: float) -> void:
	if boss == null:
		return

	# Animation state
	if boss_death_playing:
		boss_anim = "death"
		boss_anim_t += delta
		var death_len := 0.6 if boss_death_frames.is_empty() else (float(boss_death_frames.size()) / 7.0)
		if boss_anim_t >= death_len:
			boss = null
			_add_score(50000)
			_show_result(true)
		return

	if state.time < boss_stun_until:
		boss_anim = "stun"
		boss_anim_t += delta
		# During stun, stop shooting but keep slight movement
		boss.pattern_t += delta
		boss.pos.x = FIELD_RECT.position.x + FIELD_RECT.size.x * 0.5 + sin(boss.pattern_t * 0.7) * 120.0
		_update_boss_phase()
		return

	if boss_anim != "idle":
		boss_anim = "idle"
		boss_anim_t = 0.0
	else:
		boss_anim_t += delta

	boss.pattern_t += delta
	boss.pos.x = FIELD_RECT.position.x + FIELD_RECT.size.x * 0.5 + sin(boss.pattern_t * 0.7) * 120.0

	_update_boss_phase()

	var speed_mul: float = 1.0
	if state.time - state.phase_start > BOSS_PHASE_TIME:
		speed_mul = 1.5

	# Mix in extra attacks occasionally
	boss.mix_cd -= delta
	if boss.mix_cd <= 0.0:
		boss.mix_cd = 3.6
		_boss_mix_attack(speed_mul)

	boss.shoot_cd -= delta
	if boss.shoot_cd > 0.0:
		return

	match boss.phase:
		1:
			boss.shoot_cd = 0.35
			var dir: Vector2 = (player.pos - boss.pos).normalized()
			for angle in [-12.0, 0.0, 12.0]:
				var d := dir.rotated(deg_to_rad(angle)).normalized()
				var start_pos := boss.pos + d * BOSS_MUZZLE_OFFSET
				_spawn_boss_bullet(start_pos, d * 240.0 * speed_mul, 6.0)
		2:
			boss.shoot_cd = 0.2
			var count: int = 14
			for i in range(count):
				var angle: float = boss.pattern_t * 1.8 + (TAU / count) * i
				var dir: Vector2 = Vector2(cos(angle), sin(angle))
				var start_pos := boss.pos + dir * BOSS_MUZZLE_OFFSET
				_spawn_boss_bullet(start_pos, dir * 220.0 * speed_mul, 5.0)
		3:
			boss.shoot_cd = 0.18
			var base: float = (player.pos - boss.pos).angle()
			for angle in [-20.0, -8.0, 0.0, 8.0, 20.0]:
				var dir3 := Vector2.RIGHT.rotated(base + deg_to_rad(angle))
				var start_pos := boss.pos + dir3.normalized() * BOSS_MUZZLE_OFFSET
				_spawn_boss_bullet(start_pos, dir3 * 260.0 * speed_mul, 6.0)
			var ring: int = 10
			for i in range(ring):
				var ang: float = boss.pattern_t * 2.0 + (TAU / ring) * i
				var dir_ring: Vector2 = Vector2(cos(ang), sin(ang))
				var start_pos2 := boss.pos + dir_ring * BOSS_MUZZLE_OFFSET
				_spawn_boss_bullet(start_pos2, dir_ring * 200.0 * speed_mul, 4.0)

func _boss_mix_attack(speed_mul: float) -> void:
	if boss == null:
		return
	var pick := rng.randi_range(0, 2)
	match pick:
		0:
			# Aimed burst
			var dir := (player.pos - boss.pos).normalized()
			for a in [-18.0, -9.0, 0.0, 9.0, 18.0]:
				var d := dir.rotated(deg_to_rad(a)).normalized()
				_spawn_boss_bullet(boss.pos + d * BOSS_MUZZLE_OFFSET, d * 320.0 * speed_mul, 6.0)
		1:
			# Dense ring
			var n := 18
			for i in range(n):
				var ang := boss.pattern_t * 1.2 + (TAU / float(n)) * float(i)
				var d2 := Vector2(cos(ang), sin(ang))
				_spawn_boss_bullet(boss.pos + d2 * BOSS_MUZZLE_OFFSET, d2 * 230.0 * speed_mul, 5.0)
		2:
			# Spiral pair
			var n2 := 12
			for i in range(n2):
				var ang2 := boss.pattern_t * 2.8 + (TAU / float(n2)) * float(i)
				var d3 := Vector2(cos(ang2), sin(ang2))
				var d4 := Vector2(cos(ang2 + PI), sin(ang2 + PI))
				_spawn_boss_bullet(boss.pos + d3 * BOSS_MUZZLE_OFFSET, d3 * 210.0 * speed_mul, 4.0)
				_spawn_boss_bullet(boss.pos + d4 * BOSS_MUZZLE_OFFSET, d4 * 210.0 * speed_mul, 4.0)

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
	boss_stun_until = max(boss_stun_until, state.time + BOSS_STUN_TIME)
	boss_anim = "stun"
	boss_anim_t = 0.0
	# Attract spawned items to player for a short window so they are auto-collected
	state.item_attract_until = state.time + 2.0

func _check_boss_breaks() -> void:
	_update_boss_phase()

func _on_boss_defeated() -> void:
	if boss == null:
		return
	if boss_death_playing:
		return
	# Play death sheet first, then clear
	boss_death_playing = true
	boss_anim = "death"
	boss_anim_t = 0.0

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
				var min_r: float = PLAYER_HIT_RADIUS + b.r
				var max_r: float = PLAYER_GRAZE_RADIUS + b.r
				var t := 0.0
				if max_r > min_r:
					t = clampf(1.0 - ((dist - min_r) / (max_r - min_r)), 0.0, 1.0)
				# Stronger reward for very-close grazes: scale from 0.2x to 2.2x of base
				var gain := lerpf(GRAZE_CHARGE * 0.2, GRAZE_CHARGE * 2.2, t)
				state.graze = min(state.graze + gain, 1.0)
			
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
			_spawn_item(enemies[i].pos, 3)
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
	if state.power_point >= 220:
		return 5
	if state.power_point >= 140:
		return 4
	if state.power_point >= 80:
		return 3
	if state.power_point >= 30:
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
	var life_label := ui.get("life") as Label
	if life_label != null:
		life_label.text = str(state.life)
	var pwr_label := ui.get("power") as Label
	if pwr_label != null:
		pwr_label.text = str(_power_level())

	# Lumi portrait state: hurt during invuln (until right before it ends), else charging when graze full.
	if ui.has("lumi_portrait"):
		var portrait: TextureRect = ui["lumi_portrait"]
		var tex: Texture2D = tex_lumi_ui_normal
		var inv_left: float = player.inv_until - state.time
		if inv_left > 0.2 and tex_lumi_ui_hurt != null:
			tex = tex_lumi_ui_hurt
		elif state.graze >= 1.0 and tex_lumi_ui_charge != null:
			tex = tex_lumi_ui_charge
		elif tex_lumi_ui_normal != null:
			tex = tex_lumi_ui_normal
		portrait.texture = tex

	for i in range(ui_life_icons.size()):
		var icon := ui_life_icons[i]
		icon.texture = tex_hp_on if i < state.life else tex_hp_off

	var lvl := _power_level()
	for i in range(ui_power_icons.size()):
		var icon2 := ui_power_icons[i]
		icon2.texture = tex_lv_on if i < lvl else tex_lv_off

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
	# Keep graze bar below the character sprite.
	bar_pos.y = player.pos.y + PLAYER_DRAW_HEIGHT * 0.5 + 14.0
	bar_pos.x = clamp(bar_pos.x, FIELD_RECT.position.x, FIELD_RECT.position.x + FIELD_RECT.size.x - graze_bar.size.x)
	bar_pos.y = clamp(bar_pos.y, FIELD_RECT.position.y + 12.0, FIELD_RECT.position.y + FIELD_RECT.size.y - 20.0)
	graze_bar.position = bar_pos

func _format_time(seconds: float) -> String:
	var clamped: float = max(0.0, seconds)
	var s: int = int(floor(clamped))
	var hs: int = int(floor((clamped - float(s)) * 100.0))
	var mm: String = String.num_int64(s / 60).pad_zeros(2)
	var ss: String = String.num_int64(s % 60).pad_zeros(2)
	var hh: String = String.num_int64(hs).pad_zeros(2)
	return mm + ":" + ss + "." + hh

func _format_int_with_commas(v: int) -> String:
	var s := str(max(v, 0))
	var out := ""
	var cnt := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		cnt += 1
		if cnt % 3 == 0 and i != 0:
			out = "," + out
	return out

func _add_score(amount: int) -> void:
	state.score += amount
	# NOTE: Removed score-based HP auto-fill to prevent the "Level 5 instantly fills HP" bug.
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
