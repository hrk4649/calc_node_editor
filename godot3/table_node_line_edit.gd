extends LineEdit

signal change_value

func _on_text_changed(_new_text):
    emit_signal("change_value")
