extends Node2D

signal coin_collected(total: int)
signal enemy_stomped(total: int)
signal player_died(deaths: int)
signal level_finished(stats: Dictionary)

const PLAYER_SCENE := preload("res://game/player.gd")
const ENEMY_SCENE := preload("res://game/enemy.gd")
const COIN_SCENE := preload("res://game/coin.gd")
const FLAG_SCENE := preload("res://game/flag.gd")

const SKY_TOP := Color(0.35, 0.62, 0.95)
const SKY_BOTTOM := Color(0.55, 0.82, 0.98)
const GROUND := Color(0.42, 0.28, 0.16)
const GRASS := Color(0.28, 0.72, 0.32)
const BRICK := Color(0.78, 0.42, 0.22)
const CLOUD := Color(1.0, 1.0, 1.0, 0.85)

# Each platform: [x, y, width, height, style]
# style: "ground" | "brick" | "pipe"
const PLATFORMS: Array = [
	[0, 520, 520, 80, "ground"],
	[620, 520, 280, 80, "ground"],
	[980, 520, 360, 80, "ground"],
	[1420, 520, 320, 80, "ground"],
	[1820, 520, 420, 80, "ground"],
	[2320, 520, 520, 80, "ground"],
	[2880, 520, 640, 80, "ground"],
	[180, 420, 160, 24, "brick"],
	[420, 360, 120, 24, "brick"],
	[760, 400, 140, 24, "brick"],
	[1080, 340, 120, 24, "brick"],
	[1280, 280, 160, 24, "brick"],
	[1560, 380, 120, 24, "brick"],
	[1740, 300, 140, 24, "brick"],
	[2060, 360, 160, 24, "brick"],
	[2280, 280, 120, 24, "brick"],
	[2520, 380, 140, 24, "brick"],
	[2680, 300, 160, 24, "brick"],
	[2920, 400, 120, 24, "brick"],
	[3140, 320, 180, 24, "brick"],
	[3380, 260, 140, 24, "brick"],
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
	{"pos": Vector2(760, 492), "left": 640, "right": 900},
	{"pos": Vector2(1180, 492), "left": 1000, "right": 1320},
	{"pos": Vector2(1620, 492), "left": 1440, "right": 1720},
	{"pos": Vector2(2100, 492), "left": 1840, "right": 2220},
	{"pos": Vector2(2580, 492), "left": 2340, "right": 2780},
	{"pos": Vector2(3100, 492), "left": 2900, "right": 3380},
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
	_build_background()
	_build_platforms()
	_spawn_coins()
	_spawn_enemies()
	_spawn_flag()
	_spawn_player()
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = 0
	camera.limit_right = 3600
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
	sky.size = Vector2(3600, 600)
	sky.color = SKY_BOTTOM
	sky.z_index = -20
	add_child(sky)

	for i in range(8):
		var band := ColorRect.new()
		band.position = Vector2(0, i * 72)
		band.size = Vector2(3600, 72)
		band.color = SKY_TOP.lerp(SKY_BOTTOM, float(i) / 7.0)
		band.z_index = -19
		add_child(band)

	for cloud in [Vector2(180, 90), Vector2(620, 130), Vector2(1180, 70), Vector2(1760, 110), Vector2(2380, 85), Vector2(3020, 120)]:
		_add_cloud(cloud)

	for hill in [[120, 520, 220], [980, 520, 280], [2100, 520, 320], [3100, 520, 260]]:
		_add_hill(Vector2(hill[0], hill[1]), hill[2])


func _add_cloud(pos: Vector2) -> void:
	var root := Node2D.new()
	root.position = pos
	root.z_index = -15
	add_child(root)
	for offset in [Vector2(-28, 0), Vector2(0, -8), Vector2(28, 0), Vector2(12, 6)]:
		var puff := ColorRect.new()
		puff.color = CLOUD
		puff.size = Vector2(44, 24)
		puff.position = offset
		root.add_child(puff)


func _add_hill(foot: Vector2, width: float) -> void:
	var hill := Polygon2D.new()
	hill.color = Color(0.22, 0.58, 0.28, 0.55)
	hill.polygon = PackedVector2Array([
		foot + Vector2(-width * 0.5, 0),
		foot + Vector2(0, -width * 0.35),
		foot + Vector2(width * 0.5, 0),
	])
	hill.z_index = -12
	add_child(hill)


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

	var visual := ColorRect.new()
	visual.size = size
	if style == "ground":
		visual.color = GROUND
		body.add_child(visual)
		var grass := ColorRect.new()
		grass.size = Vector2(size.x, 10)
		grass.color = GRASS
		body.add_child(grass)
	elif style == "brick":
		visual.color = BRICK
		body.add_child(visual)
		var stripe_count := int(size.x / 24.0)
		for i in range(stripe_count):
			var mark := ColorRect.new()
			mark.color = BRICK.darkened(0.12)
			mark.size = Vector2(20, 4)
			mark.position = Vector2(i * 24.0 + 2, 4)
			body.add_child(mark)


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

		var sprite := ColorRect.new()
		sprite.name = "Sprite"
		sprite.size = Vector2(20, 20)
		sprite.position = Vector2(-10, -10)
		sprite.color = Color(1.0, 0.86, 0.18)
		coin.add_child(sprite)

		var shine := ColorRect.new()
		shine.size = Vector2(6, 6)
		shine.position = Vector2(-4, -6)
		shine.color = Color(1, 1, 0.75)
		coin.add_child(shine)

		coin.collected.connect(_on_coin_collected)
		add_child(coin)


func _spawn_enemies() -> void:
	for data in ENEMIES:
		var enemy := CharacterBody2D.new()
		enemy.position = data["pos"]
		enemy.set_script(ENEMY_SCENE)
		enemy.add_to_group("enemy")
		enemy.collision_layer = 4
		enemy.collision_mask = 1

		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(28, 28)
		shape.shape = rect
		shape.position = Vector2(0, -14)
		enemy.add_child(shape)

		var sprite := ColorRect.new()
		sprite.name = "Sprite"
		sprite.size = Vector2(28, 28)
		sprite.position = Vector2(-14, -28)
		sprite.color = Color(0.85, 0.18, 0.18)
		enemy.add_child(sprite)

		var eye_l := ColorRect.new()
		eye_l.size = Vector2(6, 8)
		eye_l.position = Vector2(-8, -22)
		eye_l.color = Color.WHITE
		enemy.add_child(eye_l)

		var eye_r := eye_l.duplicate()
		eye_r.position = Vector2(2, -22)
		enemy.add_child(eye_r)

		enemy.setup(data["left"], data["right"], randf() > 0.5)
		add_child(enemy)


func _spawn_flag() -> void:
	var flag := Area2D.new()
	flag.position = Vector2(3480, 420)
	flag.set_script(FLAG_SCENE)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24, 96)
	shape.shape = rect
	shape.position = Vector2(0, -48)
	flag.add_child(shape)

	var pole := ColorRect.new()
	pole.size = Vector2(6, 96)
	pole.position = Vector2(-3, -96)
	pole.color = Color(0.75, 0.75, 0.78)
	flag.add_child(pole)

	var banner := ColorRect.new()
	banner.size = Vector2(34, 22)
	banner.position = Vector2(3, -88)
	banner.color = Color(0.95, 0.2, 0.35)
	flag.add_child(banner)

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
	rect.size = Vector2(22, 30)
	shape.shape = rect
	shape.position = Vector2(0, -15)
	player.add_child(shape)

	var sprite := ColorRect.new()
	sprite.name = "Sprite"
	sprite.size = Vector2(22, 30)
	sprite.position = Vector2(-11, -30)
	sprite.color = Color(0.18, 0.45, 0.95)
	player.add_child(sprite)

	var cap := ColorRect.new()
	cap.size = Vector2(24, 8)
	cap.position = Vector2(-12, -32)
	cap.color = Color(0.95, 0.25, 0.2)
	player.add_child(cap)

	var stomp := Area2D.new()
	stomp.name = "StompZone"
	stomp.position = Vector2(0, -8)
	stomp.collision_layer = 0
	stomp.collision_mask = 4
	var stomp_shape := CollisionShape2D.new()
	var stomp_rect := RectangleShape2D.new()
	stomp_rect.size = Vector2(18, 8)
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
	# Stomps from above are handled by the player's stomp zone.
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
