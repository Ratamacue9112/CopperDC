extends CanvasLayer
class_name DebugConsole

var consoleLog = []

var commandField: LineEdit
var stats: Label

func _ready():
	visible = false
	commandField = $"Command Field"
	stats = $"Stats"
	for i in range(50):
		DebugConsole.log("Log " + str(i))
		DebugConsole.log_error("Error " + str(i))
	
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
	
static func _update_log():
	var root = (Engine.get_main_loop() as SceneTree).root
	var logText = ""
	for line in root.get_node("/root/debug_console").consoleLog:
		logText += line + "\n"
	root.get_node("/root/debug_console/Log/Log Content").text = logText
