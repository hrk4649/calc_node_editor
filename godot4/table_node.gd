extends GraphNode

var TableNodeLineEdit = preload("res://table_node_line_edit.tscn")
var TableNodeButton = preload("res://table_node_button.tscn")

@onready var buttonAddRow = $VBoxContainer/HBoxContainer/ButtonAddRow
@onready var buttonDelRow = $VBoxContainer/HBoxContainer/ButtonDelRow
@onready var gridContainer = $GridContainer

var node_type: 
	get:
		return Constraints.TABLE
	set(value):
		pass

func add_row():
	pass
	var lineEditNo = TableNodeLineEdit.instantiate()
	var lineEditMin = TableNodeLineEdit.instantiate()
	var lineEditMax = TableNodeLineEdit.instantiate()
	var lineEditValue = TableNodeLineEdit.instantiate()
	var buttonDelete = TableNodeButton.instantiate()
	lineEditNo.text = "1"
	lineEditNo.editable = false
	buttonDelete.table_node_button_pressed.connect(_on_button_delete_pressed)
	var elems = [lineEditNo, lineEditMin, lineEditMax, lineEditValue, buttonDelete]
	for elem in elems:
		gridContainer.add_child(elem)

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
	pass
	for row in range (1, get_row_count()):
		var no_idx = row * gridContainer.columns
		var lineEditNo = gridContainer.get_child(no_idx)
		lineEditNo.text = str(row)

func _on_button_delete_pressed(button):
	var row_number = get_row_number_of(button)
	delete_row(row_number)
	reset_no_columns()

func _on_button_add_row_pressed():
	add_row()
	reset_no_columns()

func _on_resize_request(new_minsize):
	self.size = new_minsize
