extends GraphNode

signal change_func(id, func_name)

@onready var optionButton = $OptionButton

var funcs = ["","round","floor","ceil","sin"]

var node_type: 
	get:
		return Constraints.FUNC
	set(_value):
		pass

func set_func_name(func_name):
	optionButton.select(funcs.find(func_name))

func _ready():
	for idx in range(0, funcs.size()):
		var func_name = funcs[idx]
		optionButton.add_item(func_name, idx)

func _on_option_button_item_selected(index):
	var func_name = funcs[index]
	emit_signal("change_func", get_name(), func_name)
