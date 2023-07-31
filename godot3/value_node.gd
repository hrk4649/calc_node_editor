extends GraphNode

signal change_name(id, node_name)
signal change_value(id, value)

onready var lineEditName = $GridContainer/LineEditName
onready var lineEditValue = $GridContainer/LineEditValue

var node_type setget set_node_type, get_node_type

func get_node_type():
    return Constraints.VALUE

func set_node_type(value):
    pass

func set_value(value):
    if value != null:
        lineEditValue.text = str(value)
    else:
        lineEditValue.clear()

func set_node_name(value):
    lineEditName.text = value

func _on_resize_request(new_minsize):
    self.rect_size = new_minsize

func _on_line_edit_name_text_changed(new_text):
    emit_signal("change_name", self.name, new_text)

func _on_line_edit_value_text_changed(new_text):
    emit_signal("change_value", self.name, new_text)
