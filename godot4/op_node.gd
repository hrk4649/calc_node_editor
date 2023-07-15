extends GraphNode

func get_type():
	return "operator"

func _ready():
	pass # Replace with function body.
#	self.set_slot(
#		slot_index: int, enable_left_port: bool, type_left: int, color_left: Color, \\
#		enable_right_port: bool, type_right: int, color_right: Color, \\
#		custom_icon_left: Texture2D = null, custom_icon_right: Texture2D = null, draw_stylebox: bool = true)
	self.set_slot(0,true,1,Color.WHITE,true,1,Color.BLACK)
