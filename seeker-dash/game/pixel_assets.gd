extends RefCounted
class_name PixelAssets

const TILE_SIZE := 18.0
const DISPLAY_SCALE := 2.0
const TILE_WORLD := TILE_SIZE * DISPLAY_SCALE

const CHAR_SIZE := 24.0
const CHAR_DISPLAY_SCALE := TILE_WORLD / CHAR_SIZE

const BG_TILE_SIZE := 24.0
const BG_DISPLAY_SCALE := 2.0
const BG_TILE_WORLD := BG_TILE_SIZE * BG_DISPLAY_SCALE

const TEX_COIN := preload("res://ui/pixel-platformer/Tiles/tile_0151.png")
const TEX_FLAG := preload("res://ui/pixel-platformer/Tiles/tile_0111.png")
const TEX_COIN_HUD := preload("res://ui/pixel-platformer/Tiles/tile_0152.png")

const TEX_GRASS_BLOCK := preload("res://ui/pixel-platformer/Tiles/tile_0022.png")
const TEX_DIRT_BLOCK := preload("res://ui/pixel-platformer/Tiles/tile_0122.png")
const TEX_WOOD_BLOCK := preload("res://ui/pixel-platformer/Tiles/tile_0050.png")
const TEX_CLOUD_BLOCK := preload("res://ui/pixel-platformer/Tiles/tile_0081.png")

const TEX_PLAYER := preload("res://ui/pixel-platformer/Tiles/Characters/tile_0021.png")
const TEX_ENEMY_SLIME := preload("res://ui/pixel-platformer/Tiles/Characters/tile_0012.png")
const TEX_ENEMY_ROBOT := preload("res://ui/pixel-platformer/Tiles/Characters/tile_0008.png")

const TEX_BUSH := preload("res://ui/pixel-platformer/Tiles/tile_0056.png")
const TEX_MUSHROOM := preload("res://ui/pixel-platformer/Tiles/tile_0093.png")

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


static func make_character_sprite(texture: Texture2D) -> Sprite2D:
	return make_sprite(texture, CHAR_DISPLAY_SCALE)


static func make_bg_sprite(texture: Texture2D, scale_factor: float = BG_DISPLAY_SCALE) -> Sprite2D:
	return make_sprite(texture, scale_factor)


static func fill_blocks(parent: Node, size: Vector2, texture: Texture2D, offset := Vector2.ZERO) -> void:
	var cols := maxi(1, int(ceil(size.x / TILE_WORLD)))
	var rows := maxi(1, int(ceil(size.y / TILE_WORLD)))
	for y in range(rows):
		for x in range(cols):
			var sprite := make_sprite(texture)
			sprite.position = offset + Vector2(
				x * TILE_WORLD + TILE_WORLD * 0.5,
				y * TILE_WORLD + TILE_WORLD * 0.5
			)
			parent.add_child(sprite)


static func build_ground_visual(parent: Node, size: Vector2) -> void:
	fill_blocks(parent, Vector2(size.x, TILE_WORLD), TEX_GRASS_BLOCK)
	var fill_height := size.y - TILE_WORLD
	if fill_height > 0.0:
		fill_blocks(parent, Vector2(size.x, fill_height), TEX_DIRT_BLOCK, Vector2(0.0, TILE_WORLD))


static func build_wood_visual(parent: Node, size: Vector2) -> void:
	fill_blocks(parent, size, TEX_WOOD_BLOCK)


static func build_cloud_visual(parent: Node, size: Vector2) -> void:
	fill_blocks(parent, size, TEX_CLOUD_BLOCK)
