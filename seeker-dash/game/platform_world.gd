extends Node2D

signal coin_collected(total: int)
signal star_collected(total: int)
signal enemy_stomped(total: int)
signal player_died(deaths: int)
signal level_finished(stats: Dictionary)

const PLAYER_SCENE := preload("res://game/player.gd")
const ENEMY_SCENE := preload("res://game/enemy.gd")
const COIN_SCENE := preload("res://game/coin.gd")
const FLAG_SCENE := preload("res://game/flag.gd")
const HAZARD_SCENE := preload("res://game/hazard.gd")
const BOUNCEPAD_SCENE := preload("res://game/bouncepad.gd")

const LEVEL_WIDTH := 3600.0
const GROUND_Y := 520.0

# Each platform: [x, y, width, height, style]
# style: "ground" | "grass" | "stone" | "brick" | "cloud" | "leaf"
const PLATFORMS: Array = [
	[0, GROUND_Y, 520, 96, "ground"],
	[620, GROUND_Y, 280, 96, "ground"],
	[980, GROUND_Y, 360, 96, "ground"],
	[1420, GROUND_Y, 320, 96, "ground"],
	[1820, GROUND_Y, 420, 96, "ground"],
	[2320, GROUND_Y, 520, 96, "ground"],
	[2880, GROUND_Y, 640, 96, "ground"],
	[180, 420, 144, 48, "grass"],
	[420, 360, 96, 48, "cloud"],
	[760, 400, 144, 48, "stone"],
	[1080, 340, 96, 48, "cloud"],
	[1280, 280, 144, 48, "brick"],
	[1560, 380, 96, 48, "cloud"],
	[1740, 300, 144, 48, "grass"],
	[2060, 360, 144, 48, "stone"],
	[2280, 280, 96, 48, "cloud"],
	[2520, 380, 144, 48, "leaf"],
	[2680, 300, 144, 48, "brick"],
	[2920, 400, 96, 48, "cloud"],
	[3140, 320, 192, 48, "grass"],
	[3380, 260, 144, 48, "stone"],
]

const COINS: Array = [
	Vector2(220, 480), Vector2(260, 480), Vector2(300, 480),
	Vector2(460, 320), Vector2(500, 320), Vector2(540, 320),
	Vector2(820, 360), Vector2(860, 360),
	Vector2(1120, 300), Vector2(1160, 300), Vector2(1200, 300),
	Vector2(1340, 240), Vector2(1380, 240),
	Vector2(1600, 340), Vector2(1640, 340),
	Vector2(1780, 260), Vector2(1820, 260), Vector2(1860, 260),
	Vector2(2100, 320), Vector2(2140, 320), Vector2(2180, 320),
	Vector2(2320, 240), Vector2(2360, 240),
	Vector2(2560, 340), Vector2(2600, 340),
	Vector2(2720, 260), Vector2(2760, 260), Vector2(2800, 260),
	Vector2(2960, 360), Vector2(3000, 360),
	Vector2(3200, 280), Vector2(3240, 280), Vector2(3280, 280),
	Vector2(3420, 220), Vector2(3460, 220),
]

const ENEMIES: Array = [
	{"pos": Vector2(760, 500), "left": 640, "right": 900, "kind": "spider"},
	{"pos": Vector2(1180, 320), "left": 1000, "right": 1340, "kind": "bird"},
	{"pos": Vector2(1620, 500), "left": 1440, "right": 1720, "kind": "spider"},
	{"pos": Vector2(2100, 300), "left": 1860, "right": 2240, "kind": "fish"},
	{"pos": Vector2(2580, 500), "left": 2340, "right": 2780, "kind": "spider"},
	{"pos": Vector2(3100, 310), "left": 2900, "right": 3380, "kind": "bird"},
]

# Bonus gem stars. color picks the sprite tint variant.
const STARS: Array = [
	{"pos": Vector2(500, 300), "color": "yellow"},
	{"pos": Vector2(1360, 230), "color": "green"},
	{"pos": Vector2(2160, 250), "color": "red"},
	{"pos": Vector2(2760, 250), "color": "yellow"},
	{"pos": Vector2(3260, 270), "color": "green"},
]

