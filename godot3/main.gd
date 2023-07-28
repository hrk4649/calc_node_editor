extends Control

var ValueNode = preload("res://value_node.tscn")
var OpNode = preload("res://op_node.tscn")
var NArrOpNode = preload("res://n_ary_op_node.tscn")
var TableNode = preload("res://table_node.tscn")
var FuncNode = preload("res://func_node.tscn")

const VALUE = Constraints.VALUE
const ADD = Constraints.ADD
const SUB = Constraints.SUB
const MUL = Constraints.MUL
const DIV = Constraints.DIV
const SUM = Constraints.SUM
const PROD = Constraints.PROD
const TABLE = Constraints.TABLE
const FUNC = Constraints.FUNC

onready var graphEdit = $HBoxContainer/GraphEdit
onready var fileDialog = $FileDialog
onready var exportDialog = $ExportDialog
onready var textEditExport = $ExportDialog/TextEditExport

var nodes = []

func _ready():
    pass

func generate_id():
    return Uuid.v4()


func find_my_node(id):
    for node in nodes:
        if node.id == id:
            return node
    return null

func find_node_ui(id):
    for child in graphEdit.get_children():
        if child.name == id:
            return child
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
    var input_nodes = []
    for id in node.input:
        var n = find_my_node(id)
        if n != null:
            input_nodes.append(n)

    var input_values = []
    for input_node in input_nodes:
        if input_node.has(VALUE):
            var value = input_node[VALUE]
            if value != null:
                input_values.append(value)

    var result = input_values
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
        ADD,SUB,MUL,DIV:
            process_node_2op(node)
        SUM:
            process_node_n_ary(node)
        PROD:
            process_node_n_ary(node)
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

    if !(typeof(input_value) in [TYPE_INT, TYPE_REAL]):
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
    
    if !(typeof(input_value) in [TYPE_INT, TYPE_REAL]):
        print("process_node_table:no int or float value:%s" % input_value)
        return
    
    # find row
    for row in node.row:
        print("typeof(row.min):%s" % typeof(row.min))
        print("typeof(input_value):%s" % typeof(input_value))
        print("typeof(string):%s" % typeof("abc"))
        var pass_min = (row.min == null || input_value >= float(row.min))
        var pass_max = (row.max == null || input_value < float(row.max))
        
        if pass_min && pass_max:
            node.value = row.value
            break

func process_node_n_ary(node):
    # set node.value
    if node.input.size() == 0:
        # do nothing
        pass
    elif is_input_available(node):
        var input_values = get_input_values(node)
        var result
        match node.type:
            SUM:
                result = 0
                for value in input_values:
                    result = result + value
            PROD:
                result = 1
                for value in input_values:
                    result = result * value
        node.value = result

func process_node_2op(node):
    if node.input.size() == 2 && node.input[0] != null && node.input[1] != null:
        var input_values = get_input_values(node)
        if input_values.size() == 2:
            var inputA = input_values[0]
            var inputB = input_values[1]
            var result = null
            match node.type:
                ADD:
                    result = inputA + inputB
                SUB:
                    result = inputA - inputB
                MUL:
                    result = inputA * inputB
                DIV:
                    if inputB != 0:
                        result = inputA / inputB
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
    var file = File.new()
    file.open(path, File.WRITE)
    var content = JSON.print(nodes)
    file.store_string(content)
    file.close()

func load_file(path):
    reset_data()
    var file = File.new()
    file.open(path, File.READ)
    var content = file.get_as_text()
    print("load_file:content:%s" % content)
    file.close()
    var result = JSON.parse(content)
    nodes = result.result
    initNodeUIs()
    yield(get_tree(), "idle_frame")
    arrange_nodes()

func initNodeUIs():
    var children = graphEdit.get_children()
    for child in children:
        var child_class = child.get_class()
        if child_class == "GraphNode":
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

func graphEdit_arrange_nodes():
    yield(get_tree(), "idle_frame")
#    for child in graphEdit.get_children():
#        var child_class = child.get_class()
#        if child_class == "GraphNode":
#            child.selected = true
    arrange_nodes()

func count_node_in_layers(layers):
    var count = 0
    for layer in layers:
        count = count + layer.size()
    return count

func add_node_layer(node, layers, layer_index):
    if layer_index >= layers.size():
        var need = (layer_index + 1) - layers.size()
        for _idx in range(0, need):
            layers.append([])
    var layer = layers[layer_index]
    var idx = layer.find(node)
    if idx == -1:
        layer.append(node)

func get_highest_layer(id_array, layers):
    var highest_layer = -1
    for id in id_array:
        var is_found = false
        for idx in range(0, layers.size()):
            var layer = layers[idx]
            for node in layer:
                if node.id == id:
                    is_found = true
                    break
            if is_found && highest_layer < idx:
                highest_layer = idx
                break
        
    return highest_layer

func arrange_nodes():
    var layers = []
    var loop_count = 0
    var max_loop_count = nodes.size()
    while true:
        pass
        var count1 = count_node_in_layers(layers)
        if count1 == nodes.size() || loop_count > max_loop_count:
            break
        loop_count = loop_count + 1
        for node in nodes:
            if get_highest_layer([node.id], layers) >= 0:
                continue
            if node.input.size() == 0:
                # add node layer 0
                add_node_layer(node, layers, 0)
            else:
                # 
                var highest_layer = get_highest_layer(node.input, layers)
                if highest_layer >= 0:
                    add_node_layer(node, layers, highest_layer + 1)
    var count2 = count_node_in_layers(layers)
    var origin = Vector2.ZERO
    var grid_size = get_grid_size()
    if count2 == nodes.size():
        for idx1 in range(0, layers.size()):
            var layer = layers[idx1]
            for idx2 in range(0, layer.size()):
                var node = layer[idx2]
                var node_ui = find_node_ui(node.id)
                var pos_x = grid_size.x * idx1 + (grid_size.x - node_ui.rect_size.x) / 2.0
                var pos_y = grid_size.y * idx2 + (grid_size.y - node_ui.rect_size.y) / 2.0
                var pos = origin + Vector2(pos_x, pos_y)
                node_ui.offset = pos

