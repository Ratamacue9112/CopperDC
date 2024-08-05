class_name DebugCommand

var id: String
var parameters: Array
var function: Callable
var functionInstance: Object
var helpText: String
var getFunction

func _init(id:String, function:Callable, functionInstance: Object, parameters:Array=[], helpText:String="", getFunction=null):
	self.id = id
	self.parameters = parameters
	self.function = function
	self.functionInstance = functionInstance
	self.helpText = helpText
	if getFunction != null: self.getFunction = getFunction

class Parameter:
	var name: String
	var type: ParameterType
	var options: Array
	
	func _init(name:String, type:ParameterType, options:Array=[]):
		self.name = name
		self.type = type
		self.options = options

enum ParameterType {
	Int, Float, String, Bool, Options
}