# Death traps. spikes/flame sit on the ground; saw floats and spins; axe swings.
const HAZARDS: Array = [
	{"pos": Vector2(1120, GROUND_Y), "kind": "spikes"},
	{"pos": Vector2(2020, GROUND_Y), "kind": "flame"},
	{"pos": Vector2(820, 250), "kind": "saw"},
	{"pos": Vector2(2280, 285), "kind": "axe"},
]

# Trampolines that fling the player toward the high platforms.
const BOUNCEPADS: Array = [
	{"pos": Vector2(700, GROUND_Y)},
	{"pos": Vector2(2380, GROUND_Y)},
]

var player: CharacterBody2D
var camera: Camera2D
var deaths := 0
var coins := 0
var stars := 0
var stomps := 0
var elapsed := 0.0
var running := false
var finished := false
var respawn_point := Vector2(80, 460)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_background()
	_build_platforms()
	_spawn_decorations()
	_spawn_hazards()
	_spawn_bouncepads()
	_spawn_coins()
	_spawn_stars()
	_spawn_enemies()
	_spawn_flag()
	_spawn_player()
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = 0
	camera.limit_right = int(LEVEL_WIDTH)
	camera.limit_top = 0
	camera.limit_bottom = 720
	add_child(camera)
	camera.make_current()


func _process(delta: float) -> void:
	if running and not finished:
		elapsed += delta
	if player != null and is_instance_valid(player):
		camera.global_position = player.global_position + Vector2(0, -40)


func start_run() -> void:
	running = true
	finished = false
	deaths = 0
	coins = 0
	stars = 0
	stomps = 0
	elapsed = 0.0
	_reset_player()


func set_controls(direction: float, wants_jump: bool) -> void:
	if player != null and is_instance_valid(player):
		player.set_input(direction, wants_jump)


func get_hud() -> Dictionary:
	return {
		"coins": coins,
		"stars": stars,
		"stomps": stomps,
		"deaths": deaths,
		"time": elapsed,
	}


func _build_background() -> void:
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -20
	add_child(sky_layer)
	var sky := ColorRect.new()
	sky.color = PixelAssets.SKY_COLOR
	sky.size = Vector2(1280, 720)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky_layer.add_child(sky)

	var px := ParallaxBackground.new()
	px.layer = -10
	add_child(px)
	_add_parallax(px, PixelAssets.BG_GLACIAL, 0.12, 1.0)
	_add_parallax(px, PixelAssets.BG_CLOUDS_BG, 0.22, 1.0)
	_add_parallax(px, PixelAssets.BG_CLOUDS_3, 0.32, 1.0)
	_add_parallax(px, PixelAssets.BG_CLOUDS_2, 0.42, 1.0)
	_add_parallax(px, PixelAssets.BG_CLOUDS_1, 0.52, 1.0)
	_add_parallax(px, PixelAssets.FG_FOG_1, 0.78, 0.4)


func _add_parallax(px: ParallaxBackground, tex: Texture2D, motion: float, alpha: float) -> void:
	var layer := ParallaxLayer.new()
	layer.motion_scale = Vector2(motion, motion)
	var scale := 720.0 / tex.get_height()
	layer.motion_mirroring = Vector2(tex.get_width() * scale, 0)
	px.add_child(layer)

	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = false
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(scale, scale)
	spr.modulate = Color(1, 1, 1, alpha)
	layer.add_child(spr)


func _build_platforms() -> void:
	for data in PLATFORMS:
		_add_platform(Vector2(data[0], data[1]), Vector2(data[2], data[3]), data[4])


