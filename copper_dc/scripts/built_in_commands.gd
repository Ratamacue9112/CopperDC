class_name _BuiltInCommands

func init():
	# Add int
	DebugConsole.add_command(DebugCommand.new("add", _add, self, [
		DebugCommand.Parameter.new("x", DebugCommand.ParameterType.Int),
		DebugCommand.Parameter.new("y", DebugCommand.ParameterType.Int),
	]))
	# Add float
	DebugConsole.add_command(DebugCommand.new("addf", _add, self, [
		DebugCommand.Parameter.new("x", DebugCommand.ParameterType.Float),
		DebugCommand.Parameter.new("y", DebugCommand.ParameterType.Float),
	]))
	# Add string
	DebugConsole.add_command(DebugCommand.new("adds", _add, self, [
		DebugCommand.Parameter.new("x", DebugCommand.ParameterType.String),
		DebugCommand.Parameter.new("y", DebugCommand.ParameterType.String),
	]))

func _add(x, y):
	DebugConsole.log(x + y)
