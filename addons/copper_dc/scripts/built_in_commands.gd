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
	
	# Keep stats visible
	DebugConsole.add_command_setvar(
		"keep_stats_visible", 
		_keep_stats_visible, 
		self, 
		DebugCommand.ParameterType.Bool,
		"Sets whether the stats in the top left are visible when the console is closed.",
		_get_stats_shown
	)
	
	# Keep log visible
	DebugConsole.add_command_setvar(
		"keep_log_visible", 
		_keep_log_visible, 
		self, 
		DebugCommand.ParameterType.Bool,
		"Sets whether the mini log in the top right is visible when the console is closed.",
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
	
	# Show all binds
	DebugConsole.add_command(
		"show_all_binds",
		_show_all_binds,
		self,
		[],
		"Use to display all binded commands and their corresponding keys."
	)
	
	# Bind
	DebugConsole.add_command(
		"bind",
		_bind,
		self,
		[
			DebugCommand.Parameter.new("command", DebugCommand.ParameterType.String),
			DebugCommand.Parameter.new("keys", DebugCommand.ParameterType.String)
		],
		"Use to bind a command to a key, or key combination. Use + to seperate keys in a combination (e.g. F+F6)."
	)
	
	# Remove bind
	DebugConsole.add_command(
		"remove_bind",
		_remove_bind,
		self,
		[
			DebugCommand.Parameter.new("keys", DebugCommand.ParameterType.Options, [], _get_binds_text)
		],
		"Removes all binds attached to the given key or keys."
	)
	
	# Clear custom binds
	DebugConsole.add_command(
		"clear_custom_binds",
		_clear_custom_binds,
		self,
		[],
		"Clears all binds created with the bind command (or created with clearable set to true)."
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

func _keep_stats_visible(value):
	var console = DebugConsole.get_console()
	console.show_stats = value
	console.stats.visible = true
	
func _get_stats_shown():
	return DebugConsole.get_console().show_stats

func _keep_log_visible(value):
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

func _show_all_binds():
	var binds = DebugConsole.get_console().command_binds
	if binds.size() == 0:
		DebugConsole.log("No binds have been created.")
		return
	for bind in DebugConsole.get_console().command_binds:
		var bind_text = bind.keys_display_text + "  -  "
		for i in range(bind.commands.size()):
			if i > 0: bind_text += ",  "
			if bind.commands[i].help_text == "":
				bind_text += "\"" + bind.commands[i].command + "\""
			else:
				bind_text += bind.commands[i].help_text
		DebugConsole.log(bind_text)

func _bind(command, keys):
	var keys_text_split = keys.split("+")
	var keycodes: Array[Key] = []
	for key in keys_text_split:
		var key_trimmed = key.replace(" ", "")
		var code = OS.find_keycode_from_string(key_trimmed)
		if code == KEY_NONE or code == KEY_UNKNOWN:
			# Accept "control" as well as "ctrl"
			if key.to_lower() == "control":
				code = KEY_CTRL
			else:
				DebugConsole.log_error("No such key as \"" + key_trimmed + "\" exists.")
				return
		keycodes.append(code)
	
	DebugConsole.bind_command_combo(command, keycodes, "", true)

func _remove_bind(keys):
	var keys_text_split = keys.split("+")
	var keycodes: Array[Key] = []
	for key in keys_text_split:
		keycodes.append(OS.find_keycode_from_string(key))
	DebugConsole.remove_bind_combo(keycodes)

func _get_binds_text():
	var binds_text = []
	for bind in DebugConsole.get_console().command_binds:
		binds_text.append(bind.keys_display_text)
	return binds_text

func _clear_custom_binds():
	var binds = DebugConsole.get_console().command_binds
	var bind_count = 0
	while bind_count < binds.size():
		var command_count = 0
		var bind = binds[bind_count]
		while command_count < bind.commands.size():
			var command = bind.commands[command_count]
			if command.clearable: 
				bind.remove_command(command.command)
			else:
				command_count += 1
		
		if bind.commands.size() == 0: 
			DebugConsole.remove_bind_combo(bind.keycodes)
		else:
			bind_count += 1
		
