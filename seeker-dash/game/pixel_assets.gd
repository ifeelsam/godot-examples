extends RefCounted
class_name PixelAssets

const TILE_SIZE := 18.0
const DISPLAY_SCALE := 2.0
const TILE_WORLD := TILE_SIZE * DISPLAY_SCALE

const ROOT := "res://ui/pixel-platformer/Tiles/"
const CHAR := "res://ui/pixel-platformer/Tiles/Characters/"
const BG := "res://ui/pixel-platformer/Tiles/Backgrounds/"

const TEX_COIN := preload("res://ui/pixel-platformer/Tiles/tile_0151.png")
const TEX_FLAG := preload("res://ui/pixel-platformer/Tiles/tile_0111.png")
const TEX_GRASS_TOP := preload("res://ui/pixel-platformer/Tiles/tile_0058.png")
const TEX_DIRT := preload("res://ui/pixel-platformer/Tiles/tile_0062.png")
const TEX_BRICK := preload("res://ui/pixel-platformer/Tiles/tile_0061.png")
const TEX_PLAYER := preload("res://ui/pixel-platformer/Tiles/Characters/tile_0000.png")
const TEX_ENEMY := preload("res://ui/pixel-platformer/Tiles/Characters/tile_0012.png")
const TEX_CLOUD := preload("res://ui/pixel-platformer/Tiles/Backgrounds/tile_0008.png")
const TEX_BG_SKY := preload("res://ui/pixel-platformer/Tiles/Backgrounds/tile_0000.png")
const TEX_HILL := preload("res://ui/pixel-platformer/Tiles/Backgrounds/tile_0012.png")
const TEX_BUTTON := preload("res://ui/pixel-platformer/Tiles/tile_0047.png")
const TEX_SPRING := preload("res://ui/pixel-platformer/Tiles/tile_0064.png")
const TEX_JOY_BASE := preload("res://ui/pixel-platformer/Tiles/tile_0059.png")
const TEX_JOY_KNOB := preload("res://ui/pixel-platformer/Tiles/tile_0047.png")
const TEX_COIN_HUD := preload("res://ui/pixel-platformer/Tiles/tile_0152.png")


static func make_sprite(texture: Texture2D, scale_factor: float = DISPLAY_SCALE) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.centered = true
	return sprite


static func make_texture_rect(texture: Texture2D, size: Vector2) -> TextureRect:
	var node := TextureRect.new()
	node.texture = texture
	node.custom_minimum_size = size
	node.size = size
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_TILE
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return node


static func fill_tiles(parent: Node, texture: Texture2D, size: Vector2) -> void:
	var layer := Node2D.new()
	parent.add_child(layer)
	var cols := maxi(1, int(ceil(size.x / TILE_WORLD)))
	var rows := maxi(1, int(ceil(size.y / TILE_WORLD)))
	for y in range(rows):
		for x in range(cols):
			var sprite := make_sprite(texture)
			sprite.position = Vector2(
				x * TILE_WORLD + TILE_WORLD * 0.5,
				y * TILE_WORLD + TILE_WORLD * 0.5
			)
			layer.add_child(sprite)


static func build_ground_visual(parent: Node, size: Vector2) -> void:
	var top_rows := 1
	var top_height := TILE_WORLD * top_rows
	fill_tiles(parent, TEX_GRASS_TOP, Vector2(size.x, top_height))
	if size.y > top_height:
		var dirt_root := Node2D.new()
		dirt_root.position = Vector2(0, top_height)
		parent.add_child(dirt_root)
		fill_tiles(dirt_root, TEX_DIRT, Vector2(size.x, size.y - top_height))


static func build_brick_visual(parent: Node, size: Vector2) -> void:
	fill_tiles(parent, TEX_BRICK, size)
