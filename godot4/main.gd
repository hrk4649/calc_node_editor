extends Control

var ValueNode = preload("res://value_node.tscn")
var OpNode = preload("res://op_node.tscn")
var NArrOpNode = preload("res://n_ary_op_node.tscn")
var TableNode = preload("res://table_node.tscn")
var FuncNode = preload("res://func_node.tscn")

var AboutResource = preload("res://about_resource.tres")

const VALUE = Constraints.VALUE
const ADD = Constraints.ADD
const SUB = Constraints.SUB
const MUL = Constraints.MUL
const DIV = Constraints.DIV
const SUM = Constraints.SUM
const PROD = Constraints.PROD
const TABLE = Constraints.TABLE
const FUNC = Constraints.FUNC

@onready var graphEdit = $VBoxContainer/HBoxContainer/GraphEdit

@onready var fileDialog = $FileDialog
@onready var exportDialog = $ExportDialog
@onready var textEditExport = $ExportDialog/TextEditExport
@onready var importDialog = $ImportDialog
@onready var textEditImport = $ImportDialog/TextEditImport
@onready var aboutDialog = $AboutDialog
@onready var textEditAbout = $AboutDialog/TextEditAbout

@onready var popupMenuFile = $VBoxContainer/MenuBar/File
@onready var popupMenuEdit = $VBoxContainer/MenuBar/Edit
@onready var popupMenuHelp = $VBoxContainer/MenuBar/Help

var nodes = []

func _ready():
	pass

func generate_id():
	return Uuid.v4()

func find_node(id):
	var f = func(node):return node.id == id
	var candidates = nodes.filter(f)
	if candidates.size() != 1:
		return null
	return candidates[0]

func find_node_ui(id):
	var f = func(child):return child.name == id
	var node_uis = graphEdit.get_children().filter(f)
	if node_uis.size() == 1:
		return node_uis[0]
	return null

func is_constant(node):
	return (node.type == VALUE &&
			node.input.size() == 0)

func remove_node(to_remove):
	pass
	# remove id in input and output
	for node in nodes:
		if node == to_remove:
			continue
		# care node.input's size
		match node.type:
			ADD,SUB,MUL,DIV:
				for idx in range(0,2):
					if node.input[idx] == to_remove.id:
						node.input[idx] = null
			_:
				node.input.erase(to_remove.id)
		node.output.erase(to_remove.id)
	nodes.erase(to_remove)

func get_input_values(node):
	var not_null = func(v): return v != null
	var f1 = func(id):return find_node(id)
	var input_nodes = node.input.map(f1).filter(not_null)
	var f2 = func(node):
		if node.has(VALUE):
			return node.value
		else: return null
	var input_values = input_nodes.map(f2)
	var result = input_values.filter(not_null)
	return result

func can_process_node(node):
	if node.input.size() == 0:
		return true
	else:
		var input_values = get_input_values(node)
		if input_values.size() == node.input.size():
			return true
	return false

func is_input_available(node):
	var input_values = get_input_values(node)
	return node.input.size() > 0 && input_values.size() == node.input.size()

func process_node(node):
	match node.type:
		VALUE:
			# set node.value
			if node.input.size() == 0:
				# do nothing
				pass
			elif is_input_available(node) && node.input.size() == 1:
				var input_values = get_input_values(node)
				if input_values.size() == 1:
					node.value = input_values[0]
		ADD:
			var proc = func add(a,b):return a + b
			process_node_2op(node, proc)
		SUB:
			var proc = func sub(a,b):return a - b
			process_node_2op(node, proc)
		MUL:
			var proc = func mul(a,b):return a * b
			process_node_2op(node, proc)
		DIV:
			var proc = func div(a,b):
				if b == 0:
					return null
				else:
					return a / b
			process_node_2op(node, proc)
		SUM:
			var proc = func(accum, elem): return accum + elem
			process_node_n_ary(node, proc, 0)
		PROD:
			var proc = func(accum, elem): return accum * elem
			process_node_n_ary(node, proc, 1)
		TABLE:
			process_node_table(node)
		FUNC:
			process_node_func(node)
		_:
			print("unsupported type:%s" % node.type)

