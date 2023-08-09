extends GraphNode

signal change_name(id, node_name)
signal change_table_rows(id, row)

var TableNodeLineEdit = preload("res://table_node_line_edit.tscn")
var TableNodeButton = preload("res://table_node_button.tscn")

onready var lineEditName = $VBoxContainer/HBoxContainer/LineEditName
onready var buttonAddRow = $VBoxContainer/HBoxContainer2/ButtonAddRow
onready var gridContainer = $VBoxContainer/GridContainer

var skip_refresh_row = false

var node_type setget set_node_type, get_node_type

func get_node_type():
    return Constraints.OPTION

func set_node_type(value):
    pass

func set_node_name(value):
    lineEditName.text = value

func init_rows(rows):
    skip_refresh_row = true
    for no in range(0, rows.size()):
        add_row()
    for no in range (0, rows.size()):
        var no_idx = (no + 1) * gridContainer.columns
        var lineEditNo = gridContainer.get_child(no_idx)
        var checkBoxCheck = gridContainer.get_child(no_idx + 1)
        var lineEditDesc = gridContainer.get_child(no_idx + 2)
        var lineEditValue = gridContainer.get_child(no_idx + 3)	
        var r = rows[no]
        
        var values = [r.no, r.check, r.description, r.value]
        var uis = [lineEditNo, checkBoxCheck, lineEditDesc, lineEditValue]
        
        for idx in range(0, values.size()):
            var value = values[idx]
            var ui = uis[idx]
            match ui:
                lineEditNo, lineEditDesc, lineEditValue:
                    if value != null:
                        var str_value = str(value)
                        if ui.text != str_value:
                            ui.text = str_value
                    else:
                        ui.clear()
                checkBoxCheck:
                    ui.pressed = (value == true)
        skip_refresh_row = false

func add_row():
    var lineEditNo = TableNodeLineEdit.instance()
    var checkBoxCheck = CheckBox.new()
    var lineEditDesc = TableNodeLineEdit.instance()
    var lineEditValue = TableNodeLineEdit.instance()
    var buttonDelete = TableNodeButton.instance()
    lineEditNo.text = "1"
    lineEditNo.editable = false
    checkBoxCheck.connect("pressed", self, "_on_table_node_line_edit_change_value")
    lineEditDesc.connect("change_value", self, "_on_table_node_line_edit_change_value")
    lineEditValue.connect("change_value", self, "_on_table_node_line_edit_change_value")
    buttonDelete.connect("table_node_button_pressed", self, "_on_button_delete_pressed")
    gridContainer.add_child(lineEditNo)
    gridContainer.add_child(checkBoxCheck)
    gridContainer.add_child(lineEditDesc)
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
    var rows = []
    for no in range (1, get_row_count()):
        var no_idx = no * gridContainer.columns
        # var lineEditNo = gridContainer.get_child(no_idx)
        var checkBoxCheck = gridContainer.get_child(no_idx + 1)
        var lineEditDesc = gridContainer.get_child(no_idx + 2)
        var lineEditValue = gridContainer.get_child(no_idx + 3)
        # row is like {"no":1, "check":true, "description":"text", "value":1}
        var row = {
            "no": no,
            "check": checkBoxCheck.pressed,
            "description": Utils.text_to_value(lineEditDesc.text),
            "value": Utils.text_to_value(lineEditValue.text),
        }
        rows.append(row)
    emit_signal("change_table_rows", self.name, rows)

func _on_table_node_line_edit_change_value():
    if !skip_refresh_row:
        refresh_row()

func _on_button_delete_pressed(button):
    var row_number = get_row_number_of(button)
    delete_row(row_number)
    reset_no_columns()

func _on_button_add_row_pressed():
    add_row()
    reset_no_columns()

func _on_resize_request(new_minsize):
    self.rect_size = new_minsize

func _on_line_edit_name_text_changed(_new_text):
    emit_signal("change_name", self.name, lineEditName.text)

