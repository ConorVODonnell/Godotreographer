@tool
class_name PresetRuler extends Control

var beats_in_measure := 4:
	set(value):
		beats_in_measure = value
		queue_redraw()
var measures := 1
var buffer := 10 # pixel buffer before start and end of display

func _draw() -> void:
	draw_foundation()
	
	var total_numbers = beats_in_measure * measures
	# 1 Buffer before + 2 after = 3
	var display_size = size.x - (3 * buffer)
	var distance_between_lines = display_size / total_numbers
	
	for i in total_numbers:
		var x = i * distance_between_lines + buffer
		draw_line(Vector2(x, 0), Vector2(x, size.y), get_theme_color("highlight"))
		draw_string(get_theme_font("font"), Vector2(x + 2, size.y - 4), str(i + 1),
			HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_font_size("font_size"), get_theme_color("font"))
	
	var next_measure_x = total_numbers * distance_between_lines + buffer - 5
	draw_string(get_theme_font("font"), Vector2(next_measure_x, size.y - 4), str(1),
			HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_font_size("font_size"), Color(Color.INDIAN_RED, 0.5))


func draw_foundation():
	draw_rect(Rect2(Vector2.ZERO, size), get_theme_color("background"))
	draw_line(Vector2(buffer, size.y), Vector2(size.x - (2 * buffer), size.y), get_theme_color("support"))