func process_node_func(node):
	if node.input.size() != 1:
		print("process_node_func:no input")
		return
	var input_values = get_input_values(node)
	if input_values.size() != 1:
		print("process_node_func:no input value")
		return
	var input_value = input_values[0]	

	if !(typeof(input_value) in [TYPE_INT, TYPE_FLOAT]):
		print("process_node_func:no int or float value:%s" % input_value)
		return

	match node.func_name:
		"round":
			node.value = round(input_value)
		"floor":
			node.value = floor(input_value)
		"ceil":
			node.value = ceil(input_value)			
		"sin":
			node.value = sin(input_value)
		_:
			print("process_node_func:unsupported func name:%s" % node.func_name)


func process_node_table(node):
	if node.input.size() != 1:
		print("process_node_table:no input")
		return
	var input_values = get_input_values(node)
	if input_values.size() != 1:
		print("process_node_table:no input value")
		return
	var input_value = input_values[0]
	
	if !(typeof(input_value) in [TYPE_INT, TYPE_FLOAT]):
		print("process_node_table:no int or float value:%s" % input_value)
		return
	
	# find row
	for row in node.row:
		var pass_min = (row.min == null || input_value >= float(row.min))
		var pass_max = (row.max == null || input_value < float(row.max))
		
		if pass_min && pass_max:
			node.value = row.value
			break

func process_node_n_ary(node, proc, initValue):
	# set node.value
	if node.input.size() == 0:
		# do nothing
		pass
	elif is_input_available(node):
		var input_values = get_input_values(node)
		var result = input_values.reduce(proc, initValue)
		node.value = result

func process_node_2op(node, lambda):
	if node.input.size() == 2 && node.input[0] != null && node.input[1] != null:
		var input_values = get_input_values(node)
		if input_values.size() == 2:
			var inputA = input_values[0]
			var inputB = input_values[1]
			var result = lambda.call(inputA, inputB)
			node.value = result

func calculate_nodes():
	# reset value
	for node in nodes:
		if !is_constant(node):
			node.value = null

	var loopCount = 0
	var processed = []
	while processed.size() < nodes.size() && loopCount < 10:
		loopCount = loopCount + 1
		for node in nodes:
			if node in processed:
				continue
			if can_process_node(node):
				process_node(node)
				processed.append(node)

func reflect_values():
	for node in nodes:
		var child = find_node_ui(node.id)
		if child == null:
			continue
		if !is_constant(node) && child.node_type == VALUE:
			child.set_value(node.value)

func save_file(path):
	var file = FileAccess.open(path, FileAccess.WRITE)
	var content = JSON.stringify(nodes)
	file.store_string(content)

func load_file(path):
	reset_data()
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	load_json(content)

func load_json(content):
	nodes = JSON.parse_string(content)
	initNodeUIs()

func initNodeUIs():
	var children = graphEdit.get_children()
	for child in children:
		graphEdit.remove_child(child)

	# create node ui
	for node in nodes:
		var node_ui = null
		match node.type:
			VALUE:
				node_ui = create_value_node_ui(node)
			ADD:
				node_ui = create_add_op_node_ui(node)
			SUB:
				node_ui = create_sub_op_node_ui(node)
			MUL:
				node_ui = create_mul_op_node_ui(node)
			DIV:
				node_ui = create_div_op_node_ui(node)
			SUM:
				node_ui = create_sum_op_node_ui(node)
			PROD:
				node_ui = create_prod_op_node_ui(node)
			TABLE:
				node_ui = create_table_node_ui(node)
			FUNC:
				node_ui = create_func_node_ui(node)
			_:
				print("unexpected type:%s" % node.type)
		if node_ui != null:
			graphEdit.add_child(node_ui)

	# create edges
	for node in nodes:
		for input_idx in range(0, node.input.size()):
			var input_id = node.input[input_idx]
			var to_port = 0
			if node.type in [ADD,SUB,MUL,DIV]:
				to_port = input_idx
			graphEdit.connect_node(input_id, 0, node.id, to_port)

	for node in nodes:
		var node_ui = find_node_ui(node.id)
		if node_ui == null:
			continue
		# set names
		if node.type in [VALUE, TABLE]:
			if node.has("name") && node.name != null:
				node_ui.set_node_name(node.name)
		# set func_name
		if node.type == FUNC:
			if node.has("func_name") && node.func_name != null:
				node_ui.set_func_name(node.func_name)
		# set value
		if is_constant(node):
			node_ui.set_value(node.value)
		# set row
		if node.type == TABLE && node.has("row"):
			node_ui.init_row(node.row)

	reflect_values()
	graphEdit_arrange_nodes()

