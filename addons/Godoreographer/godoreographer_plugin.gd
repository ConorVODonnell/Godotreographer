@tool
extends EditorPlugin

var dock


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	dock = preload("res://addons/Godoreographer/_base/godoreographer.tscn").instantiate()
	add_control_to_bottom_panel(dock, "Godoreographer")
	make_bottom_panel_item_visible(dock)


func _exit_tree() -> void:
	remove_control_from_bottom_panel(dock)
	var history_id = get_undo_redo().get_object_history_id(dock)
	get_undo_redo().clear_history(history_id)
	
	dock.queue_free()
