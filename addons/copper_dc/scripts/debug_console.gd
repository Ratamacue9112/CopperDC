extends CanvasLayer
class_name DebugConsole

class Monitor:
	var id: String
	var displayName: String
	var value: Variant
	var visible: bool
	
	func _init(id:String, displayName:String, value:Variant, visible:bool):
		self.id = id
		self.displayName = displayName
		self.value = value
		self.visible = visible

var consoleLog = []
var commands = {}
var monitors = {}

var showStats = false
var showMiniLog = false

@onready var commandField = $"Command Field"

@onready var commandHintsPanel = $"Command Hints Panel"
@onready var commandHintsParent = $"Command Hints"
@onready var commandHintsLabel = $"Command Hints/RichTextLabel"
@onready var commandHintHeader = $"Command Hint Header"
@onready var commandHintHeaderLabel = $"Command Hint Header/RichTextLabel"

@onready var stats = $"Stats"
@onready var miniLog = $"Mini Log"
@onready var logField = $Log
@onready var logScrollBar = logField.get_v_scroll_bar()
@onready var miniLogScrollBar = miniLog.get_v_scroll_bar()

#region Overrides
func _ready():
	hide_console()
	logScrollBar.connect("changed", _on_scrollbar_changed)
	
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
	logField.scroll_vertical = logScrollBar.max_value

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
				stats.text += monitor.displayName + ": " + monitor.value + "\n"

func _input(event):
	# Open debug
	if !commandField.visible and event.is_action_pressed("open_debug"):
		show_console()
		_on_command_field_text_changed(commandField.text)
		# This is stupid but it works
		await get_tree().create_timer(0.02).timeout
		commandField.grab_focus()
	# Close debug
	elif visible and event.is_action_pressed("ui_cancel"):
		hide_console(showStats, showMiniLog)
	# Enter command
	elif visible and event.is_action_pressed("ui_text_submit"):
		DebugConsole.log("> " + commandField.text)
		process_command(commandField.text)
		commandField.clear()

func _on_command_field_text_changed(new_text):
	var commandHints = []
	var commandSplit = new_text.split(" ")
	var commandID = commandSplit[0]
	if commandSplit.size() > 1 and commands.keys().has(commandID):
		commandHintsParent.visible = true
		commandHintsLabel.visible = true
		commandHintsPanel.visible = true
		commandHintHeader.visible = true
		commandHintsLabel.text = ""
		
		# Get parameters filled
		var parameterCount = 0
		var readingString = false
		for word in commandSplit:
			if word.begins_with("\""):
				if !readingString: parameterCount += 1
				if word != "\"":
					if !word.ends_with("\""):
						readingString = true
				else:
					readingString = !readingString
			elif word.ends_with("\""):
				readingString = false
			else:
				if !readingString: parameterCount += 1
		parameterCount -= 2
		commandHintHeaderLabel.text = _get_parameter_text(commands[commandID], parameterCount)
		if parameterCount < commands[commandID].parameters.size():
			var options = commands[commandID].parameters[parameterCount].options
			if !options.is_empty():
				for option in options:
					if str(option).begins_with(commandSplit[commandSplit.size() - 1]):
						commandHintsLabel.text += str(option) + "\n"
	else:
		var sortedCommands = commands.keys()
		sortedCommands.sort()
		for command in sortedCommands:
			if command.begins_with(commandID):
				commandHints.append(commands[command])
		commandHintHeader.visible = false
		if !commandHints.is_empty():
			commandHintsParent.visible = true
			commandHintsLabel.visible = true
			commandHintsPanel.visible = true
			commandHintsLabel.text = ""
			for command in commandHints:
				commandHintsLabel.text += _get_parameter_text(command) + "\n"
		else:
			commandHintsParent.visible = false
			commandHintsLabel.visible = false
			commandHintsPanel.visible = false
#endregion

