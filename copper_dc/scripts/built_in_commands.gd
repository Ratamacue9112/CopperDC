class_name _BuiltInCommands

func init():
	# Add int
	DebugConsole.add_command("add", _add, self, [
		DebugCommand.Parameter.new("x", DebugCommand.ParameterType.Int),
		DebugCommand.Parameter.new("y", DebugCommand.ParameterType.Int),
	])
	# Add float
	DebugConsole.add_command("addf", _add, self, [
		DebugCommand.Parameter.new("x", DebugCommand.ParameterType.Float),
		DebugCommand.Parameter.new("y", DebugCommand.ParameterType.Float),
	])
	# Add string
	DebugConsole.add_command("adds", _add, self, [
		DebugCommand.Parameter.new("x", DebugCommand.ParameterType.String),
		DebugCommand.Parameter.new("y", DebugCommand.ParameterType.String),
	])
	# Compare bool
	DebugConsole.add_command("compare", _compare, self, [
		DebugCommand.Parameter.new("x", DebugCommand.ParameterType.Bool),
		DebugCommand.Parameter.new("x", DebugCommand.ParameterType.Bool),
	])

func _add(x, y):
	DebugConsole.log(x + y)

func _compare(x, y):
	DebugConsole.log(x == y)
