class_name _BuiltInCommands

func init():
	DebugConsole.add_command(DebugCommand.new("add", _add, self, [
		DebugCommand.Parameter.new("x", DebugCommand.ParameterType.Int),
		DebugCommand.Parameter.new("y", DebugCommand.ParameterType.Int),
	]))

func _add(x, y):
	DebugConsole.log(x + y)
