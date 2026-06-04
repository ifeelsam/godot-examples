extends Node2D

signal coin_collected(total: int)
signal enemy_stomped(total: int)
signal player_died(deaths: int)
signal level_finished(stats: Dictionary)

const PLAYER_SCENE := preload("res://game/player.gd")
const ENEMY_SCENE := preload("res://game/enemy.gd")
const COIN_SCENE := preload("res://game/coin.gd")
const FLAG_SCENE := preload("res://game/flag.gd")

const LEVEL_WIDTH := 3600.0
const GROUND_Y := 520.0

# Each platform: [x, y, width, height, style]
# style: "ground" | "wood" | "cloud"
const PLATFORMS: Array = [
	[0, GROUND_Y, 520, 80, "ground"],
	[620, GROUND_Y, 280, 80, "ground"],
	[980, GROUND_Y, 360, 80, "ground"],
	[1420, GROUND_Y, 320, 80, "ground"],
	[1820, GROUND_Y, 420, 80, "ground"],
	[2320, GROUND_Y, 520, 80, "ground"],
	[2880, GROUND_Y, 640, 80, "ground"],
	[180, 420, 160, 24, "wood"],
	[420, 360, 120, 24, "cloud"],
	[760, 400, 140, 24, "wood"],
	[1080, 340, 120, 24, "cloud"],
	[1280, 280, 160, 24, "wood"],
	[1560, 380, 120, 24, "cloud"],
	[1740, 300, 140, 24, "wood"],
	[2060, 360, 160, 24, "cloud"],
	[2280, 280, 120, 24, "wood"],
	[2520, 380, 140, 24, "cloud"],
	[2680, 300, 160, 24, "wood"],
	[2920, 400, 120, 24, "cloud"],
	[3140, 320, 180, 24, "wood"],
	[3380, 260, 140, 24, "cloud"],
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

const DECORATIONS: Array = [
	{"pos": Vector2(140, 492), "kind": "bush"},
	{"pos": Vector2(700, 492), "kind": "mushroom"},
	{"pos": Vector2(1540, 492), "kind": "bush"},
	{"pos": Vector2(2450, 492), "kind": "mushroom"},
	{"pos": Vector2(3300, 492), "kind": "bush"},
]

var player: CharacterBody2D
var camera: Camera2D
var deaths := 0
var coins := 0
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
	_spawn_coins()
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
	stomps = 0
	elapsed = 0.0
	_reset_player()


func set_controls(direction: float, wants_jump: bool) -> void:
	if player != null and is_instance_valid(player):
		player.set_input(direction, wants_jump)


func get_hud() -> Dictionary:
	return {
		"coins": coins,
		"stomps": stomps,
		"deaths": deaths,
		"time": elapsed,
	}


func _build_background() -> void:
	var sky := ColorRect.new()
	sky.size = Vector2(LEVEL_WIDTH, 560)
	sky.color = PixelAssets.SKY_COLOR
	sky.z_index = -30
	add_child(sky)

	var hills := Node2D.new()
	hills.z_index = -22
	hills.modulate = Color(1, 1, 1, 0.45)
	add_child(hills)
	for x in range(0, int(LEVEL_WIDTH), int(PixelAssets.BG_TILE_WORLD * 2)):
		var hill := PixelAssets.make_bg_sprite(PixelAssets.TEX_BG_HILL)
		hill.position = Vector2(x + PixelAssets.BG_TILE_WORLD, 430)
		hills.add_child(hill)

	var trees := Node2D.new()
	trees.z_index = -20
	trees.modulate = Color(1, 1, 1, 0.55)
	add_child(trees)
	for x in [180, 620, 1180, 1760, 2380, 3020]:
		var tree := PixelAssets.make_bg_sprite(PixelAssets.TEX_BG_TREES)
		tree.position = Vector2(x, 470)
		trees.add_child(tree)

	for cloud_pos in [Vector2(220, 110), Vector2(760, 80), Vector2(1380, 130), Vector2(2060, 95), Vector2(2860, 120), Vector2(3340, 70)]:
		_add_cloud(cloud_pos)


func _add_cloud(pos: Vector2) -> void:
	var root := Node2D.new()
	root.position = pos
	root.z_index = -18
	root.modulate = Color(1, 1, 1, 0.85)
	add_child(root)
	for offset in [Vector2(-48, 0), Vector2(-16, -12), Vector2(20, -4), Vector2(52, 2)]:
		var puff := PixelAssets.make_bg_sprite(PixelAssets.TEX_BG_CLOUD, 1.6)
		puff.position = offset
		root.add_child(puff)


func _build_platforms() -> void:
	for data in PLATFORMS:
		_add_platform(Vector2(data[0], data[1]), Vector2(data[2], data[3]), data[4])


func _add_platform(pos: Vector2, size: Vector2, style: String) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	add_child(body)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = size * 0.5
	body.add_child(shape)

	var visual := Node2D.new()
	body.add_child(visual)
	match style:
		"ground":
			PixelAssets.build_ground_visual(visual, size)
		"cloud":
			PixelAssets.build_cloud_visual(visual, size)
		_:
			PixelAssets.build_wood_visual(visual, size)


func _spawn_decorations() -> void:
	for data in DECORATIONS:
		var sprite := PixelAssets.make_sprite(
			PixelAssets.TEX_BUSH if data["kind"] == "bush" else PixelAssets.TEX_MUSHROOM
		)
		sprite.position = data["pos"]
		sprite.z_index = -2
		add_child(sprite)


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

		coin.collected.connect(_on_coin_collected)
		add_child(coin)


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
	flag.position = Vector2(3480, 420)
	flag.set_script(FLAG_SCENE)
	flag.collision_layer = 0
	flag.collision_mask = 2
	flag.monitoring = true

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24, 96)
	shape.shape = rect
	shape.position = Vector2(0, -48)
	flag.add_child(shape)

	var sprite := PixelAssets.make_sprite(PixelAssets.TEX_FLAG, 2.5)
	sprite.position = Vector2(0, -54)
	flag.add_child(sprite)

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


func _on_coin_collected() -> void:
	coins += 1
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
		"stomps": stomps,
		"deaths": deaths,
		"time": elapsed,
	})
