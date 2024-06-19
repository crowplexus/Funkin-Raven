extends PreferenceBar

var _lang_codes: PackedStringArray = []


func _ready() -> void:
	display_names.clear()
	_lang_codes.append_array(TranslationServer.get_loaded_locales())
	value = _lang_codes[_lang_codes.find(Preferences.language)]
	for code: String in _lang_codes:
		var cn: = TranslationServer.get_locale_name(code)
		# format language name
		var cn_split: = cn.split(", ")
		match cn_split[1]: # shorten names
			"United States of America": cn_split[1] = "United States"

		var cn_trans: = [
			tr("LANG_%s" % cn_split[0].to_snake_case().to_upper()),
			tr("COUNTRY_%s" % cn_split[1].to_snake_case().to_upper())]
		if not cn_trans[0].begins_with("LANG_"):
			cn_split[0] = cn_trans[0]
		if not cn_trans[1].begins_with("COUNTRY_"):
			cn_split[1] = cn_trans[1]

		display_names.append("%s (%s)" % [ cn_split[0], cn_split[1] ])
	update()


func update(amount: int=0) -> void:
	if option_type != 2:
		if amount == 0: check_value()
		else: super(amount)
	else:
		if not (value is String or value is StringName):
			return

		var current_val: int = _lang_codes.find(value)
		var next_value: int = wrapi(current_val + amount, 0, _lang_codes.size())
		_force_name = display_names[next_value]
		Preferences.set(variable, _lang_codes[next_value])
		check_value()