func graphEdit_arrange_nodes():
	await get_tree().process_frame
	for child in graphEdit.get_children():
		child.selected = true
	graphEdit.arrange_nodes()
	
func reset_data():
	nodes = []
	var children = graphEdit.get_children()
	for child in children:
		graphEdit.remove_child(child)

func create_value_node():
	return {
		"id": generate_id(),
		"type": VALUE,
		"name": null,
		"value": null,
		"input": [],
		"output": []
	}

func create_add_op_node():
	return {
		"id": generate_id(),
		"type": ADD,
		"value": null,
		"input": [null, null],
		"output": []
	}
	
func create_sub_op_node():
	return {
		"id": generate_id(),
		"type": SUB,
		"value": null,
		"input": [null, null],
		"output": []
	}

func create_mul_op_node():
	return {
		"id": generate_id(),
		"type": MUL,
		"value": null,
		"input": [null, null],
		"output": []
	}

func create_div_op_node():
	return {
		"id": generate_id(),
		"type": DIV,
		"value": null,
		"input": [null, null],
		"output": []
	}

func create_sum_op_node():
	return {
		"id": generate_id(),
		"type": SUM,
		"value": null,
		"input": [],
		"output": []
	}

func create_prod_op_node():
	return {
		"id": generate_id(),
		"type": PROD,
		"value": null,
		"input": [],
		"output": []
	}

func create_table_node():
	return {
		"id": generate_id(),
		"type": TABLE,
		# row is like {"no":1, "min":0, "max":100, "value":1}
		"row": [],
		"value": null,
		"input": [],
		"output": []
	}

func create_func_node():
	return {
		"id": generate_id(),
		"type": FUNC,
		"func_name": null,
		"value": null,
		"input": [],
		"output": []
	}


func create_value_node_ui(node):
	var valueNode = ValueNode.instantiate()
	valueNode.name = node.id
	valueNode.connect("change_name", Callable(self, "_on_change_name"))
	valueNode.connect("change_value", Callable(self, "_on_change_value"))
	return valueNode

func create_add_op_node_ui(node):
	var opNode = OpNode.instantiate()
	opNode.name = node.id
	opNode.node_type = ADD
	opNode.title = "A + B"
	return opNode

func create_sub_op_node_ui(node):
	var opNode = OpNode.instantiate()
	opNode.name = node.id
	opNode.node_type = SUB
	opNode.title = "A - B"
	return opNode

func create_mul_op_node_ui(node):
	var opNode = OpNode.instantiate()
	opNode.name = node.id
	opNode.node_type = MUL
	opNode.title = "A x B"
	return opNode

func create_div_op_node_ui(node):
	var opNode = OpNode.instantiate()
	opNode.name = node.id
	opNode.node_type = DIV
	opNode.title = "A / B"
	return opNode

func create_sum_op_node_ui(node):
	var opNode = NArrOpNode.instantiate()
	opNode.name = node.id
	opNode.node_type = SUM
	opNode.title = "Σ"
	return opNode

func create_prod_op_node_ui(node):
	var opNode = NArrOpNode.instantiate()
	opNode.name = node.id
	opNode.node_type = PROD
	opNode.title = "Π"
	return opNode

func create_table_node_ui(node):
	var uiNode = TableNode.instantiate()
	uiNode.name = node.id
	uiNode.node_type = TABLE
	uiNode.connect("change_name", Callable(self, "_on_change_name"))
	uiNode.connect("change_table_row", Callable(self, "_on_change_table_row"))
	return uiNode

