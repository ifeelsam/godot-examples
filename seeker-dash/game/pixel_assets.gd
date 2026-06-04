extends RefCounted
class_name PixelAssets

const TILE_SIZE := 18.0
const DISPLAY_SCALE := 2.0
const TILE_WORLD := TILE_SIZE * DISPLAY_SCALE

const BG_TILE_SIZE := 24.0
const BG_DISPLAY_SCALE := 2.0
const BG_TILE_WORLD := BG_TILE_SIZE * BG_DISPLAY_SCALE

const ROOT := "res://ui/pixel-platformer/Tiles/"
const CHAR := "res://ui/pixel-platformer/Tiles/Characters/"
const BG := "res://ui/pixel-platformer/Tiles/Backgrounds/"

const TEX_COIN := preload("res://ui/pixel-platformer/Tiles/tile_0151.png")
const TEX_FLAG := preload("res://ui/pixel-platformer/Tiles/tile_0111.png")
const TEX_COIN_HUD := preload("res://ui/pixel-platformer/Tiles/tile_0152.png")

const TEX_GRASS_LEFT := preload("res://ui/pixel-platformer/Tiles/tile_0021.png")
const TEX_GRASS_MID := preload("res://ui/pixel-platformer/Tiles/tile_0022.png")
const TEX_GRASS_RIGHT := preload("res://ui/pixel-platformer/Tiles/tile_0023.png")
const TEX_DIRT_LEFT := preload("res://ui/pixel-platformer/Tiles/tile_0121.png")
const TEX_DIRT_MID := preload("res://ui/pixel-platformer/Tiles/tile_0122.png")
const TEX_DIRT_RIGHT := preload("res://ui/pixel-platformer/Tiles/tile_0123.png")

const TEX_WOOD_LEFT := preload("res://ui/pixel-platformer/Tiles/tile_0049.png")
const TEX_WOOD_MID := preload("res://ui/pixel-platformer/Tiles/tile_0050.png")
const TEX_WOOD_RIGHT := preload("res://ui/pixel-platformer/Tiles/tile_0051.png")

const TEX_CLOUD_LEFT := preload("res://ui/pixel-platformer/Tiles/tile_0080.png")
const TEX_CLOUD_MID := preload("res://ui/pixel-platformer/Tiles/tile_0081.png")
const TEX_CLOUD_RIGHT := preload("res://ui/pixel-platformer/Tiles/tile_0082.png")

const TEX_PLAYER := preload("res://ui/pixel-platformer/Tiles/Characters/tile_0000.png")
const TEX_ENEMY_SLIME := preload("res://ui/pixel-platformer/Tiles/Characters/tile_0012.png")
const TEX_ENEMY_ROBOT := preload("res://ui/pixel-platformer/Tiles/Characters/tile_0008.png")

const TEX_BUSH := preload("res://ui/pixel-platformer/Tiles/tile_0056.png")
const TEX_MUSHROOM := preload("res://ui/pixel-platformer/Tiles/tile_0093.png")

const TEX_BG_SKY := preload("res://ui/pixel-platformer/Tiles/Backgrounds/tile_0002.png")
const TEX_BG_HILL := preload("res://ui/pixel-platformer/Tiles/Backgrounds/tile_0014.png")
const TEX_BG_TREES := preload("res://ui/pixel-platformer/Tiles/Backgrounds/tile_0015.png")
const TEX_BG_CLOUD := preload("res://ui/pixel-platformer/Tiles/Backgrounds/tile_0008.png")

const SKY_COLOR := Color(0.67, 0.9, 0.96)


static func make_sprite(texture: Texture2D, scale_factor: float = DISPLAY_SCALE) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.centered = true
	return sprite


static func make_bg_sprite(texture: Texture2D, scale_factor: float = BG_DISPLAY_SCALE) -> Sprite2D:
	return make_sprite(texture, scale_factor)


static func _tile_columns(width: float) -> int:
	return maxi(1, int(ceil(width / TILE_WORLD)))


static func _place_row(parent: Node, width: float, y_offset: float, left: Texture2D, mid: Texture2D, right: Texture2D) -> void:
	var cols := _tile_columns(width)
	for x in range(cols):
		var texture := mid
		if x == 0:
			texture = left
		elif x == cols - 1:
			texture = right
		var sprite := make_sprite(texture)
		sprite.position = Vector2(
			x * TILE_WORLD + TILE_WORLD * 0.5,
			y_offset + TILE_WORLD * 0.5
		)
		parent.add_child(sprite)


static func build_ground_visual(parent: Node, size: Vector2) -> void:
	_place_row(parent, size.x, 0.0, TEX_GRASS_LEFT, TEX_GRASS_MID, TEX_GRASS_RIGHT)
	var fill_height := size.y - TILE_WORLD
	if fill_height <= 0.0:
		return
	var rows := maxi(1, int(ceil(fill_height / TILE_WORLD)))
	for y in range(rows):
		_place_row(parent, size.x, TILE_WORLD + y * TILE_WORLD, TEX_DIRT_LEFT, TEX_DIRT_MID, TEX_DIRT_RIGHT)


static func build_wood_visual(parent: Node, size: Vector2) -> void:
	_place_row(parent, size.x, 0.0, TEX_WOOD_LEFT, TEX_WOOD_MID, TEX_WOOD_RIGHT)


static func build_cloud_visual(parent: Node, size: Vector2) -> void:
	_place_row(parent, size.x, 0.0, TEX_CLOUD_LEFT, TEX_CLOUD_MID, TEX_CLOUD_RIGHT)


static func build_brick_visual(parent: Node, size: Vector2) -> void:
	build_wood_visual(parent, size)
