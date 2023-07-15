extends GraphNode

signal change_name(id, node_name)
signal change_value(id, value)

@onready var textEditName = $VBoxContainer/TextEditName
@onready var textEditValue = $VBoxContainer/TextEditValue

func set_value(value):
	textEditValue.text = str(value)

func get_type():
	return "value"

func _ready():
	pass # Replace with function body.
	# input
	self.set_slot(0,true,1,Color.WHITE,true,1,Color.RED)

func _on_text_edit_name_text_changed():
	emit_signal("change_name", self.name, textEditName.text)

func _on_text_edit_value_text_changed():
	emit_signal("change_value", self.name, int(textEditValue.text))