func get_grid_size():
    var max_size = Vector2(0,0)
    for node in nodes:
        var node_ui = find_node_ui(node.id)
        var ui_rect_size = node_ui.rect_size
        if ui_rect_size.x > max_size.x:
            max_size.x = ui_rect_size.x
        if ui_rect_size.y > max_size.y:
            max_size.y = ui_rect_size.y
    # widen for margin
    # max_size = max_size * 1.2
    var base_length = 160
    var num_grid_x = ceil(max_size.x / base_length)
    var num_grid_y = ceil(max_size.y / base_length)
    var result = Vector2(base_length * num_grid_x,base_length * num_grid_y)
    return result

func reset_data():
    nodes = []
    var children = graphEdit.get_children()
    for child in children:
        var child_class = child.get_class()
        if child_class == "GraphNode":
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
    var valueNode = ValueNode.instance()
    valueNode.name = node.id
    valueNode.connect("change_name", self, "_on_change_name")
    valueNode.connect("change_value", self, "_on_change_value")
    return valueNode

func create_add_op_node_ui(node):
    var opNode = OpNode.instance()
    opNode.name = node.id
    opNode.node_type = ADD
    opNode.title = "A + B"
    return opNode

func create_sub_op_node_ui(node):
    var opNode = OpNode.instance()
    opNode.name = node.id
    opNode.node_type = SUB
    opNode.title = "A - B"
    return opNode

func create_mul_op_node_ui(node):
    var opNode = OpNode.instance()
    opNode.name = node.id
    opNode.node_type = MUL
    opNode.title = "A x B"
    return opNode

func create_div_op_node_ui(node):
    var opNode = OpNode.instance()
    opNode.name = node.id
    opNode.node_type = DIV
    opNode.title = "A / B"
    return opNode

func create_sum_op_node_ui(node):
    var opNode = NArrOpNode.instance()
    opNode.name = node.id
    opNode.node_type = SUM
    opNode.title = "Σ"
    return opNode

func create_prod_op_node_ui(node):
    var opNode = NArrOpNode.instance()
    opNode.name = node.id
    opNode.node_type = PROD
    opNode.title = "Π"
    return opNode

func create_table_node_ui(node):
    var uiNode = TableNode.instance()
    uiNode.name = node.id
    uiNode.node_type = TABLE
    uiNode.connect("change_name", self, "_on_change_name")
    uiNode.connect("change_table_row", self, "_on_change_table_row")
    return uiNode

func create_func_node_ui(node):
    var uiNode = FuncNode.instance()
    uiNode.name = node.id
    uiNode.connect("change_func", self, "_on_change_func")
    return uiNode

func _on_change_table_row(id, row):
    print("_on_change_table_row:%s, %s" % [id, row])
    var node = find_my_node(id)
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
    var node = find_my_node(id)
    # set value if there is no input
    node.name = node_name

func _on_change_value(id, value):
    print("_on_change_value:%s, %s" % [id, value])
    var node = find_my_node(id)
    # set value if there is no input
    if node.input.size() == 0:
        node.value = Utils.text_to_value(value)
        calculate_nodes()
        reflect_values()

func _on_change_func(id, func_name):
    print("_on_change_func:%s, %s" % [id, func_name])
    var node = find_my_node(id)
    node.func_name = func_name
    calculate_nodes()
    reflect_values()

func _on_button_delete_pressed():
    for node_ui in graphEdit.get_children():
        var className = node_ui.get_class()
        if className == "GraphNode":
            if node_ui.selected:
                var to_remove = find_my_node(node_ui.get_name())
                remove_node(to_remove)
                graphEdit.remove_child(node_ui)
                break

func _on_graph_edit_connection_request(from_node, from_port, to_node, to_port):
    var from = find_my_node(from_node)
    var to = find_my_node(to_node)
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
    var from = find_my_node(from_node)
    var to = find_my_node(to_node)
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

func _on_button_new_pressed():
    reset_data()


func _on_button_save_pressed():
    pass # Replace with function body.
    fileDialog.mode = FileDialog.MODE_SAVE_FILE
    fileDialog.rect_size = self.rect_size * 0.8
    fileDialog.rect_position = self.rect_size * 0.5 - fileDialog.rect_size * 0.5
    fileDialog.show()

func _on_button_load_pressed():
    pass # Replace with function body.
    fileDialog.mode = FileDialog.MODE_OPEN_FILE
    fileDialog.rect_size = self.rect_size * 0.8
    fileDialog.rect_position = self.rect_size * 0.5 - fileDialog.rect_size * 0.5
    fileDialog.show()

func _on_file_dialog_file_selected(path):
    print("_on_file_dialog_file_selected:%s" % path)
    match fileDialog.mode:
        FileDialog.MODE_SAVE_FILE:
            save_file(path)
        FileDialog.MODE_OPEN_FILE:
            load_file(path)

func _on_button_arrange_nodes_pressed():
    graphEdit_arrange_nodes()

func _on_button_export_pressed():
    pass # Replace with function body.
    exportDialog.rect_size = self.rect_size * 0.8
    exportDialog.rect_position = self.rect_size * 0.5 - exportDialog.rect_size * 0.5
    var content = JSON.print(nodes)
    if content != null:
        textEditExport.text = content
    else:
        textEditExport.text = ""
    exportDialog.show()
