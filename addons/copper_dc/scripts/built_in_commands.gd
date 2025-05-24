class_name _BuiltInCommands

func init():
	# Clear
	DebugConsole.add_command(
		"clear", 
		DebugConsole.clear_log, 
		DebugConsole,
		[],
		"Clears the console."
	)
	
	# Show stats
	DebugConsole.add_command_setvar(
		"show_stats", 
		_show_stats, 
		self, 
		DebugCommand.ParameterType.Bool,
		"Sets whether the stats in the top left is visible.",
		_get_stats_shown
	)
	
	# Show log
	DebugConsole.add_command_setvar(
		"show_mini_log", 
		_show_log, 
		self, 
		DebugCommand.ParameterType.Bool,
		"Sets whether the mini log in the top right is visible.",
		_get_log_shown
	)
	
	# Exec
	var cfgs = []
	for file in list_files_in_directory("user://cfg"):
		var file_split = file.split(".")
		if file_split[-1] == "cfg":
			cfgs.append(file_split[0])
	
	var autoexec = FileAccess.open("user://cfg/autoexec.cfg", FileAccess.READ)
	if autoexec != null: _exec("autoexec")
	DebugConsole.add_command(
		"exec", 
		_exec, 
		self, 
		[DebugCommand.Parameter.new("cfg", DebugCommand.ParameterType.Options, cfgs)],
		"Executes the given cfg file, from top to bottom."
	)
	
	# Open cfg directory
	DebugConsole.add_command(
		"open_cfg_dir", 
		_open_cfg_dir, 
		self,
		[],
		"Opens the directory where cfg files are put, if it exists."
	)
	
	var monitors = DebugConsole.get_console().monitors.keys()
	# Show/hide monitor
	DebugConsole.add_command(
		"set_monitor_visible",
		DebugConsole.set_monitor_visible,
		DebugConsole,
		[
			DebugCommand.Parameter.new("monitor", DebugCommand.ParameterType.Options, monitors),
			DebugCommand.Parameter.new("visible", DebugCommand.ParameterType.Bool)
		],
		"Sets whether a particular stat monitor is visible."
	)
	
	var commands = DebugConsole.get_console().commands.keys()
	commands.sort()
	# Help
	DebugConsole.add_command(
		"help",
		_help,
		self,
		[DebugCommand.Parameter.new("command", DebugCommand.ParameterType.Options, commands)],
		"Use to get help on any particular command."
	)

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
	console.show_stats = value
	console.stats.visible = true
	
func _get_stats_shown():
	return DebugConsole.get_console().show_stats

func _show_log(value):
	var console = DebugConsole.get_console()
	console.show_mini_log = value
	if !console.command_field.visible:
		console.mini_log.visible = true
	
func _get_log_shown():
	return DebugConsole.get_console().show_mini_log

func _exec(file):
	var commands = FileAccess.open("user://cfg/" + file + ".cfg", FileAccess.READ).get_as_text().split("\r\n")
	var command_count = 0
	for command in commands:
		if command.replace(" ", "") != "":
			DebugConsole.get_console().process_command(command)
			command_count += 1
	DebugConsole.log("File " + file + ".cfg ran " + str(command_count) + " commands.")

func _open_cfg_dir():
	if not DirAccess.dir_exists_absolute("user://cfg"):
		DirAccess.make_dir_absolute("user://cfg")
	OS.shell_open(ProjectSettings.globalize_path("user://cfg"))

func _help(command):
	var help_text = DebugConsole.get_console().commands[command].help_text
	DebugConsole.log(command + " - " + (help_text if help_text != "" else "There is no help available."))
