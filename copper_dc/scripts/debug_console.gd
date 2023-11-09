extends Panel

var commandField: TextEdit

func _ready():
	visible = false
	commandField = $"Command Field"

func _input(event):
	# Open debug
	if !visible and event.is_action_pressed("open_debug"):
		visible = true
		
		# This is stupid but it works
		commandField.grab_focus()
		if commandField.text == "/":
			await get_tree().create_timer(0.02).timeout
			commandField.clear()
	# Close debug
	elif visible and event.is_action_pressed("ui_cancel"):
		visible = false
