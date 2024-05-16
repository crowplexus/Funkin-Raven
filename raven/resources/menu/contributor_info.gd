## Resource File representing a Contributor
class_name Contributor extends Resource

@export_category("Info")
## the Contributor's Username
@export var username: StringName = "Some User"
## Contributor's doings in the Project.
@export_multiline var description: String = "Did this and that."
## URL opened in browser when pressing enter.
@export var redirect_url: String = "https://example.com"
## User's GitHub Username, useful for fetching commits.
#@export var git_user: StringName

@export_category("Icon")
## Icon that shows up in the Credits Menu
@export var portrait: Texture2D
## Horizontal Frames of the Icon
@export var port_hframes: int = 1
## Vertical Frames of the Icon
@export var port_vframes: int = 1

func _make_icon() -> Sprite2D:
	if portrait == null: return Sprite2D.new()
	var cool_sprite: Sprite2D = Sprite2D.new()
	cool_sprite.texture = portrait
	cool_sprite.hframes = port_hframes
	cool_sprite.vframes = port_vframes
	return cool_sprite
