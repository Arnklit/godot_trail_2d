@tool
extends EditorPlugin

const Trail2D = preload("trail_2d.gd")

func _enter_tree() -> void:
	add_custom_type('Trail2D', 'Node2D', preload('trail_2d.gd'), preload("Trail2D.svg"))


#func _on_selection_change() -> void:
	#_editor_selection = get_editor_interface().get_selection()
	#var selected = _editor_selection.get_selected_nodes()
	#
	#_edited_node = selected[0]




func _forward_canvas_gui_input(event):
	var selected_trail_2d: Trail2D = get_editor_interface().get_selection().get_selected_nodes()[0]

	if event is InputEventKey:
		if event.key_label == KEY_J and event.pressed == false:
			selected_trail_2d.paused = not selected_trail_2d.paused


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_custom_type('Trail2D')


func _handles(node):
	return node is Trail2D
