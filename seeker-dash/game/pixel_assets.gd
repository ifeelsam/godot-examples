extends RefCounted
class_name PixelAssets

# Art helper for the "Super Mango" pixel pack.
# Tiles are authored at 16 px; tilesets are 3x3 (48x48) autotile blocks.
# Characters / hazards live on 48 px animation strips. Backgrounds are 384x216
# parallax layers. Everything renders with nearest-neighbour filtering.

const TILE := 16.0
const WORLD_SCALE := 3.0
const TILE_WORLD := TILE * WORLD_SCALE          # 48 px on screen
const CHAR_SCALE := 3.0
# Content in every 48 px cell rests with its feet near native y=32.
const FEET_OFFSET := 8.0 * CHAR_SCALE           # sprite.y so feet sit on origin
const PLAYER_FEET_OFFSET := 9.0 * CHAR_SCALE

const SPRITES := "res://ui/sprites/"

# --- Characters ---------------------------------------------------------
const PLAYER_SHEET := preload("res://ui/sprites/player/player.png")
const PLAYER_FRAME := 48

const TEX_SPIDER := preload("res://ui/sprites/entities/spider.png")
const TEX_JUMPING_SPIDER := preload("res://ui/sprites/entities/jumping_spider.png")
const TEX_BIRD := preload("res://ui/sprites/entities/bird.png")
const TEX_FASTER_BIRD := preload("res://ui/sprites/entities/faster_bird.png")
const TEX_FISH := preload("res://ui/sprites/entities/fish.png")
const TEX_FASTER_FISH := preload("res://ui/sprites/entities/faster_fish.png")

# --- Collectibles -------------------------------------------------------
const TEX_COIN := preload("res://ui/sprites/collectibles/coin.png")
const TEX_STAR_YELLOW := preload("res://ui/sprites/collectibles/star_yellow.png")
const TEX_STAR_GREEN := preload("res://ui/sprites/collectibles/star_green.png")
const TEX_STAR_RED := preload("res://ui/sprites/collectibles/star_red.png")
const TEX_LAST_STAR := preload("res://ui/sprites/collectibles/last_star.png")

# --- Hazards ------------------------------------------------------------
const TEX_SPIKE := preload("res://ui/sprites/hazards/spike.png")
const TEX_SPIKE_BLOCK := preload("res://ui/sprites/hazards/spike_block.png")
const TEX_SPIKE_PLATFORM := preload("res://ui/sprites/hazards/spike_platform.png")
const TEX_CIRCULAR_SAW := preload("res://ui/sprites/hazards/circular_saw.png")
const TEX_FIRE_FLAME := preload("res://ui/sprites/hazards/fire_flame.png")
const TEX_BLUE_FLAME := preload("res://ui/sprites/hazards/blue_flame.png")
const TEX_AXE_TRAP := preload("res://ui/sprites/hazards/axe_trap.png")

# --- Tilesets (3x3, 16 px tiles) ---------------------------------------
const TILESET_GRASS := preload("res://ui/sprites/levels/grass_tileset.png")
const TILESET_GRASS_ROCK := preload("res://ui/sprites/levels/grass_rock_tileset.png")
const TILESET_BRICK := preload("res://ui/sprites/levels/brick_tileset.png")
const TILESET_STONE := preload("res://ui/sprites/levels/stone_tileset.png")
const TILESET_LEAF := preload("res://ui/sprites/levels/leaf_tileset.png")
const TILESET_CLOUD := preload("res://ui/sprites/levels/cloud_tileset.png")
const TILESET_GRASS_GROUND := preload("res://ui/sprites/levels/grass_platform.png")

# --- Surfaces -----------------------------------------------------------
const TEX_BRIDGE := preload("res://ui/sprites/surfaces/bridge.png")
const TEX_FLOAT_PLATFORM := preload("res://ui/sprites/surfaces/float_platform.png")
const TEX_LADDER := preload("res://ui/sprites/surfaces/ladder.png")
const TEX_VINE_GREEN := preload("res://ui/sprites/surfaces/vine_green.png")
const TEX_BOUNCEPAD := preload("res://ui/sprites/surfaces/bouncepad_high.png")
const TEX_BOUNCEPAD_MED := preload("res://ui/sprites/surfaces/bouncepad_medium.png")

# --- Backgrounds / foregrounds -----------------------------------------
const BG_SKY := preload("res://ui/sprites/backgrounds/sky_blue.png")
const BG_GLACIAL := preload("res://ui/sprites/backgrounds/glacial_mountains_lightened.png")
const BG_CLOUDS_BG := preload("res://ui/sprites/backgrounds/clouds_bg.png")
const BG_CLOUDS_1 := preload("res://ui/sprites/backgrounds/clouds_mg_1.png")
const BG_CLOUDS_2 := preload("res://ui/sprites/backgrounds/clouds_mg_2.png")
const BG_CLOUDS_3 := preload("res://ui/sprites/backgrounds/clouds_mg_3.png")
const BG_FOREST_LEAFS := preload("res://ui/sprites/backgrounds/forest_leafs.png")
const FG_FOG_1 := preload("res://ui/sprites/foregrounds/fog_1.png")
const FG_WATER := preload("res://ui/sprites/foregrounds/water.png")

# --- Screens / HUD ------------------------------------------------------
const TEX_LOGO := preload("res://ui/sprites/screens/start_menu_logo.png")
const TEX_HUD_COINS := preload("res://ui/sprites/screens/hud_coins.png")

