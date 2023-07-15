extends Control

var ValueNode = preload("res://value_node.tscn")
var OpNode = preload("res://op_node.tscn")
var AddOpNode = preload("res://add_op_node.tscn")

const VALUE = Constraints.VALUE
const OPERATOR = Constraints.OPERATOR
const ADD = Constraints.ADD

@onready var graphEdit = $HBoxContainer/GraphEdit

var nodes = []

func _ready():
	pass

func generate_id():
	#return int(Time.get_unix_time_from_system() * 1000)
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
			# set node.value into one.value in output
			if node.value != null && node.output.size() > 0:
				var output_nodes = node.output.map(func(id):return find_node(id))
				for output_node in output_nodes:
					output_node.value = node.value
		OPERATOR:
			process_node_sum(node)
		ADD:
			process_node_sum(node)
		_:
			print("unsupported type:%s" % node.type)

func process_node_sum(node):
	# set node.value
	if node.input.size() == 0:
		# do nothing
		pass
	elif is_input_available(node):
		var input_values = get_input_values(node)
		# now operator is summation
		var sum = input_values.reduce(func(accum, elem):return accum + elem,0)
		node.value = sum
	# set node.value into one.value in output
	if node.value != null && node.output.size() > 0:
		var output_nodes = node.output.map(func(id):return find_node(id))
		for output_node in output_nodes:
			output_node.value = node.value	

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
#			for child in children:
#				print("reflect_values:child:%s %s" % [child, child.get_name()])
#				if child.get_name() == node.id:
#					child.set_value(node.value)
			var cands = children.filter(func(child): return child.get_name() == node.id)
			if cands.size() == 1:
				var child = cands[0]
				if child.get_type() == VALUE:
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

func _on_button_op_node_pressed():
	var opNode = OpNode.instantiate()
	opNode.name = generate_id()
	graphEdit.add_child(opNode)
	var node = {
		"id": opNode.name,
		"type": OPERATOR,
		"value": null,
		"input": [],
		"output": []
	}
	nodes.append(node)

func _on_button_add_op_node_pressed():
	var addOpNode = AddOpNode.instantiate()
	addOpNode.name = generate_id()
	graphEdit.add_child(addOpNode)
	var node = {
		"id": addOpNode.name,
		"type": ADD,
		"value": null,
		"input": [null, null],
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
		
	# check number of input
	if to.type in [ADD]:
		if to.input[to_port] != null:
			# cancel
			return
		
	# add to.id into from.output
	if from.output.find(to.id) < 0:
		from.output.append(to.id)
	# add from.id into to.input
	match to.type:
		ADD:
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
		ADD:
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
	for child in graphEdit.get_children():
		print("GraphNode:%s %s" % [child, child.get_name()])
	for node in nodes:
		print("node:%s" % node)
	for dict in graphEdit.get_connection_list():
		print("connection:%s" % [dict])



