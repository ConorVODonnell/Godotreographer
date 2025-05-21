class_name ReusablePresetData extends Resource

@export var name : String
@export var beats_in_measure : int = 4
@export var measures : int = 1


func _init(name, beats_in_measure, measures := 1) -> void:
	self.name = name
	self.beats_in_measure = beats_in_measure
	self.measures = measures
