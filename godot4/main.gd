extends Control

var ValueNode = preload("res://value_node.tscn")
var OpNode = preload("res://op_node.tscn")
var NArrOpNode = preload("res://n_ary_op_node.tscn")

const VALUE = Constraints.VALUE
const ADD = Constraints.ADD
const SUB = Constraints.SUB
const MUL = Constraints.MUL
const DIV = Constraints.DIV
const SUM = Constraints.SUM

@onready var graphEdit = $HBoxContainer/GraphEdit

var nodes = []

func _ready():
	pass

func generate_id():
	return Uuid.v4()

func find_node(id):
	var candidates = nodes.filter(func(node):return node.id == id)
	if candidates.size() != 1:
		return null
	return candidates[0]

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
	var input_nodes = node.input.map(func(id):return find_node(id)).filter(func(node): return node != null)
	var input_values = input_nodes.map(func(node):if node.has(VALUE):return node.value else: return null)
	var result = input_values.filter(func(v):return v != null)
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
			process_node_n_ary(node, proc)
		_:
			print("unsupported type:%s" % node.type)

func process_node_n_ary(node, proc):
	# set node.value
	if node.input.size() == 0:
		# do nothing
		pass
	elif is_input_available(node):
		var input_values = get_input_values(node)
		var result = input_values.reduce(proc,0)
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
	var children = graphEdit.get_children()
	for node in nodes:
		if !is_constant(node):
			var cands = children.filter(func(child): return child.get_name() == node.id)
			if cands.size() == 1:
				var child = cands[0]
				if child.node_type == VALUE:
					child.set_value(node.value)

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
		node.value = value
		calculate_nodes()
		reflect_values()

func _on_button_value_node_pressed():
	var valueNode = ValueNode.instantiate()
	valueNode.name = generate_id()
	valueNode.connect("change_name", Callable(self, "_on_change_name"))
	valueNode.connect("change_value", Callable(self, "_on_change_value"))
	graphEdit.add_child(valueNode)
	var node = {
		"id": valueNode.name,
		"type": VALUE,
		"name": null,
		"value": null,
		"input": [],
		"output": []
	}
	nodes.append(node)

func _on_button_add_op_node_pressed():
	var opNode = OpNode.instantiate()
	opNode.name = generate_id()
	opNode.node_type = ADD
	opNode.title = "A + B"
	graphEdit.add_child(opNode)
	var node = {
		"id": opNode.name,
		"type": ADD,
		"value": null,
		"input": [null, null],
		"output": []
	}
	nodes.append(node)


func _on_button_sub_op_node_pressed():
	var opNode = OpNode.instantiate()
	opNode.name = generate_id()
	opNode.node_type = SUB
	opNode.title = "A - B"
	graphEdit.add_child(opNode)
	var node = {
		"id": opNode.name,
		"type": SUB,
		"value": null,
		"input": [null, null],
		"output": []
	}
	nodes.append(node)


func _on_button_mul_op_node_pressed():
	var opNode = OpNode.instantiate()
	opNode.name = generate_id()
	opNode.node_type = MUL
	opNode.title = "A x B"
	graphEdit.add_child(opNode)
	var node = {
		"id": opNode.name,
		"type": MUL,
		"value": null,
		"input": [null, null],
		"output": []
	}
	nodes.append(node)

func _on_button_div_op_node_pressed():
	var opNode = OpNode.instantiate()
	opNode.name = generate_id()
	opNode.node_type = DIV
	opNode.title = "A / B"
	graphEdit.add_child(opNode)
	var node = {
		"id": opNode.name,
		"type": DIV,
		"value": null,
		"input": [null, null],
		"output": []
	}
	nodes.append(node)

func _on_button_sum_op_node_pressed():
	var opNode = NArrOpNode.instantiate()
	opNode.name = generate_id()
	opNode.node_type = SUM
	opNode.title = "Σ"
	graphEdit.add_child(opNode)
	var node = {
		"id": opNode.name,
		"type": SUM,
		"value": null,
		"input": [],
		"output": []
	}
	nodes.append(node)

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

func _on_button_list_pressed():
	print("_on_button_list_pressed()")
#	for child in graphEdit.get_children():
#		print("GraphNode:%s %s" % [child, child.get_name()])
	for node in nodes:
		print("node:%s" % node)
#	for dict in graphEdit.get_connection_list():
#		print("connection:%s" % [dict])

