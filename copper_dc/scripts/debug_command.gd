class_name DebugCommand

var id: String
var parameters: Array
var function: Callable

func _init(id:String, function:Callable, parameters:Array=[]):
	self.id = id
	self.parameters = parameters
	self.function = function

class Parameter:
	var name: String
	var type: ParamaterType
	
enum ParamaterType {
	Int, Float, String, FromList
}
