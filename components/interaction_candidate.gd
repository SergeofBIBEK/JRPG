class_name InteractionCandidate;
extends RefCounted;

var node: InteractionTarget;
var distance: float;

func _init(initialNode: InteractionTarget, initialDistance: float):
	node = initialNode;
	distance = initialDistance;

func update_distance(newDistance: float):
	distance = newDistance;

func start_being_target():
	node.display_prompts();
	
func stop_being_target():
	node.clear_prompts();

func interact(interaction_index: int):
	node.handle_interaction(interaction_index);
