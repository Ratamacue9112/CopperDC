# CopperDC
A in-game debug console for Godot. This makes testing in a build much easier. For example, if you want to play a certain level in a build, you could create a command to take you there without having to play through the game.

## Setup
1. Download the repository
2. Place it the addons folder in your project (if you don't have one make one)
3. Go to Edit > Project Settings > Plugins and enable the plugin
4. Click the input map and create a new action called "open_debug" (it has to be this exactly)
5. Bind "open_debug" to whatever key you want
6. Run the game and press that key to test if the console opens

## Using the log
CopperDC includes an in-game debug log. Note that Godot's `print()` and `printerr()` functions will not show their output in the in-game log. You must instead use `DebugConsole.log()` or `DebugConsole.log_error()`. These functions will also show their message in the Godot output tab.

## Creating commands
First, create a script that will run on game startup. For example, this could be done by attaching the script to a node in the main menu.
Then, in that scripts ready function, you can instantiate your commands. Commands are created like this: <br><br>
`DebugConsole.add_command(id: String, function: Callable, functionInstance: Object, parameters: Array = [])`<br><br>
- **id**: The name of the command. This will be the first word of the command.
- **function**: The function your command will run. Lambda functions do not work.
- **functionInstance**: The instance your function will be called on. Almost always set to `self`.
- **parameters** *(optional)*: The parameters of your command. More details in the next section.

## Command parameters
Parameters are created like this:<br><br>
`DebugCommand.Parameter.new(name: String, type: DebugCommand.ParameterType, options: Array = [])`<br><br>
They parameter types available are:
- **Int**: A whole number
- **Float**: Any number, including decimals
- **String**: Text. Can be a single word, or multiple words wrapped in double quotes.
- **Bool**: A condition. Can be `true` or `false` (not case sensitive).
- **Options**: Allows the user to select from a list. For this you must put an array in the `options` parameter. If you fill in the `options` parameter on other parameter types, it will show up in the hints section, but will not restrict the options, more acting like suggestions.

## Example
Lets say we want to create a command that gets a substring within a string. We have a script attached to a child node of our main menu. In that script, type:<br><br>
```
func _ready():
	DebugConsole.add_command("substring", substring_function, self, [
		DebugCommand.Parameter.new("original", DebugCommand.ParameterType.String),
		DebugCommand.Parameter.new("from", DebugCommand.ParameterType.Int),
		DebugCommand.Parameter.new("length", DebugCommand.ParameterType.Int)
	])
```
Then below that create `substring_function`:
```
func substring_function(original, from, length):
	DebugConsole.log(original.substr(from, length))
```
Now if you start the game, open the console and type:
`substring "a b cde" 2 4`.
The console will output `b cd`, the string that starts at index 2 and lasts 4 characters.

## Future plans
I plan to implement these in future updates:
- ~~Command hints~~
- ~~"Choose from options" parameters~~
- Custom monitors (where it currently has FPS and process time)
