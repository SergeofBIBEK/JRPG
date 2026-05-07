class_name Utils;

static func get_child_of_type(parent: Node, type: Variant):
	for child in parent.get_children():
		if is_instance_of(child, type):
			return child;
	return null;
