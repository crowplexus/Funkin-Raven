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

@export var countdown_sprite_filter: = CanvasItem.TEXTURE_FILTER_LINEAR