#region Commands processing
func _get_parameter_text(command, currentParameter=-1) -> String:
	var text: String = command.id
	var isHeader = currentParameter < command.parameters.size() and currentParameter >= 0
	for parameter in command.parameters:
		if isHeader and parameter.name == command.parameters[currentParameter].name:
			text += " [b]<" + parameter.name + ": " + DebugCommand.ParameterType.keys()[parameter.type] + ">[/b]"
		else:
			text += " <" + parameter.name + ": " + DebugCommand.ParameterType.keys()[parameter.type] + ">"
		if command.getFunction != null:
			#print(typeof(command.getFunction))
			var value = command.getFunction.call()
			if value != null:
				text += " === " + str(value)
	return text

func process_command(command):
	# Splits command
	var commandSplit = command.split(" ")
	# Checks if command is valid
	if !commands.keys().has(commandSplit[0]):
		log_error("Command not found: " + commandSplit[0])
		return
	# Keeps track of current parameter being read
	var commandData = commands[commandSplit[0]]
	var currentParameter = 0
	
	# Checks that function is not lambda
	if commandData.function.get_method() == "<anonymous lambda>":
		DebugConsole.log_error("Command function must be named.")
		DebugConsole.log(commandData.function.get_method())
		return
	var commandFunction = commandData.function.get_method() +  "("
	var currentString = ""
	# Iterates through split list
	for i in range(commandSplit.size()):
		if i == 0: continue
		elif commandSplit[i] == "": continue
		if commandData.parameters.size() <= currentParameter:
			DebugConsole.log_error("Command \"" + commandData.id + "\" requires " + str(commandData.parameters.size()) + " parameters, but too many were given.")
			return
		var currentParameterObj: DebugCommand.Parameter = commandData.parameters[currentParameter]
		
		# Int parameter
		if currentParameterObj.type == DebugCommand.ParameterType.Int:
			if !commandSplit[i].is_valid_int():
				DebugConsole.log_error("Parameter " + currentParameterObj.name + " should be an integer, but an incorrect value was passed.")
				return
			commandFunction += commandSplit[i] + ","
			currentParameter += 1
		# Float parameter
		elif currentParameterObj.type == DebugCommand.ParameterType.Float:
			if !commandSplit[i].is_valid_float():
				DebugConsole.log_error("Parameter " + currentParameterObj.name + " should be a float, but an incorrect value was passed.")
				return
			commandFunction += commandSplit[i] + ","
			currentParameter += 1
		# String parameter
		elif currentParameterObj.type == DebugCommand.ParameterType.String:
			var word = commandSplit[i]
			if word.begins_with("\""):
				if word.ends_with("\""):
					if word == "\"":
						if currentString == "":
							currentString += "\" "
						else:
							commandFunction +=  currentString + "\","
							currentParameter += 1
					else:
						commandFunction += word + ","
						currentParameter += 1
				elif currentString != "":
					DebugConsole.log_error("Cannot create a string within a string.")
					return
				else:
					currentString += word + " "
			elif currentString != "":
				if word.ends_with("\""):
					currentString += word
					commandFunction += currentString + ","
					currentString = ""
					currentParameter += 1
				else:
					currentString += word + " "
			else:
				commandFunction += "\"" + word + "\","
				currentParameter += 1
		# Bool parameter
		elif currentParameterObj.type == DebugCommand.ParameterType.Bool:
			var value = commandSplit[i].to_lower()
			if value != "true" and value != "false":
				DebugConsole.log_error("Parameter " + currentParameterObj.name + " should be an bool, but an incorrect value was passed.")
				return
			commandFunction += value + ","
			currentParameter += 1
		# Options parameter
		elif currentParameterObj.type == DebugCommand.ParameterType.Options:
			if currentParameterObj.options.is_empty():
				DebugConsole.log_error("Parameter \"" + currentParameterObj.name + "\" is meant to have options, but none were set.")
				return
			if !currentParameterObj.options.has(commandSplit[i]):
				DebugConsole.log_error("\"" + commandSplit[i] + "\"" + " is not a valid option for parameter \"" + currentParameterObj.name + "\".")
				return
			commandFunction += "\"" + commandSplit[i] + "\","
			currentParameter += 1
		# Other
		else:
			DebugConsole.log_error("Parameter \"" + currentParameterObj.name + "\" received an invalid value.")
			return
		
	# Checks if all parameters are entered
	if commandData.parameters.size() != currentParameter:
		DebugConsole.log_error("Command " + commandData.id + " requires " + str(commandData.parameters.size()) + " parameters, but only " + str(currentParameter) + " were given.")
		return
		
	commandFunction += ")"

	var expression = Expression.new()
	var error = expression.parse(commandFunction)
	if error:
		DebugConsole.log_error("Parsing error: " + error_string(error))
		return

	expression.execute([], commandData.functionInstance)
