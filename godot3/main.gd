extends Control

var ValueNode = preload("res://value_node.tscn")
var OpNode = preload("res://op_node.tscn")
var NArrOpNode = preload("res://n_ary_op_node.tscn")
var TableNode = preload("res://table_node.tscn")
var OptionNode = preload("res://option_node.tscn")
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
const OPTION = Constraints.OPTION
const FUNC = Constraints.FUNC

onready var graphEdit = $VBoxContainer/HBoxContainer/GraphEdit
onready var fileDialog = $FileDialog
onready var exportDialog = $ExportDialog
onready var textEditExport = $ExportDialog/TextEditExport
onready var importDialog = $ImportDialog
onready var textEditImport = $ImportDialog/TextEditImport
onready var aboutDialog = $AboutDialog
onready var textEditAbout = $AboutDialog/TextEditAbout

onready var popupMenuFile = $VBoxContainer/HBoxContainer2/MenuButtonFile
onready var popupMenuEdit = $VBoxContainer/HBoxContainer2/MenuButtonEdit
onready var popupMenuHelp = $VBoxContainer/HBoxContainer2/MenuButtonHelp

var nodes = []

func _ready():
    initMenuButton()

func initMenuButton():
    popupMenuFile.get_popup().connect("index_pressed", self, "_on_file_index_pressed")
    popupMenuEdit.get_popup().connect("index_pressed", self, "_on_edit_index_pressed")
    popupMenuHelp.get_popup().connect("index_pressed", self, "_on_help_index_pressed")

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
        OPTION:
            process_node_option(node)
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
    for row in node.rows:
        print("typeof(row.min):%s" % typeof(row.min))
        print("typeof(input_value):%s" % typeof(input_value))
        print("typeof(string):%s" % typeof("abc"))
        var pass_min = (row.min == null || input_value >= float(row.min))
        var pass_max = (row.max == null || input_value < float(row.max))
        
        if pass_min && pass_max:
            node.value = row.value
            break

func process_node_option(node):
    # find row
    for row in node.rows:
        var row_check = (row.has("check") && row.check == true)
        
        if row_check:
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
    var max_loop_count = nodes.size()
    var processed = []
    while processed.size() < nodes.size() && loopCount < max_loop_count:
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

func create_data_content():
    var data = {
        "version":1,
        "nodes":nodes
       }
    var content = JSON.print(data)
    return content

func save_file(path):
    var file = File.new()
    file.open(path, File.WRITE)
    var content = create_data_content()
    file.store_string(content)
    file.close()

func load_file(path):
    reset_data()
    var file = File.new()
    file.open(path, File.READ)
    var content = file.get_as_text()
    print("load_file:content:%s" % content)
    file.close()
    load_json(content)

func load_json(content):
    var parseResult = JSON.parse(content)
    if parseResult.result.has("version"):
        var version = parseResult.result["version"]
        # TODO show message
        if version != 1:
            print("unexpected format version:%s" % version)
    if parseResult.result.has("nodes"):
        nodes = parseResult.result["nodes"]
    else:
        nodes = parseResult.result
    initNodeUIs()
    yield(get_tree(), "idle_frame")
    # arrange_nodes()

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
            OPTION:
                node_ui = create_option_node_ui(node)
            FUNC:
                node_ui = create_func_node_ui(node)
            _:
                print("unexpected type:%s" % node.type)
        if node_ui != null:
            read_size_position(node, node_ui)
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
        if node.type in [VALUE, TABLE, OPTION]:
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
        if node.type in [TABLE, OPTION] && node.has("rows"):
            node_ui.init_rows(node.rows)

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
                var found_in_layers = 0
                for input in node.input:
                    var v = get_highest_layer([input], layers)
                    if v >= 0:
                        found_in_layers = found_in_layers + 1
                if found_in_layers == node.input.size():
                    var highest_layer = get_highest_layer(node.input, layers)
                    if highest_layer >= 0:
                        add_node_layer(node, layers, highest_layer + 1)
    var count2 = count_node_in_layers(layers)
    var origin = Vector2.ZERO
    var prev_layer_origin = origin
    if count2 == nodes.size():
        for idx1 in range(0, layers.size()):
            var layer = layers[idx1]
            var grid_size = get_grid_size(layer)
            for idx2 in range(0, layer.size()):
                var node = layer[idx2]
                var node_ui = find_node_ui(node.id)
                var pos_x = (grid_size.x - node_ui.rect_size.x) / 2.0
                var pos_y = grid_size.y * idx2 + (grid_size.y - node_ui.rect_size.y) / 2.0
                var pos = origin + Vector2(pos_x, pos_y)
                if idx2 == 0:
                    prev_layer_origin = origin + Vector2(grid_size.x, 0)
                node_ui.offset = pos
            origin = prev_layer_origin

