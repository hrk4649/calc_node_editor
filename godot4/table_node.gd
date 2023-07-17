extends GraphNode

signal change_name(id, node_name)
signal change_table_row(id, row)

var TableNodeLineEdit = preload("res://table_node_line_edit.tscn")
var TableNodeButton = preload("res://table_node_button.tscn")

@onready var lineEditName = $VBoxContainer/LineEditName
@onready var buttonAddRow = $VBoxContainer/HBoxContainer/ButtonAddRow
@onready var buttonDelRow = $VBoxContainer/HBoxContainer/ButtonDelRow
@onready var gridContainer = $VBoxContainer/GridContainer

var node_type: 
	get:
		return Constraints.TABLE
	set(value):
		pass

func set_node_name(value):
	lineEditName.text = value

func set_row(row):
	while get_row_count() > 1:
		delete_row(1)
	for no in range(0, row.size()):
		add_row()
	for no in range (0, row.size()):
		var no_idx = (no + 1) * gridContainer.columns
		var lineEditNo = gridContainer.get_child(no_idx)
		var lineEditMin = gridContainer.get_child(no_idx + 1)
		var lineEditMax = gridContainer.get_child(no_idx + 2)
		var lineEditValue = gridContainer.get_child(no_idx + 3)	
		var r = row[no]
		
		lineEditNo.text = str(r.no)
		lineEditMin.text = str(r.min)
		lineEditMax.text = str(r.max)
		lineEditValue.text = str(r.value)

func add_row():
	var lineEditNo = TableNodeLineEdit.instantiate()
	var lineEditMin = TableNodeLineEdit.instantiate()
	var lineEditMax = TableNodeLineEdit.instantiate()
	var lineEditValue = TableNodeLineEdit.instantiate()
	var buttonDelete = TableNodeButton.instantiate()
	lineEditNo.text = "1"
	lineEditNo.editable = false

	lineEditMin.change_value.connect(_on_table_node_line_edit_change_value)
	lineEditMax.change_value.connect(_on_table_node_line_edit_change_value)
	lineEditValue.change_value.connect(_on_table_node_line_edit_change_value)

	buttonDelete.table_node_button_pressed.connect(_on_button_delete_pressed)
	gridContainer.add_child(lineEditNo)
	gridContainer.add_child(lineEditMin)
	gridContainer.add_child(lineEditMax)
	gridContainer.add_child(lineEditValue)
	gridContainer.add_child(buttonDelete)

func delete_row(row_no):
	# pick elements to delete
	var to_delete = []
	var from = row_no * gridContainer.columns
	var to = (row_no + 1) * gridContainer.columns
	if from > gridContainer.get_child_count():
		print("delete_row:%s is out of index" % from)
		return
	if to > gridContainer.get_child_count():
		print("delete_row:%s is out of index" % to)
		return
	for idx in range(from, to):
		to_delete.append(gridContainer.get_child(idx))
	# delete elements
	for child in to_delete:
		gridContainer.remove_child(child)

func get_row_number_of(elem):
	var idx = gridContainer.get_children().find(elem)
	if idx >= 0:
		return int(idx / gridContainer.columns)
	return -1

func get_row_count():
	return int(gridContainer.get_child_count() / gridContainer.columns)

func reset_no_columns():
	for no in range (1, get_row_count()):
		var no_idx = no * gridContainer.columns
		var lineEditNo = gridContainer.get_child(no_idx)
		lineEditNo.text = str(no)

func refresh_row():
	var row_ary = []
	for no in range (1, get_row_count()):
		var no_idx = no * gridContainer.columns
		var lineEditNo = gridContainer.get_child(no_idx)
		var lineEditMin = gridContainer.get_child(no_idx + 1)
		var lineEditMax = gridContainer.get_child(no_idx + 2)
		var lineEditValue = gridContainer.get_child(no_idx + 3)
		var row = {
			"no": no,
			"min": Utils.text_to_value(lineEditMin.text),
			"max": Utils.text_to_value(lineEditMax.text),
			"value": Utils.text_to_value(lineEditValue.text),
		}
		row_ary.append(row)
	emit_signal("change_table_row", self.name, row_ary)

func _on_table_node_line_edit_change_value():
	refresh_row()

func _on_button_delete_pressed(button):
	var row_number = get_row_number_of(button)
	delete_row(row_number)
	reset_no_columns()

func _on_button_add_row_pressed():
	add_row()
	reset_no_columns()

func _on_resize_request(new_minsize):
	self.size = new_minsize

func _on_line_edit_name_text_changed(new_text):
	emit_signal("change_name", self.name, lineEditName.text)