func create_func_node_ui(node):
	var uiNode = FuncNode.instantiate()
	uiNode.name = node.id
	uiNode.connect("change_func", Callable(self, "_on_change_func"))
	return uiNode

func _on_change_table_row(id, row):
	print("_on_change_table_row:%s, %s" % [id, row])
	var node = find_node(id)
	node.row = row
	calculate_nodes()
	reflect_values()

func _on_button_value_node_pressed():
	var node = create_value_node()
	var node_ui = create_value_node_ui(node)
	graphEdit.add_child(node_ui)
	nodes.append(node)

func _on_button_add_op_node_pressed():
	var node = create_add_op_node()
	var node_ui = create_add_op_node_ui(node)
	graphEdit.add_child(node_ui)
	nodes.append(node)

func _on_button_sub_op_node_pressed():
	var node = create_sub_op_node()
	var node_ui = create_sub_op_node_ui(node)
	graphEdit.add_child(node_ui)
	nodes.append(node)

func _on_button_mul_op_node_pressed():
	var node = create_mul_op_node()
	var node_ui = create_mul_op_node_ui(node)
	graphEdit.add_child(node_ui)
	nodes.append(node)

func _on_button_div_op_node_pressed():
	var node = create_div_op_node()
	var node_ui = create_div_op_node_ui(node)
	graphEdit.add_child(node_ui)
	nodes.append(node)

func _on_button_sum_op_node_pressed():
	var node = create_sum_op_node()
	var node_ui = create_sum_op_node_ui(node)
	graphEdit.add_child(node_ui)
	nodes.append(node)

func _on_button_prod_op_node_pressed():
	var node = create_prod_op_node()
	var node_ui = create_prod_op_node_ui(node)
	graphEdit.add_child(node_ui)
	nodes.append(node)

func _on_button_table_node_pressed():
	var node = create_table_node()
	var node_ui = create_table_node_ui(node)
	graphEdit.add_child(node_ui)
	nodes.append(node)

func _on_button_func_node_pressed():
	var node = create_func_node()
	var node_ui = create_func_node_ui(node)
	graphEdit.add_child(node_ui)
	nodes.append(node)

func _on_change_name(id, node_name):
	print("_on_change_name:%s, %s" % [id, node_name])
	var node = find_node(id)
	# set value if there is no input
	node.name = node_name

func _on_change_value(id, value):
	print("_on_change_value:%s, %s" % [id, value])
	var node = find_node(id)
	# set value if there is no input
	if node.input.size() == 0:
		node.value = Utils.text_to_value(value)
		calculate_nodes()
		reflect_values()

func _on_change_func(id, func_name):
	print("_on_change_func:%s, %s" % [id, func_name])
	var node = find_node(id)
	node.func_name = func_name
	calculate_nodes()
	reflect_values()

func _on_button_delete_pressed():
	for node in graphEdit.get_children():
		var className = node.get_class()
		if className == "GraphNode":
			if node.selected:
				var to_remove = find_node(node.get_name())
				remove_node(to_remove)
				graphEdit.remove_child(node)
				break

func _on_graph_edit_connection_request(from_node, from_port, to_node, to_port):
	var from = find_node(from_node)
	var to = find_node(to_node)
	if from == null:
		print("from_node %s is not found" % from_node)
		return
	if to == null:
		print("to_node %s is not found" % to_node)
		return
		
	# check if input is already set
	if to.type in [ADD, SUB, MUL, DIV]:
		if to.input[to_port] != null:
			# cancel
			return
		
	# add to.id into from.output
	if from.output.find(to.id) < 0:
		from.output.append(to.id)
	# add from.id into to.input
	match to.type:
		ADD,SUB,MUL,DIV:
			to.input[to_port] = from.id
		_:
			if to.input.find(from.id) < 0:
				to.input.append(from.id)
	
	graphEdit.connect_node(from_node, from_port, to_node, to_port)
	calculate_nodes()
	reflect_values()