#endregion

#region Logging
static func log(message):
	# Add to log
	get_console().consoleLog.append(message)
	_update_log()
	
	# Print to Godot output
	print(str(message))

static func log_error(message):
	# Add to log
	get_console().consoleLog.append("[color=red]"+str(message)+"[/color]")
	_update_log()
	
	# Print to Godot output
	printerr(str(message))

static func clear_log():
	get_console().consoleLog.clear()
	_update_log()
#endregion

#region Creating commands
static func add_command(id:String, function:Callable, functionInstance:Object, parameters:Array=[], getFunction=null):
	get_console().commands[id] = DebugCommand.new(id, function, functionInstance, parameters, getFunction)

static func add_command_setvar(id:String, function:Callable, functionInstance:Object, type:DebugCommand.ParameterType, getFunction=null):
	get_console().commands[id] = DebugCommand.new(id, function, functionInstance, [
		DebugCommand.Parameter.new("value", type)
	], getFunction)

static func add_command_obj(command:DebugCommand):
	get_console().commands[command.id] = command
#endregion

#region Monitors
static func add_monitor(id, displayName, visible:bool=true):
	if id.contains(" "): 
		DebugConsole.log_error("Monitor id \"" + id + "\"" + "needs to be a single word.")
		return
	elif get_console().monitors.keys().has(id):
		pass
	else:
		get_console().monitors[id] = Monitor.new(id, displayName, null, visible)

static func update_monitor(id, value):
	if !get_console().monitors.keys().has(id):
		DebugConsole.log_error("Monitor " + id + " does not exist.")
	else:
		get_console().monitors[id].value = value

static func is_monitor_visible(id) -> bool:
	var monitors = get_console().monitors
	if !monitors.keys().has(id): return false
	else: return monitors[id].visible

static func set_monitor_visible(id, visible):
	if !get_console().monitors.keys().has(id):
		DebugConsole.log_error("Monitor " + id + " does not exist.")
	else:
		get_console().monitors[id].visible = visible
#endregion

#region Console managing
static func get_console() -> CanvasLayer:
	return (Engine.get_main_loop() as SceneTree).root.get_node("/root/debug_console") as CanvasLayer

static func hide_console(showStats:bool=false, showMiniLog:bool=false):
	var console = get_console()
	for child in console.get_children():
		if (!showStats or child.name != "Stats") and (!showMiniLog or child.name != "Mini Log"):
			child.visible = false
		elif child.name == "Mini Log":
			child.visible = true
			await console.get_tree().create_timer(0.01).timeout
			console.miniLog.scroll_vertical = console.miniLogScrollBar.max_value

static func show_console():
	for child in get_console().get_children():
		if child.name != "Mini Log":
			child.visible = true
		else:
			child.visible = false

static func _update_log():
	var console = get_console()
	var logText = ""
	for line in console.consoleLog:
		logText += str(line) + "\n"
	
	console.get_node("Log/MarginContainer/Log Content").text = logText
	console.get_node("Mini Log/MarginContainer/Log Content").text = "[right]" + logText
#endregion

static func setup_cfg():
	DirAccess.make_dir_absolute("user://cfg")
	#var file = FileAccess.open("user://cfg/autoexec.cfg", FileAccess.WRITE)
