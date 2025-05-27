class_name DebugCommand

var id: String
var parameters: Array
var function: Callable
var function_instance: Object
var help_text: String
var get_function

func _init(id:String, function:Callable, function_instance: Object, parameters:Array=[], help_text:String="", get_function:Callable=Callable()):
	self.id = id
	self.parameters = parameters
	self.function = function
	self.function_instance = function_instance
	self.help_text = help_text
	if get_function != Callable(): self.get_function = get_function

class Parameter:
	var name: String
	var type: ParameterType
	var options: Array
	var options_get_function: Callable
	
	func _init(name:String, type:ParameterType, options:Array=[], options_get_function:Callable=Callable()):
		self.name = name
		self.type = type
		self.options = options
		self.options_get_function = options_get_function

enum ParameterType {
	Int, Float, String, Bool, Options
}
