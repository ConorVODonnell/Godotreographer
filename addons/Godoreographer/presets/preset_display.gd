@tool
class_name PresetDisplay extends Control

var beats_in_measure := 4:
	set(value):
		beats_in_measure = value
		queue_redraw()
# For every beat in measure, there are subdivision lines, and multiple as many snap lines.
# One on the beat, one on each subdivision, and one between each beat and/or subdivision
# Represets the "On" beat, the "off" beat, and most breakdowns between
# This should cover use cases. And people can post markers freely, otherwise
var subdivisions : int:
	get():
		if triplet_sub_div: return 6
		else: return 4
# Is the beat subdivided in half, or into triplets
var triplet_sub_div := false
var snaps_per_measure:
	get():
		return beats_in_measure * subdivisions
var snap_positions : PackedFloat32Array
var x_between_snaps
var measures:= 1
var zoom := 1
var marker_width := -1 # pixels

## Markers
var markers : Array[MarkerData]:
	set(value):
		markers = value
		markers.sort_custom(func(a, b): return a.get_time() < b.get_time())
var selected_marker : MarkerData

var display_size:
	get():
		return size.x - total_buffer

# else beat 1 is on far left edge
# pixels buffer before Measure 1 Beat 1, and after the end of the final Beat
var buffer = 10 
var back_buffer:
	get():
		return 2 * buffer
var total_buffer:
	get():
	# 1 Buffer before + 2 after = 3 buffers
		return 3 * buffer


func _gui_input(event: InputEvent) -> void:
	# Click
	if event is InputEventMouseButton:
		if not event.pressed: return
		match event.button_index:
			MOUSE_BUTTON_LEFT: handle_left_mouse(event)
			MOUSE_BUTTON_RIGHT: handle_right_mouse(event)
		queue_redraw()

func _draw() -> void:
	determine_snap_line_positions()
	draw_background()
	draw_beat_lines()
	
	for marker in markers:
		draw_marker(marker)
	if selected_marker:
		draw_marker(selected_marker, Color.ORANGE_RED, 4)
	
	draw_following_measure_line()


## Input
func handle_left_mouse(event):	
	var clicked_beat_as_percent = nearest_snap_as_percent(event.position.x)
	#  Places Marker
	if event.shift_pressed:
		add_marker(clicked_beat_as_percent)
	
	#  Select Marker
	else:
		var selected = get_marker_near(event.position.x)
		
		if selected:	selected_marker = selected
		else: 			add_marker(clicked_beat_as_percent)
func handle_right_mouse(event):
	selected_marker = null
	
	var marker_to_delete = get_marker_near(event.position.x)
	if marker_to_delete:	markers.erase(marker_to_delete)


## Snap Lines
func determine_snap_line_positions():
	snap_positions.clear()
	
	var total_snaps = snaps_per_measure * measures
	x_between_snaps = display_size / total_snaps
	
	for i in total_snaps:
		var x = i * x_between_snaps + buffer
		snap_positions.append(x)
func get_nearest_snap_index(x : float) -> int:
	var prev_i = 0
	var prev_dist = INF
	for i in snap_positions.size():
		var dist = absf(x - snap_positions[i])
		
		if prev_dist > dist:
			prev_dist = absf(x - snap_positions[i])
			prev_i = i
		else:
			break
		
	return prev_i
func nearest_snap_as_percent(x : float) -> float:
	var prev_i = 0
	var prev_dist = INF
	for i in snap_positions.size():
		var dist = absf(x - snap_positions[i])
		
		if prev_dist > dist:
			prev_dist = absf(x - snap_positions[i])
			prev_i = i
		else:
			break
	
	return float(prev_i) / float(snap_positions.size())

## Drawers
func draw_background():
	draw_rect(Rect2(Vector2.ZERO, size), get_theme_color("background"))
func draw_beat_lines():
	# When to draw a beat line
	var beat_line = subdivisions
	var sub_line := 2
	
	for i in snap_positions.size() - 1:
		var color
		var is_on_beat = i % beat_line == 0
		var is_sub_div_line = i % sub_line == 0
		
		if is_on_beat:
			color = get_theme_color("on_beat")
		elif is_sub_div_line:
			color = get_theme_color("off_beat")
		else:
			continue
		
		var x = snap_positions[i]
		draw_line(Vector2(x, 0), Vector2(x, size.y), color, marker_width)
func draw_marker(marker : MarkerData, color := marker.color, thickness := 2.0):
	var x = display_position(marker)
	if x >= 0 and x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), color, thickness)
#Draw red line to indicate beat 1 of next measure. Recommended you do not place markers here
func draw_following_measure_line():
	var line_x = size.x - (2 * buffer)
	var next_line_color := Color.INDIAN_RED
	draw_line(Vector2(line_x, 0), Vector2(line_x, size.y), next_line_color, marker_width)
	
	
	var next_text := "Next Measure Beat 1"
		# I'll be honest, I can't fully wrap my mind around how this works but it works
		# draw_set_transform() applies a transform to everything drawn after it
		# So I think it's just some matrix multiplication or something that I don't know about 
	
		# Use (position.x, 0) instead of just position, else it adds an
		# unwanted PresetRuler.size.y to drawn string position.y
	draw_set_transform(Vector2(position.x, 0), PI / 2)
	var string_size_pixels = get_theme_font("font").get_string_size(next_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12).x
	var next_text_y = (size.y - string_size_pixels) / 2
		# For some reason, x and y switch for the position
		# next_text_position.y (the x coord) needs to be negative
	var next_text_position := Vector2(next_text_y, - (line_x + 6))
	draw_string(get_theme_font("font"), next_text_position, next_text,
		HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(next_line_color, 0.5))


## Markers
func create_marker(x : float) -> MarkerData:
	var m = MarkerData.new(0, nearest_snap_as_percent(x))
	return m
func add_marker(percent_preset : float):
	var m := MarkerData.new(0, percent_preset)
	markers.append(m)
func get_marker_near(x: float, threshold := 10) -> MarkerData:
	for marker in markers:
		if abs(display_position(marker) - x) < threshold:
			return marker
	return null
func display_position(marker : MarkerData) -> float:
	return marker.get_time(display_size) + buffer