func _add_platform(pos: Vector2, size: Vector2, style: String) -> void:
	var cols := maxi(1, int(round(size.x / PixelAssets.TILE_WORLD)))
	var rows := maxi(1, int(round(size.y / PixelAssets.TILE_WORLD)))
	var snapped := Vector2(cols * PixelAssets.TILE_WORLD, rows * PixelAssets.TILE_WORLD)

	var body := StaticBody2D.new()
	body.position = pos
	add_child(body)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = snapped
	shape.shape = rect
	shape.position = snapped * 0.5
	body.add_child(shape)

	var visual := Node2D.new()
	body.add_child(visual)

	if style == "ground":
		PixelAssets.build_ground(visual, snapped)
		return

	var tileset := PixelAssets.TILESET_GRASS
	match style:
		"stone":
			tileset = PixelAssets.TILESET_STONE
		"brick":
			tileset = PixelAssets.TILESET_BRICK
		"cloud":
			tileset = PixelAssets.TILESET_CLOUD
		"leaf":
			tileset = PixelAssets.TILESET_LEAF
	PixelAssets.build_tileset_box(visual, snapped, tileset)


func _spawn_decorations() -> void:
	# Vine clumps rooted on the ground for a bit of forest depth.
	for x in [150, 590, 1560, 2470, 3320]:
		var vine := PixelAssets.make_sprite(PixelAssets.TEX_VINE_GREEN)
		vine.position = Vector2(x, GROUND_Y - 72.0)
		vine.z_index = -2
		add_child(vine)


func _spawn_hazards() -> void:
	for data in HAZARDS:
		match data.get("kind", "spikes"):
			"flame":
				_add_flame(data["pos"])
			"saw":
				_add_saw(data["pos"])
			"axe":
				_add_axe(data["pos"])
			_:
				_add_spikes(data["pos"])


func _add_spikes(pos: Vector2) -> void:
	var hz := Area2D.new()
	hz.set_script(HAZARD_SCENE)
	hz.position = pos
	add_child(hz)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(120, 24)
	shape.shape = rect
	shape.position = Vector2(0, -18)
	hz.add_child(shape)

	var spr := PixelAssets.make_sprite(PixelAssets.TEX_SPIKE_PLATFORM)
	spr.position = Vector2(0, -24)
	hz.add_child(spr)


func _add_flame(pos: Vector2) -> void:
	var hz := Area2D.new()
	hz.set_script(HAZARD_SCENE)
	hz.position = pos
	add_child(hz)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(26, 56)
	shape.shape = rect
	shape.position = Vector2(0, -32)
	hz.add_child(shape)

	var anim := PixelAssets.make_strip_anim(PixelAssets.TEX_FIRE_FLAME, PixelAssets.PLAYER_FRAME, 9.0)
	anim.position = Vector2(0, -PixelAssets.FEET_OFFSET)
	hz.add_child(anim)


func _add_saw(pos: Vector2) -> void:
	var hz := Area2D.new()
	hz.set_script(HAZARD_SCENE)
	hz.position = pos
	add_child(hz)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 40.0
	shape.shape = circle
	hz.add_child(shape)

	var spr := PixelAssets.make_sprite(PixelAssets.TEX_CIRCULAR_SAW)
	hz.add_child(spr)
	var spin := spr.create_tween().set_loops()
	spin.tween_property(spr, "rotation", TAU, 0.6).from(0.0)


