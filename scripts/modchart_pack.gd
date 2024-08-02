extends Node
class_name ModchartPack
enum CallableRequest {
	NONE = 0,
	STOP = 1,
	END = int(-2^15-1),
}

var modcharts: Array[GDScript] = []

func dispose() -> void:
	call_mod_method("_dispose", [get_tree().current_scene])
	for mod: Script in modcharts:
		mod.unreference()
		modcharts.erase(mod)
	queue_free()

func call_mod_method(method_name: String, arguments: Array = []) -> int:
	for mod: Script in modcharts:
		if mod.has_method(method_name):
			var l = mod.callv(method_name, arguments)
			if l is int and l == CallableRequest.END:
				mod.unreference()
				modcharts.erase(mod)
				return CallableRequest.NONE
			return l if l is int else CallableRequest.NONE
	return CallableRequest.NONE

func get_scripts_at(folder: String) -> void:
	if not folder or folder.is_empty() or not DirAccess.dir_exists_absolute(folder):
		#push_warning("Cannot initialise modcharts in a unspecified or inexistant folder, for folder ", folder)
		return
	for file: String in DirAccess.get_files_at(folder):
		var f: String = file.get_file()
		if not f.get_extension() == "gd":
			continue
		print_debug(folder+"/"+f)
		var script: GDScript = load(folder+"/"+f).new()
		if script:
			script.resource_name = f.get_file()
			modcharts.append(script)
		else:
			push_error("Failed to initialise modchart script, filename: ", file, " Error: Script is null.")

static func pack_from_folders(folders: PackedStringArray) -> ModchartPack:
	var pack: ModchartPack = ModchartPack.new()
	for folder: String in folders:
		# TODO: implement "deep" folder searching (search for scripts in subfolders)
		pack.get_scripts_at(folder)
	return pack
