extends Node

# Lightweight sound-effect bus. Registered as the "Sfx" autoload so any node can
# call Sfx.play("coin"). Uses a small pool of AudioStreamPlayers so overlapping
# effects (coins, stomps) don't cut each other off.

const POOL_SIZE := 10

const STREAMS := {
	"coin": preload("res://ui/sounds/collectibles/coin.wav"),
	"jump": preload("res://ui/sounds/player/player_jump.wav"),
	"hit": preload("res://ui/sounds/player/player_hit.wav"),
	"bounce": preload("res://ui/sounds/surfaces/bouncepad.wav"),
	"confirm": preload("res://ui/sounds/screens/confirm_ui.wav"),
	"axe": preload("res://ui/sounds/hazards/axe_trap.wav"),
	"bird": preload("res://ui/sounds/entities/bird.wav"),
	"fish": preload("res://ui/sounds/entities/fish.wav"),
	"spider": preload("res://ui/sounds/entities/spider.wav"),
}

var _pool: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_pool.append(p)


func play(key: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not STREAMS.has(key):
		return
	var player := _free_player()
	player.stream = STREAMS[key]
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()


func _free_player() -> AudioStreamPlayer:
	for p in _pool:
		if not p.playing:
			return p
	# All busy — round-robin reuse so we never silently drop a cue.
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	return p