func _add_axe(pos: Vector2) -> void:
	var pivot := Node2D.new()
	pivot.position = pos
	add_child(pivot)

	var hz := Area2D.new()
	hz.set_script(HAZARD_SCENE)
	pivot.add_child(hz)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(34, 48)
	shape.shape = rect
	shape.position = Vector2(0, 176)
	hz.add_child(shape)

	var spr := PixelAssets.make_sprite(PixelAssets.TEX_AXE_TRAP)
	spr.position = Vector2(0, 96)
	pivot.add_child(spr)

	var swing := pivot.create_tween().set_loops()
	swing.tween_property(pivot, "rotation", 0.85, 1.1).from(-0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	swing.tween_callback(func() -> void: Sfx.play("axe", -8.0))
	swing.tween_property(pivot, "rotation", -0.85, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	swing.tween_callback(func() -> void: Sfx.play("axe", -8.0))


func _spawn_bouncepads() -> void:
	for data in BOUNCEPADS:
		var pad := Area2D.new()
		pad.set_script(BOUNCEPAD_SCENE)
		pad.position = data["pos"]
		add_child(pad)

		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(120, 46)
		shape.shape = rect
		shape.position = Vector2(0, -44)
		pad.add_child(shape)

		var anim := PixelAssets.make_strip_anim(PixelAssets.TEX_BOUNCEPAD, PixelAssets.PLAYER_FRAME, 18.0, PixelAssets.CHAR_SCALE, false)
		anim.position = Vector2(0, -PixelAssets.FEET_OFFSET)
		pad.add_child(anim)
		pad.bind_anim(anim)


func _spawn_coins() -> void:
	for point in COINS:
		var coin := Area2D.new()
		coin.position = point
		coin.set_script(COIN_SCENE)
		coin.add_to_group("coin")
		coin.collision_layer = 0
		coin.collision_mask = 2
		coin.monitoring = true

		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 16.0
		shape.shape = circle
		coin.add_child(shape)

		var sprite := PixelAssets.make_sprite(PixelAssets.TEX_COIN)
		sprite.name = "Sprite"
		sprite.position = Vector2(0, -8)
		coin.add_child(sprite)

		coin.collected.connect(_on_pickup)
		add_child(coin)


func _spawn_stars() -> void:
	for data in STARS:
		var star := Area2D.new()
		star.position = data["pos"]
		star.set_script(COIN_SCENE)
		star.kind = "star"
		star.value = 1
		star.add_to_group("coin")
		star.collision_layer = 0
		star.collision_mask = 2
		star.monitoring = true

		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 18.0
		shape.shape = circle
		star.add_child(shape)

		var texture := PixelAssets.TEX_STAR_YELLOW
		match data.get("color", "yellow"):
			"green":
				texture = PixelAssets.TEX_STAR_GREEN
			"red":
				texture = PixelAssets.TEX_STAR_RED
		var sprite := PixelAssets.make_sprite(texture)
		sprite.name = "Sprite"
		sprite.position = Vector2(0, -8)
		star.add_child(sprite)

		star.collected.connect(_on_pickup)
		add_child(star)


func _spawn_enemies() -> void:
	for data in ENEMIES:
		var kind: String = data.get("kind", "spider")
		var enemy := CharacterBody2D.new()
		enemy.position = data["pos"]
		enemy.set_script(ENEMY_SCENE)
		enemy.add_to_group("enemy")
		enemy.collision_layer = 4
		enemy.collision_mask = 1

		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(30, 28)
		shape.shape = rect
		shape.position = Vector2(0, -16)
		enemy.add_child(shape)

		var texture := PixelAssets.TEX_SPIDER
		var fps := 8.0
		var opts := {"speed": 80.0, "sound": "spider"}
		match kind:
			"bird":
				texture = PixelAssets.TEX_BIRD
				fps = 10.0
				opts = {"flying": true, "speed": 130.0, "bob": 26.0, "bob_speed": 2.4, "sound": "bird"}
			"fish":
				texture = PixelAssets.TEX_FISH
				fps = 6.0
				opts = {"flying": true, "speed": 95.0, "bob": 34.0, "bob_speed": 3.0, "sound": "fish"}

		var sprite := PixelAssets.make_strip_anim(texture, PixelAssets.PLAYER_FRAME, fps)
		sprite.name = "Sprite"
		sprite.position = Vector2(0, -PixelAssets.FEET_OFFSET)
		enemy.add_child(sprite)

		enemy.setup(data["left"], data["right"], randf() > 0.5, opts)
		add_child(enemy)


func _spawn_flag() -> void:
	var flag := Area2D.new()
	flag.position = Vector2(3460, GROUND_Y)
	flag.set_script(FLAG_SCENE)
	flag.collision_layer = 0
	flag.collision_mask = 2
	flag.monitoring = true

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(48, 280)
	shape.shape = rect
	shape.position = Vector2(0, -140)
	flag.add_child(shape)

	# Beanstalk pole topped with the goal star.
	for i in range(2):
		var seg := PixelAssets.make_sprite(PixelAssets.TEX_VINE_GREEN)
		seg.position = Vector2(0, -72.0 - i * 144.0)
		flag.add_child(seg)

	var star := PixelAssets.make_sprite(PixelAssets.TEX_LAST_STAR, 4.0)
	star.position = Vector2(0, -300)
	flag.add_child(star)

	var pulse := star.create_tween().set_loops()
	pulse.tween_property(star, "scale", Vector2(4.6, 4.6), 0.6).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(star, "scale", Vector2(4.0, 4.0), 0.6).set_trans(Tween.TRANS_SINE)

	flag.reached.connect(_on_flag_reached)
	add_child(flag)


func _spawn_player() -> void:
	player = CharacterBody2D.new()
	player.position = respawn_point
	player.set_script(PLAYER_SCENE)
	player.add_to_group("player")
	player.collision_layer = 2
	player.collision_mask = 1 | 4
	player.z_index = 10

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(30, 40)
	shape.shape = rect
	shape.position = Vector2(0, -20)
	player.add_child(shape)

	var sprite := PixelAssets.make_player_sprite()
	sprite.name = "Sprite"
	sprite.position = Vector2(0, -PixelAssets.PLAYER_FEET_OFFSET)
	player.add_child(sprite)

	var stomp := Area2D.new()
	stomp.name = "StompZone"
	stomp.position = Vector2(0, -6)
	stomp.collision_layer = 0
	stomp.collision_mask = 4
	var stomp_shape := CollisionShape2D.new()
	var stomp_rect := RectangleShape2D.new()
	stomp_rect.size = Vector2(26, 12)
	stomp_shape.shape = stomp_rect
	stomp.add_child(stomp_shape)
	player.add_child(stomp)

	player.died.connect(_on_player_died)
	player.stomped_enemy.connect(_on_enemy_stomped)

	add_child(player)
	_wire_enemy_hits()


func _wire_enemy_hits() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not enemy.has_meta("wired"):
			enemy.set_meta("wired", true)
			var hitbox := Area2D.new()
			hitbox.collision_layer = 4
			hitbox.collision_mask = 2
			var hit_shape := CollisionShape2D.new()
			var hit_rect := RectangleShape2D.new()
			hit_rect.size = Vector2(24, 24)
			hit_shape.shape = hit_rect
			hit_shape.position = Vector2(0, -14)
			hitbox.add_child(hit_shape)
			enemy.add_child(hitbox)
			hitbox.body_entered.connect(_on_enemy_touch_player.bind(enemy))


func _on_enemy_touch_player(body: Node, enemy: Node) -> void:
	if not running or finished:
		return
	if body != player or not enemy.alive:
		return
	if player.velocity.y > 0 and player.global_position.y < enemy.global_position.y - 8:
		return
	player.take_damage()


func _on_pickup(kind: String, value: int) -> void:
	if kind == "star":
		stars += value
		emit_signal("star_collected", stars)
	else:
		coins += value
		emit_signal("coin_collected", coins)


func _on_enemy_stomped() -> void:
	stomps += 1
	emit_signal("enemy_stomped", stomps)


func _on_player_died() -> void:
	deaths += 1
	emit_signal("player_died", deaths)
	await get_tree().create_timer(0.6).timeout
	if running and not finished:
		_reset_player()


func _reset_player() -> void:
	if player == null:
		_spawn_player()
		return

	player.alive = true
	player.global_position = respawn_point
	player.velocity = Vector2.ZERO
	player.sprite.modulate = Color.WHITE
	player.sprite.flip_h = false
	player.sprite.play("idle")


func _on_flag_reached() -> void:
	if finished:
		return
	finished = true
	running = false
	emit_signal("level_finished", {
		"coins": coins,
		"stars": stars,
		"stomps": stomps,
		"deaths": deaths,
		"time": elapsed,
	})
