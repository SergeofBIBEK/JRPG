@tool
class_name InteractionHandler;
extends Node2D;

@onready var _area: Area2D = $Area2D;

var _candidates: Array[InteractionCandidate] = [];
var target: InteractionCandidate = null;

func _process(_delta):
	_clean_list();
	_update_distances();
	_sort_candidates();

func _ready() -> void:
	_area.body_entered.connect(_register_candidate);
	_area.body_exited.connect(_deregister_candidate);

func _unhandled_input(event: InputEvent) -> void:
	var interaction_index: int = -1;
	
	if event.is_action_pressed("interact3"):
		interaction_index = 3;
	if event.is_action_pressed("interact2"):
		interaction_index = 2;
	if event.is_action_pressed("interact1"):
		interaction_index = 1;
	if event.is_action_pressed("interact"):
		interaction_index = 0;
	
	if (interaction_index > -1 and not _candidates.is_empty()):
		_candidates[0].interact(interaction_index);

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = [];
	
	if get_node_or_null("Area2D") == null:
		warnings.append("InteractionHandler requires a child Area2D.");
	
	return warnings;

func _register_candidate(body: Node2D) -> void:
	var interactionTarget: InteractionTarget = Utils.get_child_of_type(body, InteractionTarget);
	if (interactionTarget):
		var node = interactionTarget;
		var distance = _get_distance_from_self_to_node(body);
		
		var interactionCandidate = InteractionCandidate.new(node, distance);
		_candidates.append(interactionCandidate);
	
func _deregister_candidate(body: Node2D) -> void:
	var interactionTarget: InteractionTarget = Utils.get_child_of_type(body, InteractionTarget);
	if (interactionTarget):
		_candidates = _candidates.filter(
			func(candidate):
				return candidate.node != interactionTarget;
		);

func _get_distance_from_self_to_node(node: Node2D) -> float:
	var currentPosition = self.global_position;
	var nodePosition = node.global_position;
	var distanceBetween = currentPosition.distance_to(nodePosition);
	
	return distanceBetween;

func _clean_list():
	_candidates = _candidates.filter(
		func(candidate):
			return is_instance_valid(candidate.node);
	);

func _update_distances():
	for candidate in _candidates:
		if not is_instance_valid((candidate.node)):
			continue;
		
		var distance = _get_distance_from_self_to_node(candidate.node);
		candidate.update_distance(distance);

func _sort_candidates():
	_candidates.sort_custom(
		func(a, b):
			return a.distance < b.distance;
	);
	
func _set_target(newTarget: InteractionCandidate):
	target.stop_being_target();
	newTarget.start_being_target();
	
	target = newTarget;
