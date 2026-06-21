extends StaticBody3D

@export var option_scene : PackedScene

var trash_nodes : Array[Trash]

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Trash and not body in trash_nodes:
		trash_nodes.append(body)
		if trash_nodes.size() == 1:
			$Control.show()
			recycle(body)

func recycle(body : Trash):
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	for i in range(body.recycle_info.block_ids.size()):
		var option_node : Button = option_scene.instantiate()
		var item = body.recycle_info.block_ids[i]
		var name_block = $"../Builder".blocks[item].instantiate()
		option_node.text = name_block.name
		option_node.connect("pressed",pressed.bind(item,body,i))
		$Control/VBoxContainer.add_child(option_node)

func pressed(item,trash,i):
	trash_nodes.erase(trash)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	for child in $Control/VBoxContainer.get_children():
		if child is Button:
			child.queue_free()
	$"../Builder".part_limits[item] += trash.recycle_info.block_count[i]
	trash.queue_free()
	if trash_nodes.size() > 0:
		recycle(trash_nodes[0])
	else:
		$Control.hide()
