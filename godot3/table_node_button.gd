extends Button

signal table_node_button_pressed(button)

func _on_pressed():
    emit_signal("table_node_button_pressed", self)
