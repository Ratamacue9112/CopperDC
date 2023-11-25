class_name _BuiltInCommands

func init():
	# Clear
	DebugConsole.add_command("clear", DebugConsole.clear_log, DebugConsole)
	
	# Display stats
	DebugConsole.add_setvar_command("display_stats", _show_stats, self, DebugCommand.ParameterType.Bool, _get_stats_shown)

func _show_stats(value):
	DebugConsole.get_console().showStats = value
	
func _get_stats_shown():
	return DebugConsole.get_console().showStats
