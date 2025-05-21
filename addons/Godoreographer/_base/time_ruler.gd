@tool
extends Control
class_name TimeRuler

var visible_start = 0.0
var range := 10.0
var range_index := 1:
	set(value):
		# clamps within the array it indexes for
		range_index = clampi(value, 0, draw_frequency.size() - 1)		
		queue_redraw()
## The first num is the range. Used for reference, since var range is set directly by waveform_display.
## The others are frequesncies. "draw ___ every x seconds"
## [range, line, number, is line color highlight]
var draw_frequency = [[5.0, 1, 1, 1], [10.0, 1, 1, 2], [15.0, 1, 1, 5], 
	[30.0, 1, 5, 5], [60.0, 5, 5, 10], [120.0, 10, 10, 30], [INF, 30, 30, 30]]


func _draw() -> void:
	draw_foundation()
	var width = size.x
	var seconds_per_pixel = range / width
	var pixels_per_second = width / range
	var tick_interval = pick_tick_interval(seconds_per_pixel)
	
	var start_time = ceil(visible_start / tick_interval) * tick_interval
	var end_time = start_time + range
	
	# */ by 100 else I forget
	# I think if you don't, the t(ime) var gets rounded off, or truncated?
	for t in range(start_time * 100, end_time * 100, tick_interval * 100):
		t /= 100
		var start_to_tick = t - visible_start
		if start_to_tick < 0: continue
		var x = start_to_tick * pixels_per_second
		
		draw_line_and_number(x, round(t))


# Helpers
func draw_foundation():
	draw_rect(Rect2(Vector2.ZERO, size), get_theme_color("background"))
	draw_line(Vector2(0, size.y), size, get_theme_color("support"))
func pick_tick_interval(seconds_per_pixel : float):
	if seconds_per_pixel > 1.0: return 5.0 # 120+
	if seconds_per_pixel > 0.2: return 1.0 # 60 : 0.75, 30 : 0.375
	if seconds_per_pixel > 0.05: return 0.2 # 15: 0.1875, 10 : 0.125, 5 : 0.0625, 
	if seconds_per_pixel > 0.01: return 0.05 
	return 0.01
func draw_line_and_number(x, t : int):
	# x is the horizontal distance from the left of the ruler
	# t is time, in seconds, at that point
	# Used to be 2 lines that drew a line, and the number.
	# Added all this other work to highlight specific lines, and only show
	# specific numbers. Defined by draw_frequency, for each zoom range
	var is_draw_line = t % draw_frequency[range_index][1] == 0
	var is_num = t % draw_frequency[range_index][2] == 0
	var is_highlight = t % draw_frequency[range_index][3] == 0
	var num_x = x + 2
	# Get length of num string, else num will appear off right side of ruler
	var num_length = get_theme_font("font").get_string_size(str(t), 0, -1, get_theme_font_size("font_size")).x
	var is_draw_number = num_x + num_length < size.x and is_num
	if is_draw_line: 
		var line_color = get_theme_color("highlight") if is_highlight else get_theme_color("support")
		draw_line(Vector2(x, 0), Vector2(x, size.y), line_color, 1.0)
	if is_draw_number: draw_string(get_theme_font("font"), Vector2(x + 2, size.y - 4), str(t),
	 HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_font_size("font_size"), get_theme_color("font"))
