@tool
extends Node

@export var raw_data : String
@export var final_data : Array[Vector3]

func string_to_vector3_array(data_str: String) -> Array[Vector3]:
	var result: Array[Vector3] = []
	
	# Clean up any brackets, parentheses, or newlines, leaving only raw numbers and commas
	var clean_str = data_str.replace("[", "").replace("]", "").replace("(", "").replace(")", "")
	clean_str = clean_str.replace("\n", "").replace(" ", "")
	
	# Split everything into an array of individual text numbers
	var components = clean_str.split(",", false)
	
	# Step through the numbers 3 at a time to build Vector3 objects
	for i in range(0, components.size(), 3):
		if i + 2 < components.size():
			var x = components[i].to_float()
			var y = components[i+1].to_float()
			var z = components[i+2].to_float()
			result.append(Vector3(x, y, z))
			
	return result

func _process(delta: float) -> void:
	final_data = string_to_vector3_array(raw_data)
