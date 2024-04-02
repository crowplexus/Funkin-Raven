class_name SparrowConverter extends Control


var use_offsets: bool = true
var animations_looped: bool = false
var animation_framerate: int = 24
var source_file: String = ''

@onready var file: Label = $panel/file


func _set_offsets(value: bool) -> void:
	use_offsets = value


func _set_looped(value: bool) -> void:
	animations_looped = value


func _set_framerate(value: int) -> void:
	animation_framerate = value


func _set_file(value: String) -> void:
	source_file = value
	file.text = source_file.replace('res://', '')


func _import() -> Error:
	if not FileAccess.file_exists(source_file):
		print('File not found at path "%s"!' % source_file)
		return ERR_FILE_NOT_FOUND
	
	var xml: XMLParser = XMLParser.new()
	xml.open(source_file)
	
	var sprite_frames: SpriteFrames = SpriteFrames.new()
	sprite_frames.remove_animation('default')
	
	var texture = null
	var image: Image
	var image_texture: ImageTexture
	
	# This is done to prevent reuse of atlas textures.
	# The actual difference this makes may be unnoticable but it is still done.
	var sparrow_frames: Array = []
	
	var options: Dictionary = {
		'use_offsets': use_offsets,
		'animations_looped': animations_looped,
		'animation_framerate': animation_framerate,
	}
	
	while xml.read() == OK:
		if xml.get_node_type() != XMLParser.NODE_ELEMENT:
			continue
		
		var node_name: String = xml.get_node_name().to_lower()
		
		if node_name == 'textureatlas':
			var image_name: StringName = xml.get_named_attribute_value_safe('imagePath')
			var image_path: String = '%s/%s' % [source_file.get_base_dir(), image_name]
			
			if not FileAccess.file_exists(image_path):
				print('Image not found at imagePath (%s)!' % image_name)
				return ERR_FILE_NOT_FOUND
			
			texture = ResourceLoader.load(image_path, 'CompressedTexture2D', ResourceLoader.CACHE_MODE_IGNORE)
			continue
		
		if node_name != 'subtexture':
			continue
		
		# Couldn't find texture from imagePath in TextureAtlas.
		if texture == null:
			return ERR_FILE_MISSING_DEPENDENCIES

		var frame = SparrowFrame.new()
		frame.name = xml.get_named_attribute_value_safe('name')

		if frame.name == '':
			continue

		frame.source = Rect2i(
			Vector2i(xml.get_named_attribute_value_safe('x').to_int(),
					xml.get_named_attribute_value_safe('y').to_int(),),
			Vector2i(xml.get_named_attribute_value_safe('width').to_int(),
					xml.get_named_attribute_value_safe('height').to_int(),),)
		frame.offsets = Rect2i(
			Vector2i(xml.get_named_attribute_value_safe('frameX').to_int(),
					xml.get_named_attribute_value_safe('frameY').to_int(),),
			Vector2i(xml.get_named_attribute_value_safe('frameWidth').to_int(),
					xml.get_named_attribute_value_safe('frameHeight').to_int(),),)
		frame.has_offsets = xml.has_attribute('frameX') and options.get('use_offsets', true)

		var frame_data: Array = _get_frame_name_and_number(frame)
		
		for sparrow_frame in sparrow_frames:
			if sparrow_frame.source == frame.source and \
					sparrow_frame.offsets == frame.offsets:
				frame.atlas = sparrow_frame.atlas
				break

		# Unique new frame! Awesome.
		if frame.atlas == null:
			frame.atlas = AtlasTexture.new()
			
			var rotated: bool = xml.get_named_attribute_value_safe('rotated') == 'true'
			
			# Just used to not have to reference frame 24/7.
			var atlas: AtlasTexture = frame.atlas
			
			if rotated:
				if not (image and image_texture):
					image = texture.get_image()
					image.decompress()
					image_texture = ImageTexture.create_from_image(image)
				
				atlas.atlas = image_texture
			else:
				# allow for cool compression savings! :3
				atlas.atlas = texture
			
			atlas.filter_clip = true
			atlas.region = frame.source
			
			var margin: Rect2i = Rect2i(-1, -1, -1, -1)
			
			if frame.has_offsets:
				if frame.offsets.size == Vector2i.ZERO:
					frame.offsets.size = frame.source.size
				
				# Once again just not referencing frame constantly.
				var source: Rect2i = frame.source
				var offsets: Rect2i = frame.offsets
				
				margin = Rect2i(
					-offsets.position.x, -offsets.position.y,
					offsets.size.x - source.size.x, offsets.size.y - source.size.y)
				
				margin.size = margin.size.clamp(margin.position.abs(), Vector2i.MAX)
				atlas.margin = margin
			
			if rotated:
				var atlas_image: Image = atlas.get_image()
				atlas_image.rotate_90(COUNTERCLOCKWISE)
				
				var atlas_texture: ImageTexture = ImageTexture.create_from_image(atlas_image)

				if margin != Rect2i(-1, -1, -1, -1):
					# source is based on the frame, not the whole texture.
					# This is because rotating the image messes with the offests,
					# so we just recalculate the margins basically.
					# :]
					var source: Rect2i = Rect2(Vector2.ZERO, atlas_texture.get_size())
					var offsets: Rect2i = frame.offsets

					atlas = AtlasTexture.new()
					atlas.atlas = atlas_texture
					atlas.region = source

					margin = Rect2i(
						-offsets.position.x, -offsets.position.y,
						offsets.size.x - source.size.x, offsets.size.y - source.size.y)
					
					atlas.margin = margin
					frame.atlas = atlas
				else:
					frame.atlas = atlas_texture
		
		frame.animation = frame_data[1]
		
		if not sprite_frames.has_animation(frame.animation):
			sprite_frames.add_animation(frame.animation)
			sprite_frames.set_animation_loop(frame.animation, options.get('animations_looped', false))
			sprite_frames.set_animation_speed(frame.animation, options.get('animation_framerate', 24))
		
		sparrow_frames.push_back(frame)
	
	sparrow_frames.sort_custom(_sort_frames)

	for frame in sparrow_frames:
		sprite_frames.add_frame(frame.animation, frame.atlas)

	var filename: StringName = &'%s.res' % [source_file.get_basename()]
	return ResourceSaver.save(sprite_frames, filename, ResourceSaver.FLAG_COMPRESS)


func _get_frame_name_and_number(frame) -> Array:
	var frame_number: StringName = frame.name.right(4)
	var animation_name: StringName = frame.name.left(frame.name.length() - 4)
	
	# By default we support animations with name0000, name0001, etc.
	# We should still allow other sprites to be exported properly however.
	if not frame_number.is_valid_int():
		animation_name = frame.name
	
	return [frame_number.to_int() if frame_number.is_valid_int() else -1, animation_name]


func _sort_frames(a_frame, b_frame) -> bool:
	var a: Array = _get_frame_name_and_number(a_frame)
	var b: Array = _get_frame_name_and_number(b_frame)
	return a[0] < b[0]
