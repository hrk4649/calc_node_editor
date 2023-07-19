extends GraphNode

signal change_name(id, node_name)
signal change_value(id, value)

@onready var lineEditName = $VBoxContainer/LineEditName
@onready var lineEditValue = $VBoxContainer/LineEditValue

var node_type: 
	get:
		return Constraints.VALUE
	set(_value):
		pass

func set_value(value):
	lineEditValue.text = str(value)

func set_node_name(value):
	lineEditName.text = value

func _on_resize_request(new_minsize):
	self.size = new_minsize

func _on_line_edit_name_text_changed(new_text):
	emit_signal("change_name", self.name, new_text)

func _on_line_edit_value_text_changed(new_text):
	emit_signal("change_value", self.name, new_text)


