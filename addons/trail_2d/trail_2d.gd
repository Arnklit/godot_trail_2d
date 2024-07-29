@tool
extends Node2D
## A 2D trail that generates from a point.

const noise_texture: Texture2D = preload("trail_2d_noise.png")

## If [code]true[/code], points are being emitted.
@export var emitting := true: set = set_emitting
## Amount of time each point will exist.
@export var life_time := 1.0
## The distance between each point.
@export_range(0.0, 1000.0, 0.01, "suffix:px", "or_greater", "hide_slider") var segment_length := 20.0
## The polyline's width.
@export_range(0.0, 1000.0, 0.01, "suffix:px", "or_greater", "hide_slider") var width := 10.0: set = set_width
## The polyline's width curve. The width of the polyline over its length will be equivalent to the value of the width curve over its domain.
@export var width_curve: Curve: set = set_width_curve
## The color of the polyline. Will not be used if a gradient is set.
@export var default_color := Color.WHITE: set = set_default_color

@export_group("Noise")
## The amount of noise displacement
@export_range(0.0, 800.0, 0.01, "or_greater") var noise_amount := 50.0
## The displacement amount curve, mapped over lifetime of the point.
@export var noise_amount_curve: Curve
## Frequency of the displacement noise.
@export var noise_frequency := 1.0

@export_group("Fill")
## The gradient is drawn through the whole line from start to finish. The [member default_color] will not be used if this property is set.
@export var gradient: Gradient: set = set_gradient
## The texture used for the polyline. Uses [member texture_mode] for drawing style.
@export var texture: Texture2D: set = set_texture
## The style to render the [member texture] of the polyline. Use [enum LineTextureMode] constants.
@export_enum("None", "Tile", "Stretch") var texture_mode := 0: set = set_texture_mode

@export_group("Capping")
## The style of the connections between segments of the polyline. Use [enum LineJointMode] constants.
@export_enum("Sharp", "Bevel", "Round") var joint_mode := 0: set = set_joint_mode
## The style of the beginning of the polyline, if [member closed] is [code]false[/code]. Use [enum LineCapMode] constants.
@export_enum("None", "Box", "Round") var begin_cap_mode := 0: set = set_begin_cap_mode
## The style of the end of the polyline, if [member closed] is [code]false[/code]. Use [enum LineCapMode] constants.
@export_enum("None", "Box", "Round") var end_cap_mode := 0: set = set_end_cap_mode

@export_group("Border")
## Determines the miter limit of the polyline. Normally, when [member joint_mode] is set to [constant LINE_JOINT_SHARP], sharp angles fall back to using the logic of [constant LINE_JOINT_BEVEL] joints to prevent very long miters. Higher values of this property mean that the fallback to a bevel joint will happen at sharper angles.
@export var sharp_limit := 2.0: set = set_sharp_limit
## The smoothness used for rounded joints and caps. Higher values result in smoother corners, but are more demanding to render and update.
@export var round_precision := 8: set = set_round_precision
## If [code]true[/code], the polyline's border will be anti-aliased.
## [b]Note:[/b] [Line2D] is not accelerated by batching when being anti-aliased.
@export var antialiased := false: set = set_antialised

# Private Variables
var _last_point: Vector2
var _points := PackedVector2Array()
var _age_array := PackedFloat32Array()
var _noise_array := PackedVector2Array()
var _line2d : Line2D
var _noise_sample_point := 0.0
var _first_enter_tree := true
var _noise_image : Image


func set_emitting(value: bool) -> void:
	emitting = value
	if value:
		_points = PackedVector2Array()
		_age_array = PackedFloat32Array()
		_noise_array = PackedVector2Array()


func set_width(value: float) -> void:
	width = value
	if _first_enter_tree:
		return
	_line2d.width = value


func set_width_curve(value: Curve) -> void:
	width_curve = value
	if _first_enter_tree:
		return
	_line2d.width_curve = value


