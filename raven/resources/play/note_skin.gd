## Configuration File for Note Skins.
class_name NoteSkin extends Resource
## Declares how the noteskin's color works.[br]
## This is important as it denominates how the noteskins menu will look like.
enum SkinColour {
	## Colors are set in the image itself.
	SET	= 0,
	## Colors are set in accordance to your settings.
	CUSTOM	= 1,
}
var name: StringName = "idk"
var colour_mode: = SkinColour.SET
var apply_to: Array[StringName] = ["normal"]
var receptor: Receptor

func propagate_call(fun: String, arg: Array = []) -> int:
	var ret: int = -1 # 0 for success, anything else for failure.
	if has_method(fun):
		var result: Variant = callv(fun, arg)
		if result is int: ret = int(result)
	return ret

static func create_if_exists(skin: StringName = "") -> NoteSkin:
	if skin.is_empty(): skin = Settings.note_skin

	# try user folder, if not, hardcoded res folder.
	var folder: String = "user://noteskins/%s/config.gd" % skin
	if not ResourceLoader.exists(folder):
		folder = folder.replace("user://", "res://assets/")
	# if the noteskin really isn't anywhere to be found, use fallback.
	if not ResourceLoader.exists(folder):
		folder = folder.replace(skin, "fallback")

	# then create it
	var note_skin: Variant = load(folder).new()
	if note_skin is NoteSkin:
		note_skin.name = skin
		return note_skin
	else:
		note_skin.unreference()
		return null

static func get_skin_color_mode(skin: StringName = "") -> int:
	var skin_colour_mode: int = SkinColour.SET
	if skin.is_empty(): skin = Settings.note_skin
	var note_skin: = create_if_exists(skin)
	if note_skin != null:
		skin_colour_mode = note_skin.colour_mode
		note_skin.unreference()
	return skin_colour_mode

static func get_noteskins_at(dirs: Array[String] = []) -> Array[StringName]:
	var noteskins: Array[StringName] = ["fnf", "raven"]
	if dirs.is_empty(): # default directories
		dirs = ["user://noteskins/", "res://assets/noteskins/"]

	for directory in dirs:
		if not DirAccess.dir_exists_absolute(directory):
			continue

		for skin in DirAccess.get_directories_at(directory):
			if not noteskins.has(skin) and ResourceLoader.exists(directory + skin + "/config.gd"):
				noteskins.append(skin)

	return noteskins

