@tool
extends Control
class_name WaveformDisplay

signal seek_requested(time: float)

## Waveform Calculation
var current_waveform : PackedFloat32Array = []
var waveform_levels : Array[PackedFloat32Array] = []
var samples_per_second_needed := 80.0

## Markers
#@onready var marker_display: MarkerDisplay = $MarkerDisplay
var markers : Array[MarkerData] = []:
	set(value):
		markers = value
		markers.sort_custom(func(a, b): return a.get_time() < b.get_time())
const MarkerData = preload("res://addons/Godoreographer/marker/marker_data.gd")
# marker selection
var selected_marker : MarkerData = null:
	set(value):
		selected_marker = value
		var dropdown = $"../SelectedMarkerContainer/MarkerTypeDropdown" as OptionButton
		if selected_marker:
			dropdown.visible = true
			dropdown.select(selected_marker.type_index)
		else:
			dropdown.visible = false

## Song info
var song_length : float = 60.0  # seconds
var seconds_per_pixel : float

## Display
var visible_start : float  = 0.0:  # time scroll position (in seconds)
	set(value):
		visible_start = clampf(value, 0.0, song_length - range)
		queue_redraw()
		update_ruler()
# Amount of time displayed, as range
var max_range_out := false
var range_index := 1: # start at 10
	set(value):
		# clamps within the array it indexes for
		range_index = clampi(value, 0, possible_ranges.size() - 1)
		range = possible_ranges[range_index]
		if song_length <= possible_ranges[range_index]:
				max_range_out = true
# seconds visible at once
var possible_ranges : PackedFloat32Array = [5.0, 10.0, 15.0, 30.0, 60.0, 120.0, INF]
var range : float :
	set(value):
		range = value
		range = clampf(value, 0.1, song_length)
		var display_text = "Range: " + str(int(range)) + " sec"
		if range == song_length:
			display_text = "Range: ~" + str(int(range)) + " sec"
		$"../InfoHBox/RangeLabel".text = display_text
		seconds_per_pixel = range / size.x
		
		visible_start = visible_start # refresh
		update_ruler()
		#update_marker_display()

var playhead_time := 0.0: # seconds
	set(value):
		playhead_time = value
		queue_redraw()

## Mouse Controls
var is_seeking
var is_panning := false
var drag_origin : float
var predrag_visible_start : float

var threshold_pixels_away := 8
var click_threshold :
	get():
		return threshold_pixels_away * seconds_per_pixel

@onready var time_ruler: TimeRuler = $"../TimeRuler" as TimeRuler


func _ready() -> void:
	var dropdown = $"../SelectedMarkerContainer/MarkerTypeDropdown" as OptionButton
	dropdown.clear()
	for i in MarkerData.Types.size():
		dropdown.add_item(MarkerData.Types.keys()[i])
		dropdown.set_item_text(i, MarkerData.Types.keys()[i])
	dropdown.item_selected.connect(func(index):
		selected_marker.type_index = index)

func _gui_input(event: InputEvent) -> void:
	# Click
	if event is InputEventMouseButton: 
		match event.button_index:
			MOUSE_BUTTON_LEFT: handle_left_mouse(event)
			MOUSE_BUTTON_MIDDLE: handle_middle_mouse(event)
			MOUSE_BUTTON_RIGHT: handle_right_mouse(event)
		queue_redraw()
	# Mouse Drag
	elif event is InputEventMouseMotion:
		handle_mouse_motion(event)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), get_theme_color("background"))
	if current_waveform.is_empty(): return
	
	draw_waveform()
	draw_playhead()
	for marker in markers:
		draw_marker(marker)
	if selected_marker:
		draw_marker(selected_marker, Color.ORANGE_RED, 4)


## Waveform
func set_waveform(_full_waveform : PackedFloat32Array, _song_length_sec):
	song_length = _song_length_sec
	
	reset_to_zero()
	
	generate_waveform_levels(_full_waveform)
	current_waveform = pick_best_level()
	samples_per_second_needed = current_waveform.size() / song_length
	queue_redraw()
func reset_to_zero():
	## Some things to refresh or init, every time you change song
	## Refreshing these calls their setters, which ensures
	## everything is clamped correctly
	range_index = 1		#Set to 1 to be a little zoomed out. Could be 0 to cover <5 second songs
	visible_start = 0.0

func generate_waveform_levels(base_waveform : PackedFloat32Array, max_levels := 8):
	waveform_levels.clear()
	waveform_levels.append(base_waveform)
	
	var current = base_waveform
	
	for i in max_levels:
		var next_level_size = current.size() / 2
		if next_level_size <= 1 : break
		
		var downsampled = downsample(current, int(next_level_size))
		waveform_levels.append(downsampled)
		current = downsampled