func get_grid_size(layer):
    var max_size = Vector2(0,0)
    for node in layer:
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
        "rows": [],
        "value": null,
        "input": [],
        "output": []
    }

func create_option_node():
    return {
        "id": generate_id(),
        "type": OPTION,
        # row is like {"no":1, "check":true, "description":"text", "value":1}
        "rows": [],
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

func read_size_position(node, node_ui):
    if node.has("ui_size"):
        var vec = node["ui_size"]
        # ui_size is like {"x":123, "y":456}
        if vec.has("x") and vec.has("y"):
            var x = vec["x"]
            var y = vec["y"]
            var v = Vector2(x,y)
            node_ui.rect_size = v
    if node.has("ui_position"):
        var vec = node["ui_position"]
        # ui_position is like {"x":123, "y":456}
        if vec.has("x") and vec.has("y"):
            var x = vec["x"]
            var y = vec["y"]
            var v = Vector2(x,y)
            node_ui.offset = v

func write_size_position(node, node_ui):
    node["ui_size"] = {
        "x": node_ui.rect_size.x,
        "y": node_ui.rect_size.y
       }
    node["ui_position"] = {
        "x": node_ui.offset.x,
        "y": node_ui.offset.y
       }

func write_node_ui_size_position():
    for node in nodes:
        var node_ui = find_node_ui(node.id)
        if node_ui != null:
            write_size_position(node, node_ui)

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
    opNode.title = "SUM"
    return opNode

func create_prod_op_node_ui(node):
    var opNode = NArrOpNode.instance()
    opNode.name = node.id
    opNode.node_type = PROD
    opNode.title = "PROD"
    return opNode

func create_table_node_ui(node):
    var uiNode = TableNode.instance()
    uiNode.name = node.id
    uiNode.node_type = TABLE
    uiNode.connect("change_name", self, "_on_change_name")
    uiNode.connect("change_table_rows", self, "_on_change_table_rows")
    return uiNode

func create_option_node_ui(node):
    var uiNode = OptionNode.instance()
    uiNode.name = node.id
    #uiNode.node_type = TABLE
    uiNode.connect("change_name", self, "_on_change_name")
    uiNode.connect("change_table_rows", self, "_on_change_table_rows")
    return uiNode

func create_func_node_ui(node):
    var uiNode = FuncNode.instance()
    uiNode.name = node.id
    uiNode.connect("change_func", self, "_on_change_func")
    return uiNode

func move_to_center(node_ui):
    var center = ((graphEdit.rect_size / 2.0 + graphEdit.scroll_offset) 
        / graphEdit.zoom)
    node_ui.offset = center

func _on_change_table_rows(id, rows):
    print("_on_change_table_rows:%s, %s" % [id, rows])
    var node = find_my_node(id)
    node.rows = rows
    calculate_nodes()
    reflect_values()

func _on_change_option_row(id, rows):
    print("_on_change_option_row:%s, %s" % [id, rows])
    var node = find_my_node(id)
    node.rows = rows
    calculate_nodes()
    reflect_values()

func _on_button_value_node_pressed():
    var node = create_value_node()
    var node_ui = create_value_node_ui(node)
    move_to_center(node_ui)
    graphEdit.add_child(node_ui)
    nodes.append(node)

func _on_button_add_op_node_pressed():
    var node = create_add_op_node()
    var node_ui = create_add_op_node_ui(node)
    move_to_center(node_ui)
    graphEdit.add_child(node_ui)
    nodes.append(node)

func _on_button_sub_op_node_pressed():
    var node = create_sub_op_node()
    var node_ui = create_sub_op_node_ui(node)
    move_to_center(node_ui)
    graphEdit.add_child(node_ui)
    nodes.append(node)

func _on_button_mul_op_node_pressed():
    var node = create_mul_op_node()
    var node_ui = create_mul_op_node_ui(node)
    move_to_center(node_ui)
    graphEdit.add_child(node_ui)
    nodes.append(node)

func _on_button_div_op_node_pressed():
    var node = create_div_op_node()
    var node_ui = create_div_op_node_ui(node)
    move_to_center(node_ui)
    graphEdit.add_child(node_ui)
    nodes.append(node)

func _on_button_sum_op_node_pressed():
    var node = create_sum_op_node()
    var node_ui = create_sum_op_node_ui(node)
    move_to_center(node_ui)
    graphEdit.add_child(node_ui)
    nodes.append(node)

func _on_button_prod_op_node_pressed():
    var node = create_prod_op_node()
    var node_ui = create_prod_op_node_ui(node)
    move_to_center(node_ui)
    graphEdit.add_child(node_ui)
    nodes.append(node)

func _on_button_table_node_pressed():
    var node = create_table_node()
    var node_ui = create_table_node_ui(node)
    move_to_center(node_ui)
    graphEdit.add_child(node_ui)
    nodes.append(node)

func _on_button_option_node_pressed():
    var node = create_option_node()
    var node_ui = create_option_node_ui(node)
    move_to_center(node_ui)
    graphEdit.add_child(node_ui)
    nodes.append(node)

func _on_button_func_node_pressed():
    var node = create_func_node()
    var node_ui = create_func_node_ui(node)
    move_to_center(node_ui)
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
            write_node_ui_size_position()
            save_file(path)
        FileDialog.MODE_OPEN_FILE:
            load_file(path)

func _on_button_arrange_nodes_pressed():
    graphEdit_arrange_nodes()

func _on_button_export_pressed():
    exportDialog.rect_size = self.rect_size * 0.8
    exportDialog.rect_position = self.rect_size * 0.5 - exportDialog.rect_size * 0.5
    write_node_ui_size_position()
    var content = create_data_content()
    if content != null:
        textEditExport.text = content
    else:
        textEditExport.text = ""
    exportDialog.show()

func _on_button_import_pressed():
    importDialog.rect_size = self.rect_size * 0.8
    importDialog.rect_position = self.rect_size * 0.5 - importDialog.rect_size * 0.5
    textEditImport.text = ""
    importDialog.show()

func _on_import_dialog_confirmed():
    var content = textEditImport.text
    load_json(content)

func _on_button_about_pressed():
    aboutDialog.rect_size = self.rect_size * 0.8
    aboutDialog.rect_position = self.rect_size * 0.5 - aboutDialog.rect_size * 0.5
    textEditAbout.text = AboutResource.text
    aboutDialog.show()	

func _on_file_index_pressed(idx):
    var text = popupMenuFile.get_popup().get_item_text(idx)
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

func _on_edit_index_pressed(idx):
    var text = popupMenuEdit.get_popup().get_item_text(idx)
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
        "SUM":
            _on_button_sum_op_node_pressed()
        "PROD":
            _on_button_prod_op_node_pressed()
        "Table":
            _on_button_table_node_pressed()
        "Option":
            _on_button_option_node_pressed()
        "Function":
            _on_button_func_node_pressed()
        "Arrnage Nodes":
            _on_button_arrange_nodes_pressed()
        _:
            print("unexpected menu item:%s" % text)

func _on_help_index_pressed(idx):
    var text = popupMenuHelp.get_popup().get_item_text(idx)
    match text:
        "About":
            _on_button_about_pressed()
        _:
            print("unexpected menu item:%s" % text)
