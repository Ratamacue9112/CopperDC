class_name _BuiltInCommands

func init():
	# Clear
	DebugConsole.add_command(
		"clear", 
		DebugConsole.clear_log, 
		DebugConsole
	)
	
	# Show stats
	DebugConsole.add_command_setvar(
		"show_stats", 
		_show_stats, 
		self, 
		DebugCommand.ParameterType.Bool, 
		_get_stats_shown
	)
	
	# Show log
	DebugConsole.add_command_setvar(
		"show_log", 
		_show_log, 
		self, 
		DebugCommand.ParameterType.Bool,
		_get_log_shown
	)
	
	# Exec
	var cfgs = []
	for file in list_files_in_directory("user://cfg"):
		var fileSplit = file.split(".")
		if fileSplit[-1] == "cfg":
			cfgs.append(fileSplit[0])
	
	var autoexec = FileAccess.open("user://cfg/autoexec.cfg", FileAccess.READ)
	if autoexec != null: _exec("autoexec")
	DebugConsole.add_command(
		"exec", 
		_exec, 
		self, 
		[DebugCommand.Parameter.new("cfg", DebugCommand.ParameterType.Options, cfgs)]
	)
	
	var monitors = DebugConsole.get_console().monitors.keys()
	# Show monitor
	DebugConsole.add_command(
		"show_monitor",
		DebugConsole.set_monitor_visible,
		DebugConsole,
		[
			DebugCommand.Parameter.new("monitor", DebugCommand.ParameterType.Options, monitors),
			DebugCommand.Parameter.new("visible", DebugCommand.ParameterType.Bool)
		]
	)
	# Hide monitor

func list_files_in_directory(path):
	var files = []
	if DirAccess.open("user://").dir_exists(path):
		var dir = DirAccess.open(path)
		dir.list_dir_begin()

		while true:
			var file = dir.get_next()
			if file == "":
				break
			elif not file.begins_with("."):
				files.append(file)
			
		dir.list_dir_end()
		
		return files
	return []

func _show_stats(value):
	var console = DebugConsole.get_console()
	console.showStats = value
	console.stats.visible = true
	
func _get_stats_shown():
	return DebugConsole.get_console().showStats

func _show_log(value):
	var console = DebugConsole.get_console()
	console.showMiniLog = value
	if !console.commandField.visible:
		console.miniLog.visible = true
	
func _get_log_shown():
	return DebugConsole.get_console().showMiniLog

func _exec(file):
	var commands = FileAccess.open("user://cfg/" + file + ".cfg", FileAccess.READ).get_as_text().split("\r\n")
	var commandCount = 0
	for command in commands:
		if command.replace(" ", "") != "":
			#DebugConsole.log("> " + command)
			DebugConsole.get_console().process_command(command)
			commandCount += 1
	DebugConsole.log("File " + file + ".cfg ran " + str(commandCount) + " commands.")