func _on_graph_edit_disconnection_request(from_node, from_port, to_node, to_port):
	var from = find_node(from_node)
	var to = find_node(to_node)
	if from == null:
		print("from_node %s is not found" % from_node)
		return
	if to == null:
		print("to_node %s is not found" % to_node)
		return
	# remove to.id from.output
	from.output.erase(to.id)

	match to.type:
		ADD,SUB,MUL,DIV:
			# set null
			to.input[to_port] = null
		_:
			# remove from.id from to.input
			to.input.erase(from.id)

	graphEdit.disconnect_node(from_node, from_port, to_node, to_port)
	calculate_nodes()
	reflect_values()

func _on_button_new_pressed():
	reset_data()

func _on_button_save_pressed():
	pass # Replace with function body.
	fileDialog.file_mode = FileDialog.FileMode.FILE_MODE_SAVE_FILE
	fileDialog.size = self.size * 0.8
	fileDialog.position = self.size * 0.5 - fileDialog.size * 0.5
	fileDialog.show()

func _on_button_load_pressed():
	pass # Replace with function body.
	fileDialog.file_mode = FileDialog.FileMode.FILE_MODE_OPEN_FILE
	fileDialog.size = self.size * 0.8
	fileDialog.position = self.size * 0.5 - fileDialog.size * 0.5
	fileDialog.show()

func _on_file_dialog_file_selected(path):
	print("_on_file_dialog_file_selected:%s" % path)
	match fileDialog.file_mode:
		FileDialog.FileMode.FILE_MODE_SAVE_FILE:
			save_file(path)
		FileDialog.FileMode.FILE_MODE_OPEN_FILE:
			load_file(path)

func _on_button_arrange_nodes_pressed():
	graphEdit_arrange_nodes()

func _on_button_export_pressed():
	exportDialog.size = self.size * 0.8
	exportDialog.position = self.size * 0.5 - exportDialog.size * 0.5
	var content = JSON.stringify(nodes)
	if content != null:
		textEditExport.text = content
	else:
		textEditExport.text = ""
	exportDialog.show()

func _on_button_import_pressed():
	importDialog.size = self.size * 0.8
	importDialog.position = self.size * 0.5 - importDialog.size * 0.5
	textEditImport.text = ""
	importDialog.show()

func _on_import_dialog_confirmed():
	var content = textEditImport.text
	load_json(content)

func _on_button_about_pressed():
	aboutDialog.size = self.size * 0.8
	aboutDialog.position = self.size * 0.5 - aboutDialog.size * 0.5
	textEditAbout.text = AboutResource.text
	aboutDialog.show()	

func _on_file_id_pressed(id):
	var idx = popupMenuFile.get_item_index(id)
	var text = popupMenuFile.get_item_text(idx)
	match text:
		"New":
			_on_button_new_pressed()
		"Save":
			_on_button_save_pressed()
		"Load":
			_on_button_load_pressed()
		"Export":
			_on_button_export_pressed()
		"Import":
			_on_button_import_pressed()
		_:
			print("unexpected menu item:%s" % text)

func _on_edit_id_pressed(id):
	var idx = popupMenuEdit.get_item_index(id)
	var text = popupMenuEdit.get_item_text(idx)
	match text:
		"Delete":
			_on_button_delete_pressed()
		"Value":
			_on_button_value_node_pressed()
		"A + B":
			_on_button_add_op_node_pressed()
		"A - B":
			_on_button_sub_op_node_pressed()
		"A x B":
			_on_button_mul_op_node_pressed()
		"A / B":
			_on_button_div_op_node_pressed()
		"Σ":
			_on_button_sum_op_node_pressed()
		"Π":
			_on_button_prod_op_node_pressed()
		"Table":
			_on_button_table_node_pressed()
		"Function":
			_on_button_func_node_pressed()
		"Arrnage Nodes":
			_on_button_arrange_nodes_pressed()
		_:
			print("unexpected menu item:%s" % text)

func _on_help_index_pressed(idx):
	var text = popupMenuHelp.get_item_text(idx)
	match text:
		"About":
			_on_button_about_pressed()
		_:
			print("unexpected menu item:%s" % text)
