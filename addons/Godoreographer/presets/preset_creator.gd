@tool
class_name PresetCreator extends HBoxContainer

var presets : Array[ReusablePresetData] = []
var current_preset : ReusablePresetData:
	get():
		return presets[selected_index]
var selected_index := 0

@onready var ruler: PresetRuler = $PresetViewport/PresetRuler
@onready var display: PresetDisplay = $PresetViewport/PresetDisplay
@onready var confirmation_box := $Buttons/PresetList/ConfirmationDialog 


func _ready() -> void:
	$Buttons/SaveButton.pressed.connect(on_save_preset)
	$Buttons/BeatsInMeasureBox.value_changed.connect(change_beats_in_measure)
	$Buttons/PresetList.item_selected.connect(on_select_preset)
	confirmation_box.confirmed.connect(load_preset)

# Save Load
func on_save_preset():
	var name = $Buttons/NameEdit.text
	if name == "" :
		push_warning("Preset name cannot be blank.")
		return
	
	var beats_in_measure = $Buttons/BeatsInMeasureBox.value
	var measures = $Buttons/NumOfMeasuresBox.value
	var new_preset = ReusablePresetData.new(name, beats_in_measure, measures)
		
	presets.append(new_preset)
	refresh_preset_list()
func on_select_preset(saved_preset_index : int):
	selected_index = saved_preset_index
	confirmation_box.popup_centered()
func load_preset():
	print("Just loaded: " + str(current_preset))

func refresh_preset_list():
	var list = $Buttons/PresetList as ItemList
	list.clear()
	for preset in presets:
		list.add_item(preset.name)
	
	if list.item_count == 0:
		var item = list.add_item("Saved Presets", null, false)
		list.set_item_disabled(item, true)


func change_beats_in_measure(new_beats : int):
	ruler.beats_in_measure = new_beats
	display.beats_in_measure = new_beats
