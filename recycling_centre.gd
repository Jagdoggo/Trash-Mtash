extends StaticBody3D

@export var option_scene : PackedScene

var trash_nodes : Array[Trash]

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Trash and not body in trash_nodes:
		trash_nodes.append(body)
		if trash_nodes.size() == 1:
			recycle(body)

func recycle(body : Trash):
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	for item in body.recycle_info.block_ids:
		var option_node : Button = option_scene.instantiate()
		var name_block = $"../Builder".blocks[item].instantiate()
		option_node.text = name_block.name
		option_node.connect("pressed",pressed.bind(item,body))
		$Control/VBoxContainer.add_child(option_node)

func pressed(item,trash):
	trash_nodes.erase(trash)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	for child in $Control/VBoxContainer.get_children():
		child.queue_free()
	$"../Builder".part_limits[item] += 1
	trash.queue_free()
	if trash_nodes.size() > 0:
		recycle(trash_nodes[0])
