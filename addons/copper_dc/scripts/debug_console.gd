extends CanvasLayer
class_name DebugConsole

class Monitor:
	var id: String
	var display_name: String
	var value: Variant
	var visible: bool
	
	func _init(id:String, display_name:String, value:Variant, visible:bool):
		self.id = id
		self.display_name = display_name
		self.value = value
		self.visible = visible

class CommandBind:
	var command: String
	var keycodes: Array[Key]
	var help_text: String
	
	func _init(command:String, keycodes:Array[Key], help_text:String):
		self.command = command
		self.keycodes = keycodes
		self.help_text = help_text

var console_log = []
var commands = {}
var command_binds = []
var monitors = {}
var history = []
var current_history = -1

var pause_on_open = false
var show_stats = false
var show_mini_log = false

@onready var command_field = %"Command Field"
@onready var console_panel = %"Console Panel"

@onready var command_hints_panel = %"Command Hints Panel"
@onready var command_hints_parent = %"Command Hints"
@onready var command_hints_label = %"Command Hints/RichTextLabel"
@onready var command_hint_header = %"Command Hint Header"
@onready var command_hint_header_label = %"Command Hint Header/RichTextLabel"

@onready var stats = %"Stats"
@onready var mini_log = %"Mini Log"
@onready var log_field = %Log
@onready var log_scroll_bar = log_field.get_v_scroll_bar()
@onready var mini_log_scroll_bar = mini_log.get_v_scroll_bar()

#region Overrides and signals
func _ready():
	hide_console()
	log_scroll_bar.connect("changed", _on_scrollbar_changed)
	
	# Register built-in monitors
	add_monitor("fps", "FPS")
	add_monitor("process", "Process", false)
	add_monitor("physics_process", "Physics Process", false)
	add_monitor("navigation_process", "Navigation Process", false)
	add_monitor("static_memory", "Static Memory", false)
	add_monitor("static_memory_max", "Static Memory Max", false)
	add_monitor("objects", "Objects", false)
	add_monitor("nodes", "Nodes", false)
	
	# Register built-in commands
	await get_tree().create_timer(0.05).timeout
	_BuiltInCommands.new().init()

func _on_scrollbar_changed():
	log_field.scroll_vertical = log_scroll_bar.max_value

