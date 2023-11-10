extends CanvasLayer
class_name DebugConsole

var consoleLog = []
var commands = {}

var commandField: LineEdit
var stats: Label

func _ready():
	visible = false
	commandField = $"Command Field"
	stats = $"Stats"
	
	# Register clear command
	commands["clear"] = DebugCommand.new("clear", clear_log)

func _process(delta):
	if visible:
		stats.text = "FPS: " + str(Performance.get_monitor(Performance.TIME_FPS))
		stats.text += "\nProcess Time: " + str(snapped(Performance.get_monitor(Performance.TIME_PROCESS), 0.001))

func _input(event):
	# Open debug
	if !visible and event.is_action_pressed("open_debug"):
		visible = true
		
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
	
	# Iterates through split list
	for i in range(commandSplit.size() - 2):
		pass
	
	commandData.function.call()

static func log(message):
	# Add to log
	(Engine.get_main_loop() as SceneTree).root.get_node("/root/debug_console").consoleLog.append(message)
	_update_log()
	
	# Print to Godot output
	print(str(message))

static func log_error(message):
	# Add to log
	(Engine.get_main_loop() as SceneTree).root.get_node("/root/debug_console").consoleLog.append("[color=red]"+message+"[/color]")
	_update_log()
	
	# Print to Godot output
	printerr(str(message))

static func clear_log():
	(Engine.get_main_loop() as SceneTree).root.get_node("/root/debug_console").consoleLog.clear()
	_update_log()

static func _update_log():
	var root = (Engine.get_main_loop() as SceneTree).root
	var logText = ""
	for line in root.get_node("/root/debug_console").consoleLog:
		logText += line + "\n"
	root.get_node("/root/debug_console/Log/Log Content").text = logText
