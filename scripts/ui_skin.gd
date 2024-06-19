extends Resource
class_name UISkin

@export_category("Gameplay")

@export var countdown_sprites: Array[Texture2D] = [
	preload("res://assets/sprites/ui/normal/prepare.png"),
	preload("res://assets/sprites/ui/normal/ready.png"),
	preload("res://assets/sprites/ui/normal/set.png"),
	preload("res://assets/sprites/ui/normal/go.png"),
]
@export var countdown_sounds: Array[AudioStream] = [
	preload("res://assets/audio/sfx/gameplay/intro3.ogg"),
	preload("res://assets/audio/sfx/gameplay/intro2.ogg"),
	preload("res://assets/audio/sfx/gameplay/intro1.ogg"),
	preload("res://assets/audio/sfx/gameplay/introGo.ogg"),
]

@export var judgment_row: Texture2D = preload("res://assets/sprites/ui/normal/judgments.png")
@export var combo_row: Texture2D = preload("res://assets/sprites/ui/normal/combo.png")

@export_category("Filtering")

@export var countdown_sprite_filter: = CanvasItem.TEXTURE_FILTER_LINEAR
@export var judgment_sprite_filter: = CanvasItem.TEXTURE_FILTER_LINEAR
@export var combo_num_sprite_filter: = CanvasItem.TEXTURE_FILTER_LINEAR

@export_category("Scaling")

@export var countdown_sprite_scale: Vector2 = Vector2.ONE
@export var judgment_sprite_scale:  Vector2 = Vector2(0.65, 0.65)
@export var combo_num_sprite_scale: Vector2 = Vector2(0.45, 0.45)
