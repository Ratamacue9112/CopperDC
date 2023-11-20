class_name _BuiltInCommands

func init():
	# Add
	DebugConsole.add_command(DebugCommand.new("add", _add, self, [
		DebugCommand.Parameter.new("x", DebugCommand.ParameterType.Int),
		DebugCommand.Parameter.new("y", DebugCommand.ParameterType.Int),
	]))
	# Float
	DebugConsole.add_command(DebugCommand.new("addf", _add, self, [
		DebugCommand.Parameter.new("x", DebugCommand.ParameterType.Float),
		DebugCommand.Parameter.new("y", DebugCommand.ParameterType.Float),
	]))

func _add(x, y):
	DebugConsole.log(x + y)
