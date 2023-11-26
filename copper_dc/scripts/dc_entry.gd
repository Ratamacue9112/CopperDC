@tool
extends EditorPlugin

var dock

func _enter_tree():
	# Add autoloads
	add_autoload_singleton("debug_console", "res://addons/copper_dc/debug_console.tscn")

func _exit_tree():
	# Remove autoloads
	remove_autoload_singleton("debug_console")
