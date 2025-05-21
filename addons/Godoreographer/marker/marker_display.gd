@tool
extends Control
class_name MarkerDisplay

signal added_marker
signal removed_marker

var display_position : Callable
var create_marker : Callable

var markers
var selected_marker


func draw_marker(marker : MarkerData, color := marker.color, thickness := 2.0):
	var x = display_position.call(marker)
	if x >= 0 and x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), color, thickness)

func handle_right_mouse(event):
	selected_marker = null
	
	var marker_to_delete = get_marker_near(event.position.x)
	if marker_to_delete:	markers.erase(marker_to_delete)
func get_marker_near(x: float, threshold := 10) -> MarkerData:
	for marker in markers:
		if abs(display_position.call(marker) - x) < threshold:
			return marker
	return null
