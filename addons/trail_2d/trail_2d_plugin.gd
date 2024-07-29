@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type('Trail2D', 'Node2D', preload('trail_2d.gd'), preload("Trail2D.svg"))


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_custom_type('Trail2D')
