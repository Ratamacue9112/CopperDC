@tool
extends EditorPlugin

var dock

func _enter_tree():
	# Set up editor window
	dock = preload("res://addons/copper_dc/dc_editor_window.tscn").instantiate()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UR, dock)
	
	# Add autoloads
	add_autoload_singleton("debug_console", "res://addons/copper_dc/debug_console.tscn")

func _exit_tree():
	# Remove editor window
	remove_control_from_docks(dock)
	dock.free()

	# Remove autoloads
	remove_autoload_singleton("debug_console")