func downsample(samples : PackedFloat32Array, target_samples_per_song : int) -> PackedFloat32Array:
	var result = PackedFloat32Array()
	result.resize(target_samples_per_song)
	
	var chunk_size = samples.size() / target_samples_per_song
	
	for i in target_samples_per_song:
		var start = int(i * chunk_size)
		var end = int((i + 1) * chunk_size)
		
		var sum := 0.0
		var count := 0.0
		
		for j in range(start, end):
			if j >= samples.size():
				break
			sum += samples[j]
			count += 1
		
		result[i] = sum / count if (count > 0) else 0.0
	
	
	return result


## Input help
func handle_left_mouse(event):      #  Place Marker   #   +Shift Seeks
	is_seeking = false
	if not event.pressed: return
	
	var clicked_time = display_to_time(event.position.x)
	#  Seeks
	if event.ctrl_pressed:
		is_seeking = true
		seek_requested.emit(clicked_time)
	
	#  Places Marker
	elif event.shift_pressed:
		add_marker(clicked_time)
	
	#  Select Marker
	else:
		var selected = get_marker_near(event.position.x)
		
		if selected:	selected_marker = selected
		else: 			add_marker(clicked_time)
func handle_middle_mouse(event):    #  Panning
	if event.button_index == MOUSE_BUTTON_MIDDLE:
		if event.pressed:  # Begin pan
			is_panning = true
			drag_origin = event.position.x
			predrag_visible_start = visible_start
		else:  # End pan
			is_panning = false 
func handle_right_mouse(event):     #  Delete Marker
	selected_marker = null
	
	var marker_to_delete = get_marker_near(event.position.x)
	if marker_to_delete:	markers.erase(marker_to_delete)
func handle_mouse_motion(event):    #  Click and drag
	# Middle mouse down?
	if is_panning :
		var drag_delta = event.position.x - drag_origin
		visible_start = predrag_visible_start - (drag_delta * seconds_per_pixel)
	
	# Left mouse down?
	elif is_seeking:
		var clicked_time = visible_start + (event.position.x * seconds_per_pixel)
		seek_requested.emit(clicked_time) 

# Helper
func get_marker_near(x: float, threshold := 10) -> MarkerData:
	for marker in markers:
		if abs(display_position(marker) - x) < threshold:
			return marker
	return null
func display_position(marker : MarkerData) -> float:
	return time_to_display(marker.get_time())
func time_to_display(time) -> float:
	var x = (time - visible_start) / seconds_per_pixel
	return x 
func display_to_time(x) -> float:
	var time = visible_start + (x * seconds_per_pixel)
	return time


## Marker generation
func add_marker(time : float):
	var m := MarkerData.new(time)
	markers.append(m)
func create_marker(x : float) -> MarkerData:
	var m = MarkerData.new(display_to_time(x))
	return m


## Draw help
func draw_waveform():
	var half_height = size.y / 2.0
	
	var start_sample = int(visible_start * samples_per_second_needed)
	var end_sample = int((visible_start + range) * samples_per_second_needed)
	
	start_sample = clamp(start_sample, 0 ,current_waveform.size())
	end_sample = clamp(end_sample, 0, current_waveform.size())
	
	var visible_sample_range = end_sample - start_sample
	if visible_sample_range <= 0: return
	
	var spacing = size.x / float(visible_sample_range)
	
	for i in visible_sample_range:
		var sample_index = start_sample + i
		var x = i * spacing
		var amp = current_waveform[sample_index] * half_height
		draw_line(Vector2(x, half_height - amp), Vector2(x, half_height + amp), get_theme_color("sample"), 1.0)
func draw_playhead():
	var visible_end = visible_start + range
	
	if playhead_time >= visible_start and playhead_time <= visible_end:
		var playhead_scale = (playhead_time - visible_start) / range
		var playhead_position = playhead_scale * size.x
		draw_line(Vector2(playhead_position, 0), Vector2(playhead_position, size.y), get_theme_color("playhead"), 1.5)
func draw_marker(marker : MarkerData, color := marker.color, thickness := 2.0):
	var x = display_position(marker)
	if x >= 0 and x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), color, thickness)


## Zoom process
func zoom_player_display(zoom_in : bool):
	if zoom_in:
		range_index -= 1
		max_range_out = false
	elif not max_range_out: # zoom out, if not all the way
		range_index += 1
func pick_best_level() -> PackedFloat32Array:
	if waveform_levels.is_empty(): return PackedFloat32Array()
	
	var total_samples_on_screen = size.x
	samples_per_second_needed = total_samples_on_screen / range
	
	for i in waveform_levels.size():
		var level = waveform_levels[i]
		var level_sample_rate = level.size() / song_length
		
		if level_sample_rate <= samples_per_second_needed:
			return level
	
	# Fallback, return last level
	return waveform_levels[-1]


## External Updates
func update_ruler():
	time_ruler.visible_start = visible_start
	time_ruler.range_index = range_index
	time_ruler.range = range
	time_ruler.queue_redraw()