# Backwards-compatible aliases used by the shell / wallet gate.
const TEX_COIN_HUD := TEX_HUD_COINS
const TEX_FLAG := TEX_LAST_STAR

const FONT := preload("res://ui/fonts/round9x13.ttf")

const SKY_COLOR := Color(0.031, 0.663, 0.988)   # sky_blue.png solid fill


# ----------------------------------------------------------------------
# Sprite factories
# ----------------------------------------------------------------------
static func make_sprite(texture: Texture2D, scale_factor: float = WORLD_SCALE) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.centered = true
	return sprite


static func _atlas(sheet: Texture2D, col: int, row: int, fw: int, fh: int) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = sheet
	at.region = Rect2(col * fw, row * fh, fw, fh)
	at.filter_clip = true
	return at


# Single-frame icon from a sheet, for UI use (e.g. the idle player face).
static func player_icon() -> AtlasTexture:
	return _atlas(PLAYER_SHEET, 0, 0, PLAYER_FRAME, PLAYER_FRAME)


# Build an AnimatedSprite2D from a horizontal strip (single row, all columns).
static func make_strip_anim(sheet: Texture2D, frame: int, fps: float, scale_factor: float = CHAR_SCALE, loop: bool = true) -> AnimatedSprite2D:
	var frame_h := int(sheet.get_height())
	var cols := int(sheet.get_width() / frame)
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", fps)
	frames.set_animation_loop("default", loop)
	for c in range(cols):
		frames.add_frame("default", _atlas(sheet, c, 0, frame, frame_h))
	var node := AnimatedSprite2D.new()
	node.sprite_frames = frames
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.scale = Vector2(scale_factor, scale_factor)
	node.centered = true
	node.play("default")
	return node


# Player sheet: 4 cols x 6 rows of 48 px frames. Named animations mapped from
# the sheet layout (idle/run/jump/fall/hurt).
static func make_player_sprite() -> AnimatedSprite2D:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	_add_anim(f, "idle", [[0, 0], [1, 0], [2, 0], [3, 0]], 6.0, true)
	_add_anim(f, "run", [[0, 1], [1, 1], [2, 1], [3, 1]], 12.0, true)
	_add_anim(f, "jump", [[0, 2]], 1.0, false)
	_add_anim(f, "fall", [[1, 2]], 1.0, false)
	_add_anim(f, "hurt", [[0, 5], [1, 5], [2, 5]], 8.0, false)
	var node := AnimatedSprite2D.new()
	node.sprite_frames = f
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.scale = Vector2(CHAR_SCALE, CHAR_SCALE)
	node.centered = true
	node.animation = "idle"
	node.play("idle")
	return node


static func _add_anim(frames: SpriteFrames, name: String, cells: Array, fps: float, loop: bool) -> void:
	frames.add_animation(name)
	frames.set_animation_loop(name, loop)
	frames.set_animation_speed(name, fps)
	for cell in cells:
		frames.add_frame(name, _atlas(PLAYER_SHEET, cell[0], cell[1], PLAYER_FRAME, PLAYER_FRAME))


# ----------------------------------------------------------------------
# Tileset 9-slice rendering
# ----------------------------------------------------------------------
# Renders a WxH region using a 3x3 (16 px) tileset: corners, edges, centre fill.
static func build_tileset_box(parent: Node, size: Vector2, tileset: Texture2D) -> void:
	var cols := maxi(1, int(round(size.x / TILE_WORLD)))
	var rows := maxi(1, int(round(size.y / TILE_WORLD)))
	for ry in range(rows):
		for rx in range(cols):
			var tx := 1
			var ty := 1
			if rx == 0:
				tx = 0
			elif rx == cols - 1:
				tx = 2
			if ry == 0:
				ty = 0
			elif ry == rows - 1:
				ty = 2
			if cols == 1:
				tx = 1
			if rows == 1:
				ty = 1
			var tile := make_sprite(_atlas(tileset, tx, ty, int(TILE), int(TILE)))
			tile.position = Vector2(rx * TILE_WORLD + TILE_WORLD * 0.5, ry * TILE_WORLD + TILE_WORLD * 0.5)
			parent.add_child(tile)


# Ground: grass-topped dirt that runs off the bottom of the screen.
static func build_ground(parent: Node, size: Vector2) -> void:
	var cols := maxi(1, int(round(size.x / TILE_WORLD)))
	var rows := maxi(1, int(round(size.y / TILE_WORLD)))
	for ry in range(rows):
		for rx in range(cols):
			var tx := 1
			if rx == 0:
				tx = 0
			elif rx == cols - 1:
				tx = 2
			var ty := 0 if ry == 0 else 1
			if cols == 1:
				tx = 1
			var tile := make_sprite(_atlas(TILESET_GRASS_GROUND, tx, ty, int(TILE), int(TILE)))
			tile.position = Vector2(rx * TILE_WORLD + TILE_WORLD * 0.5, ry * TILE_WORLD + TILE_WORLD * 0.5)
			parent.add_child(tile)


# ----------------------------------------------------------------------
# UI theme (crisp pixel font)
# ----------------------------------------------------------------------
static func make_ui_theme(base_size: int = 26) -> Theme:
	var font: Font = FONT
	if font is FontFile:
		var ff := font as FontFile
		ff.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		ff.hinting = TextServer.HINTING_NONE
		ff.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		ff.force_autohinter = false
	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = base_size
	return theme
