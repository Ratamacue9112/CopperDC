class_name _BuiltInCommands

func init():
	# Clear
	DebugConsole.add_command(
		"clear", 
		DebugConsole.clear_log, 
		DebugConsole
	)
	
	# Show stats
	DebugConsole.add_setvar_command(
		"show_stats", 
		_show_stats, 
		self, 
		DebugCommand.ParameterType.Bool, 
		_get_stats_shown
	)
	
	# Show log
	DebugConsole.add_setvar_command(
		"show_log", 
		_show_log, 
		self, 
		DebugCommand.ParameterType.Bool,
		_get_log_shown
	)

func _show_stats(value):
	DebugConsole.get_console().showStats = value
	
func _get_stats_shown():
	return DebugConsole.get_console().showStats

func _show_log(value):
	DebugConsole.get_console().showMiniLog = value
	
func _get_log_shown():
	return DebugConsole.get_console().showMiniLog