func set_default_color(value: Color) -> void:
	default_color = value
	if _first_enter_tree:
		return
	_line2d.default_color = value


func set_gradient(value: Gradient) -> void:
	gradient = value
	if _first_enter_tree:
		return
	_line2d.gradient = value


func set_texture(value: Texture2D) -> void:
	texture = value
	if _first_enter_tree:
		return
	_line2d.texture = value


func set_texture_mode(value: int) -> void:
	texture_mode = value
	if _first_enter_tree:
		return
	_line2d.texture_mode = value


func set_joint_mode(value: int) -> void:
	joint_mode = value
	if _first_enter_tree:
		return
	_line2d.joint_mode = value


func set_begin_cap_mode(value: int) -> void:
	begin_cap_mode = value
	if _first_enter_tree:
		return
	_line2d.begin_cap_mode = value


func set_end_cap_mode(value: int) -> void:
	end_cap_mode = value
	if _first_enter_tree:
		return
	_line2d.end_cap_mode = value


func set_sharp_limit(value: float) -> void:
	sharp_limit = value
	if _first_enter_tree:
		return
	_line2d.sharp_limit = value


func set_round_precision(value: int) -> void:
	round_precision = value
	if _first_enter_tree:
		return
	_line2d.round_precision = value


func set_antialised(value: bool) -> void:
	antialiased = value
	if _first_enter_tree:
		return
	_line2d.antialiased = value


func _enter_tree():
	_last_point = global_position
	if Engine.is_editor_hint() and _first_enter_tree:
		_first_enter_tree = false
	
	_noise_image = noise_texture.get_image()
	
	_line2d = Line2D.new()
	add_child(_line2d)
	_line2d.use_parent_material = true
	_line2d.width = width
	_line2d.width_curve = width_curve
	_line2d.default_color = default_color
	_line2d.gradient = gradient
	_line2d.texture = texture
	_line2d.texture_mode = texture_mode
	_line2d.joint_mode = joint_mode
	_line2d.begin_cap_mode = begin_cap_mode
	_line2d.end_cap_mode = end_cap_mode
	_line2d.sharp_limit = sharp_limit
	_line2d.round_precision = round_precision
	_line2d.antialiased = antialiased


func _process(delta):
	# The Line 2D child used for drawing the trail has it's transform zeroed every frame.
	# This is used rather than using top_level so overriding materisl properties still works.
	_line2d.global_transform = Transform2D.IDENTITY
	
	if _last_point.distance_to(global_position) > segment_length and emitting:
		_noise_sample_point += segment_length
		
		_points.insert(0, global_position)
		_age_array.insert(0, life_time)
		var noise_color_1 := _noise_image.get_pixel(wrap(floor(_noise_sample_point) * noise_frequency, 0.0, 512.0), 0)
		# Bilinear Sampling
		#var noise_color_2 := _noise_image.get_pixel(wrap(ceil(_noise_sample_point) * noise_frequency, 0.0, 512.0), 0)
		#var col_mix = noise_color_1.lerp(noise_color_2, fmod(_noise_sample_point, 1.0))
		_noise_array.insert(0, Vector2(noise_color_1.r, noise_color_1.g) - Vector2(0.5, 0.5))
		_last_point = global_position
 	
	var idx := 0
	while idx < _age_array.size():
		_age_array[idx] -= delta
		if _age_array[idx] < 0.0:
			_age_array.remove_at(idx)
			_points.remove_at(idx)
			_noise_array.remove_at(idx)
		idx += 1
	
	_line2d.points = _points
	
	for i in _line2d.get_point_count():
		var n_sample = 1.0 if noise_amount_curve == null else noise_amount_curve.sample(1.0 - (_age_array[i] / life_time))
		_line2d.points[i] += _noise_array[i] * noise_amount * n_sample
	
	# This ensures there always is a temporary point close to the emitter to avoid stuttering
	if _last_point.distance_to(global_position) > min(segment_length, 5.0) and emitting:
		_line2d.add_point(global_position, 0)
