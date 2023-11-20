class_name DebugCommand

var id: String
var parameters: Array
var function: Callable
var functionInstance: Object

func _init(id:String, function:Callable, functionInstance: Object, parameters:Array=[]):
	self.id = id
	self.parameters = parameters
	self.function = function
	self.functionInstance = functionInstance

class Parameter:
	var name: String
	var type: ParameterType
	
	func _init(name:String, type:ParameterType):
		self.name = name
		self.type = type
	
enum ParameterType {
	Int, Float, String, FromList
}
