extends GraphNode


signal change_func2(id, func_name)

onready var optionButton = $OptionButton

var funcs = ["","round"]

var node_type setget set_node_type, get_node_type

func get_node_type():
    return Constraints.FUNC2

func set_node_type(value):
    pass

func set_func_name(func_name):
    optionButton.select(funcs.find(func_name))

func _ready():
    for idx in range(0, funcs.size()):
        var func_name = funcs[idx]
        optionButton.add_item(func_name, idx)

func _on_option_button_item_selected(index):
    var func_name = funcs[index]
    emit_signal("change_func2", get_name(), func_name)

