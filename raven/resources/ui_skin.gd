class_name UISkin extends Resource

@export_category("Textures")

@export var judgements: Texture2D = preload("res://assets/images/ui/normal/judgements.png")
@export var numbers: Texture2D = preload("res://assets/images/ui/normal/numbers.png")
@export var combo: Texture2D = preload("res://assets/images/ui/normal/combo.png")

@export var countdown_sprites: Array[Texture2D] = [
	null,
	preload("res://assets/images/ui/normal/ready.png"),
	preload("res://assets/images/ui/normal/set.png"),
	preload("res://assets/images/ui/normal/go.png"),
]
@export var countdown_sfx: Array[AudioStream] = [
	preload("res://assets/audio/sfx/game/intro/3.ogg"),
	preload("res://assets/audio/sfx/game/intro/2.ogg"),
	preload("res://assets/audio/sfx/game/intro/1.ogg"),
	preload("res://assets/audio/sfx/game/intro/go.ogg"),
]
@export var miss_sounds: Array[AudioStream] = [
	preload("res://assets/audio/sfx/game/miss/miss1.ogg"),
	preload("res://assets/audio/sfx/game/miss/miss2.ogg"),
	preload("res://assets/audio/sfx/game/miss/miss3.ogg"),
]

@export_category("Sprite Scaling")

@export var judgement_scale: Vector2 = Vector2(0.7, 0.7)
@export var numbers_scale: Vector2 = Vector2(0.6, 0.6)
@export var combo_scale: Vector2 = Vector2(0.6, 0.6)
@export var countdown_scale: Vector2 = Vector2.ONE

@export_category("Sprite Texture Filter")

@export var judgement_filter: = CanvasItem.TEXTURE_FILTER_LINEAR
@export var countdown_filter: = CanvasItem.TEXTURE_FILTER_LINEAR
@export var numbers_filter: = CanvasItem.TEXTURE_FILTER_LINEAR
@export var combo_filter: = CanvasItem.TEXTURE_FILTER_LINEAR

func create_judgement_spr(le_judge: String):
	var judgement: VelocitySprite2D = VelocitySprite2D.new()
	judgement.texture = judgements
	judgement.vframes = 4
	judgement.scale = judgement_scale
	judgement.texture_filter = judgement_filter
	
	var new_frame: int = Highscore.judgements.keys().find(le_judge)
	if le_judge != "epic": new_frame = new_frame-1
	else:
		judgement.modulate = Color(Highscore.judgements[le_judge][4])
	judgement.frame = new_frame
	return judgement

func create_combo_spr():
	var combo_spr: VelocitySprite2D = VelocitySprite2D.new()
	combo_spr.texture = combo
	combo_spr.texture_filter = combo_filter
	combo_spr.scale = combo_scale
	return combo_spr

func create_combo_number(numb: int):
	var number: VelocitySprite2D = VelocitySprite2D.new()
	number.texture = numbers
	number.hframes = 10
	number.scale = numbers_scale
	number.texture_filter = numbers_filter
	number.frame = numb
	return number

func create_countdown_spr(count: int):
	var countdown_spr: Sprite2D = Sprite2D.new()
	countdown_spr.texture = countdown_sprites[count]
	countdown_spr.scale = countdown_scale
	countdown_spr.texture_filter = countdown_filter
	return countdown_spr
