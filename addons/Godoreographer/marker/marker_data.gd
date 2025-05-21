extends RefCounted
class_name MarkerData

var time : float
var percent_preset : float		# What percent through a preset, if any. range (0, 1]
var label : String = ""
var type_index := Types.GENERIC:
	set(value):
		type_index = value
		type = Types.keys()[type_index]
		type.to_pascal_case()
var type : String = Types.keys()[Types.GENERIC]
var color := Color.ORANGE


func get_time(display_length := 1.0, preset_start := 0.0) -> float:
	return (time + preset_start) + (display_length * percent_preset)


enum Types{
	GENERIC,
	BEAT,
	CUE,
}

func _init(time: float, percent_preset := 0.0, label := "", type : String = "generic"):
	self.time = time
	self.percent_preset = percent_preset
	self.label = label
	self.type = type