func _process(delta):
	if stats.visible:
		if is_monitor_visible("fps"):
			update_monitor("fps", Performance.get_monitor(Performance.TIME_FPS))
		if is_monitor_visible("process"):
			update_monitor("process", snapped(Performance.get_monitor(Performance.TIME_PROCESS), 0.001))
		if is_monitor_visible("physics_process"):
			update_monitor("physics_process", snapped(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS), 0.001))
		if is_monitor_visible("navigation_process"):
			update_monitor("navigation_process", snapped(Performance.get_monitor(Performance.TIME_NAVIGATION_PROCESS), 0.001))
		if is_monitor_visible("static_memory"):
			update_monitor("static_memory", snapped(Performance.get_monitor(Performance.MEMORY_STATIC), 0.001))
		if is_monitor_visible("static_memory_max"):
			update_monitor("static_memory_max", snapped(Performance.get_monitor(Performance.MEMORY_STATIC_MAX), 0.001))
		if is_monitor_visible("objects"):
			update_monitor("objects", Performance.get_monitor(Performance.OBJECT_COUNT))
		if is_monitor_visible("nodes"):
			update_monitor("nodes", Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		
		stats.text = ""
		for monitor in monitors.values():
			if monitor.visible:
				if monitor.value == null: monitor.value = "unset"
				else: monitor.value = str(monitor.value)
				stats.text += monitor.display_name + ": " + monitor.value + "\n"

func _input(event):
	var open_debug_pressed = event.is_action_pressed("open_debug") if InputMap.has_action("open_debug") else false
	var close_debug_pressed = event.is_action_pressed("close_debug") if InputMap.has_action("close_debug") else (event.is_action_pressed("ui_cancel") if not InputMap.has_action("toggle_debug") else false)
	var toggle_debug_pressed = event.is_action_pressed("toggle_debug") if InputMap.has_action("toggle_debug") else false
	
	# Open debug
	if !console_panel.visible and (open_debug_pressed or toggle_debug_pressed):
		show_console()
		_on_command_field_text_changed(command_field.text)
		# This is stupid but it works
		await get_tree().create_timer(0.02).timeout
		command_field.grab_focus()
	# Close debug
	elif console_panel.visible and (close_debug_pressed or toggle_debug_pressed):
		hide_console(show_stats, show_mini_log)
	# Enter command
	elif console_panel.visible and event.is_action_pressed("ui_text_submit"):
		if command_field.text.length() > 0:
			DebugConsole.log("> " + command_field.text)
			process_command(command_field.text)
			command_field.clear()
	# Back in history
	elif console_panel.visible and event.is_action_pressed("ui_up"):
		if history.size() > 0 and current_history != -1:
			if current_history > 0:
				current_history -= 1
			command_field.text = history[current_history]
			await get_tree().process_frame
			command_field.set_caret_column(command_field.text.length())
	# Forward in history
	elif console_panel.visible and event.is_action_pressed("ui_down"):
		if history.size() > 0 and current_history < history.size() - 1:
			current_history += 1
			command_field.text = history[current_history]
			await get_tree().process_frame
			command_field.set_caret_column(command_field.text.length())
		elif current_history == history.size() - 1:
			command_field.text = ""
			current_history = history.size()
			await get_tree().process_frame
			command_field.set_caret_column(command_field.text.length())
	# Tab completion
	elif console_panel.visible and _is_tab_press(event):
		_attempt_autocompletion()

func _unhandled_key_input(event):
	# Command keybinds
	for bind in command_binds:
		var all_keys_pressed = true
		for key in bind.keycodes:
			if not Input.is_key_pressed(key):
				all_keys_pressed = false
		if all_keys_pressed:
			process_command(bind.command)

func _on_command_field_text_changed(new_text):
	var command_hints = []
	var command_split = new_text.split(" ")
	var command_id = command_split[0]
	if command_split.size() > 1 and commands.keys().has(command_id):
		command_hints_parent.visible = true
		command_hints_label.visible = true
		command_hints_panel.visible = true
		command_hint_header.visible = true
		command_hints_label.text = ""
		
		# Get parameters filled
		var parameter_count = 0
		var reading_string = false
		for word in command_split:
			if word.begins_with("\""):
				if !reading_string: parameter_count += 1
				if word != "\"":
					if !word.ends_with("\""):
						reading_string = true
				else:
					reading_string = !reading_string
			elif word.ends_with("\""):
				reading_string = false
			else:
				if !reading_string: parameter_count += 1
		parameter_count -= 2
		command_hint_header_label.text = _get_parameter_text(commands[command_id], parameter_count)
		if parameter_count < commands[command_id].parameters.size():
			var parameter = commands[command_id].parameters[parameter_count]
			if parameter.options_get_function != Callable():
				parameter.options = parameter.options_get_function.call()
			if !parameter.options.is_empty():
				for option in parameter.options:
					if str(option).begins_with(command_split[command_split.size() - 1]):
						command_hints_label.text += "[url]" + str(option) + "[/url]\n"
	else:
		var sorted_commands = commands.keys()
		sorted_commands.sort()
		for command in sorted_commands:
			if command.begins_with(command_id):
				command_hints.append(commands[command])
		command_hint_header.visible = false
		if !command_hints.is_empty():
			command_hints_parent.visible = true
			command_hints_label.visible = true
			command_hints_panel.visible = true
			command_hints_label.text = ""
			for command in command_hints:
				command_hints_label.text += "[url=" + command.id + "]" + _get_parameter_text(command) + "[/url]\n"
		else:
			command_hints_parent.visible = false
			command_hints_label.visible = false
			command_hints_panel.visible = false

func _on_command_hints_meta_clicked(meta):
	var command_split = command_field.text.split(" ")
	command_split[-1] = meta
	var new_text = ""
	for i in command_split:
		new_text += i + " "
	command_field.text = new_text
	command_field.caret_column = len(command_field.text)
	_on_command_field_text_changed(command_field.text)
#endregion

#region Commands processing
func _get_parameter_text(command:DebugCommand, current_parameter:int=-1) -> String:
	var text: String = command.id
	var is_header = current_parameter < command.parameters.size() and current_parameter >= 0
	for parameter in command.parameters:
		if is_header and parameter.name == command.parameters[current_parameter].name:
			text += " [b]<" + parameter.name + ": " + DebugCommand.ParameterType.keys()[parameter.type] + ">[/b]"
		else:
			text += " <" + parameter.name + ": " + DebugCommand.ParameterType.keys()[parameter.type] + ">"
		if command.get_function != null:
			var value = command.get_function.call()
			if value != null:
				text += " === " + str(value)
	return text

func process_command(command:String):
	# Avoid duplicating history entries
	if history.is_empty() or command != history[-1]:
		history.append(command)
		current_history = history.size()
	# Splits command
	var command_split = command.split(" ")
	# Checks if command is valid
	if !commands.keys().has(command_split[0]):
		log_error("Command not found: " + command_split[0])
		return
	# Keeps track of current parameter being read
	var command_data = commands[command_split[0]]
	var current_parameter = 0
	
	# Checks that function is not lambda
	if command_data.function.get_method() == "<anonymous lambda>":
		DebugConsole.log_error("Command function must be named.")
		DebugConsole.log(command_data.function.get_method())
		return
	var command_function = command_data.function.get_method() +  "("
	var current_string = ""
	# Iterates through split list
	for i in range(command_split.size()):
		if i == 0: continue
		elif command_split[i] == "": continue
		if command_data.parameters.size() <= current_parameter:
			DebugConsole.log_error("Command \"" + command_data.id + "\" requires " + str(command_data.parameters.size()) + " parameters, but too many were given.")
			return
		var current_parameter_obj: DebugCommand.Parameter = command_data.parameters[current_parameter]
		
		# Int parameter
		if current_parameter_obj.type == DebugCommand.ParameterType.Int:
			if !command_split[i].is_valid_int():
				DebugConsole.log_error("Parameter " + current_parameter_obj.name + " should be an integer, but an incorrect value was passed.")
				return
			command_function += command_split[i] + ","
			current_parameter += 1
		# Float parameter
		elif current_parameter_obj.type == DebugCommand.ParameterType.Float:
			if !command_split[i].is_valid_float():
				DebugConsole.log_error("Parameter " + current_parameter_obj.name + " should be a float, but an incorrect value was passed.")
				return
			command_function += command_split[i] + ","
			current_parameter += 1
		# String parameter
		elif current_parameter_obj.type == DebugCommand.ParameterType.String:
			var word = command_split[i]
			if word.begins_with("\""):
				if word.ends_with("\""):
					if word == "\"":
						if current_string == "":
							current_string += "\" "
						else:
							command_function +=  current_string + "\","
							current_parameter += 1
					else:
						command_function += word + ","
						current_parameter += 1
				elif current_string != "":
					DebugConsole.log_error("Cannot create a string within a string.")
					return
				else:
					current_string += word + " "
			elif current_string != "":
				if word.ends_with("\""):
					current_string += word
					command_function += current_string + ","
					current_string = ""
					current_parameter += 1
				else:
					current_string += word + " "
			else:
				command_function += "\"" + word + "\","
				current_parameter += 1
		# Bool parameter
		elif current_parameter_obj.type == DebugCommand.ParameterType.Bool:
			var value = command_split[i].to_lower()
			var options = {true: ["true", "on", "1"], false: ["false", "off", "0"]}
			if value not in options[true] and value not in options[false]:
				DebugConsole.log_error("Parameter " + current_parameter_obj.name + " should be a bool, but an incorrect value was passed.")
				return
			value = "true" if value in options[true] else "false"
			command_function += value + ","
			current_parameter += 1
		# Options parameter
		elif current_parameter_obj.type == DebugCommand.ParameterType.Options:
			if current_parameter_obj.options.is_empty():
				DebugConsole.log_error("Parameter \"" + current_parameter_obj.name + "\" is meant to have options, but none were set.")
				return
			if !current_parameter_obj.options.has(command_split[i]):
				DebugConsole.log_error("\"" + command_split[i] + "\"" + " is not a valid option for parameter \"" + current_parameter_obj.name + "\".")
				return
			command_function += "\"" + command_split[i] + "\","
			current_parameter += 1
		# Other
		else:
			DebugConsole.log_error("Parameter \"" + current_parameter_obj.name + "\" received an invalid value.")
			return
		
	# Checks if all parameters are entered
	if command_data.parameters.size() != current_parameter:
		DebugConsole.log_error("Command " + command_data.id + " requires " + str(command_data.parameters.size()) + " parameters, but only " + str(current_parameter) + " were given.")
		return
		
	command_function += ")"

	var expression = Expression.new()
	var error = expression.parse(command_function)
	if error:
		DebugConsole.log_error("Parsing error: " + error_string(error))
		return

	expression.execute([], command_data.function_instance)
#endregion

#region Logging
static func log(message:Variant):
	# Add to log
	get_console().console_log.append(message)
	_update_log()
	
	# Print to Godot output
	print(str(message))

static func log_error(message:Variant):
	# Add to log
	get_console().console_log.append("[color=red]"+str(message)+"[/color]")
	_update_log()
	
	# Print to Godot output
	printerr(str(message))

static func clear_log():
	get_console().console_log.clear()
	_update_log()
#endregion

#region Creating commands
static func add_command(id:String, function:Callable, function_instance:Object, parameters:Array=[], help_text:String="", get_function:Callable=Callable()):
	get_console().commands[id] = DebugCommand.new(id, function, function_instance, parameters, help_text, get_function)

static func add_command_setvar(id:String, function:Callable, function_instance:Object, type:DebugCommand.ParameterType, help_text:String="", get_function:Callable=Callable()):
	get_console().commands[id] = DebugCommand.new(id, function, function_instance, [
		DebugCommand.Parameter.new("value", type)
	], help_text, get_function)

static func add_command_obj(command:DebugCommand):
	get_console().commands[command.id] = command
#endregion

#region Managing command binds
static func bind_command(command:String, keycode:Key, help_text:String=""):
	var binds = get_console().command_binds
	for bind in binds:
		if bind.command == command and bind.keycodes == [keycode]:
			bind.help_text = help_text
			return
	binds.append(CommandBind.new(command, [keycode], help_text))

static func bind_command_combo(command:String, keycodes:Array[Key], help_text:String=""):
	var binds = get_console().command_binds
	for bind in binds:
		if bind.command == command and bind.keycodes == keycodes:
			bind.help_text = help_text
			return
	binds.append(CommandBind.new(command, keycodes, help_text))

static func remove_bind(keycode:Key):
	var binds = get_console().command_binds
	for i in range(binds.size()):
		if binds[i].keycodes[0] == keycode:
			binds.remove_at(i)

static func remove_bind_combo(keycodes:Array[Key]):
	var binds = get_console().command_binds
	for i in range(binds.size()):
		if binds[i].keycodes == keycodes:
			binds.remove_at(i)
#endregion

#region Removing commands
static func remove_command(id:String) -> bool:
	return get_console().commands.erase(id)

static func remove_commands(ids:Array[String]):
	for id in ids:
		remove_command(id)
#endregion

#region Monitors
static func add_monitor(id:String, display_name:String, visible:bool=true):
	if id.contains(" "): 
		DebugConsole.log_error("Monitor id \"" + id + "\"" + "needs to be a single word.")
		return
	elif get_console().monitors.keys().has(id):
		pass
	else:
		get_console().monitors[id] = Monitor.new(id, display_name, null, visible)

static func update_monitor(id:String, value:Variant):
	if !get_console().monitors.keys().has(id):
		DebugConsole.log_error("Monitor " + id + " does not exist.")
	else:
		get_console().monitors[id].value = value

static func is_monitor_visible(id:String) -> bool:
	var monitors = get_console().monitors
	if !monitors.keys().has(id): return false
	else: return monitors[id].visible

static func set_monitor_visible(id:String, visible:bool):
	if !get_console().monitors.keys().has(id):
		DebugConsole.log_error("Monitor " + id + " does not exist.")
	else:
		get_console().monitors[id].visible = visible
#endregion

#region Console managing
func _is_tab_press(event: InputEvent):
	if event is not InputEventKey:
		return false
	var key_event := event as InputEventKey
	return key_event.keycode == KEY_TAB and key_event.pressed and not key_event.echo

func _attempt_autocompletion():
	# Populate the hints label with words we could autocomplete
	_on_command_field_text_changed(command_field.text)
	# Gather the first word of each hint, stripping the [url] wrappers
	var hints = []
	for hint in command_hints_label.text.split("\n"):
		hints.append(hint.get_slice(']', 1).get_slice('[', 0).get_slice(" ", 0))
	hints = hints.slice(0, -1)
	# Find the common prefix to all hints
	var common_prefix = ""
	if not hints.is_empty():
		for i in range(1000):
			if not hints.all(func(h): return len(h) > i and h[i] == hints[0][i]):
				break
			common_prefix += hints[0][i]
	if not command_hints_label.visible or common_prefix == '':
		return
	if len(hints) == 1:
		common_prefix += ' ' # Only one hint, so complete the whole word
	# Replace the last word, if any, with `common_prefix`
	var r = RegEx.new()
	r.compile(r'(\w+)?$') # "Any non-whitespace characters until the end"
	var new_text = r.sub(command_field.text, common_prefix)
	command_field.text = new_text
	command_field.caret_column = len(new_text)
	_on_command_field_text_changed(new_text)

static func get_console() -> DebugConsole:
	return (Engine.get_main_loop() as SceneTree).root.get_node("/root/debug_console") as DebugConsole

static func hide_console(show_stats:bool=false, show_mini_log:bool=false):
	var console := get_console()
	console.console_panel.visible = false
	console.stats.visible = show_stats
	console.mini_log.visible = show_mini_log
	await console.get_tree().create_timer(0.01).timeout
	console.mini_log.scroll_vertical = console.mini_log_scroll_bar.max_value
	
	if console.pause_on_open: console.get_tree().paused = false

static func show_console():
	var console := get_console()
	console.console_panel.visible = true
	console.stats.visible = true
	console.mini_log.visible = false
	
	if console.pause_on_open: console.get_tree().paused = true

static func is_console_visible() -> bool:
	var console = get_console()
	if is_instance_valid(console):
		return console.get_node("Console Panel").visible
	else:
		return false

static func set_pause_on_open(pause:bool):
	get_console().pause_on_open = pause

static func _update_log():
	var console := get_console()
	var log_text = ""
	for line in console.console_log:
		log_text += str(line) + "\n"
	
	console.log_field.get_node("MarginContainer/Log Content").text = log_text
	console.mini_log.get_node("MarginContainer/Log Content").text = "[right]" + log_text
#endregion

static func setup_cfg():
	DirAccess.make_dir_absolute("user://cfg")
	#var file = FileAccess.open("user://cfg/autoexec.cfg", FileAccess.WRITE)
