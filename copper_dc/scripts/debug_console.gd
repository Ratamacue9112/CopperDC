extends CanvasLayer
class_name DebugConsole

var consoleLog = []
var commands = {}

@onready var commandField = $"Command Field"

@onready var commandHintsPanel = $"Command Hints Panel"
@onready var commandHintsParent = $"Command Hints"
@onready var commandHintsLabel = $"Command Hints/RichTextLabel"

@onready var stats = $"Stats"
@onready var logField = $Log
@onready var scrollBar = logField.get_v_scroll_bar()

func _ready():
	visible = false
	scrollBar.connect("changed", _on_scrollbar_changed)
	
	# Register built-in commands
	commands["clear"] = DebugCommand.new("clear", clear_log, self)
	_BuiltInCommands.new().init()

func _on_scrollbar_changed():
	logField.scroll_vertical = scrollBar.max_value

func _process(delta):
	if visible:
		stats.text = "FPS: " + str(Performance.get_monitor(Performance.TIME_FPS))
		stats.text += "\nProcess Time: " + str(snapped(Performance.get_monitor(Performance.TIME_PROCESS), 0.001))

func _input(event):
	# Open debug
	if !visible and event.is_action_pressed("open_debug"):
		visible = true
		_on_command_field_text_changed(commandField.text)
		# This is stupid but it works
		await get_tree().create_timer(0.02).timeout
		commandField.grab_focus()
	# Close debug
	elif visible and event.is_action_pressed("ui_cancel"):
		visible = false
	# Enter command
	elif visible and event.is_action_pressed("ui_text_submit"):
		DebugConsole.log("> " + commandField.text)
		process_command(commandField.text)
		commandField.clear()

func _on_command_field_text_changed(new_text):
	var commandHints = []
	var commandID = new_text.split(" ")[0]
	var sortedCommands = commands.keys()
	sortedCommands.sort()
	for command in sortedCommands:
		if command.begins_with(commandID):
			commandHints.append(commands[command])
			
	_update_command_hints(commandHints)
	
func _update_command_hints(commandList:Array):
	if !commandList.is_empty():
		commandHintsParent.visible = true
		commandHintsLabel.visible = true
		commandHintsPanel.visible = true
		commandHintsLabel.text = ""
		for command in commandList:
			commandHintsLabel.text += command.id
			for parameter in command.parameters:
				commandHintsLabel.text += " <" + parameter.name + ": " + DebugCommand.ParameterType.keys()[parameter.type] + ">"
			commandHintsLabel.text += "\n"
	else:
		commandHintsParent.visible = false
		commandHintsLabel.visible = false
		commandHintsPanel.visible = false

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
			if value == "true" && commandSplit[i].to_lower() == "false":
				DebugConsole.log_error("Parameter " + currentParameterObj.name + " should be an bool, but an incorrect value was passed.")
				return
			commandFunction += value + ","
			currentParameter += 1
		# Other
		else:
			DebugConsole.log_error("Parameter " + currentParameterObj.name + " received an invalid value.")
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

static func add_command(id:String, function:Callable, functionInstance:Object, parameters:Array=[]):
	get_console().commands[id] = DebugCommand.new(id, function, functionInstance, parameters)

static func add_command_obj(command:DebugCommand):
	get_console().commands[command.id] = command

static func get_console() -> CanvasLayer:
	return (Engine.get_main_loop() as SceneTree).root.get_node("/root/debug_console") as CanvasLayer

static func _update_log():
	var root = (Engine.get_main_loop() as SceneTree).root
	var logText = ""
	for line in root.get_node("/root/debug_console").consoleLog:
		logText += str(line) + "\n"
	root.get_node("/root/debug_console/Log/Log Content").text = logText