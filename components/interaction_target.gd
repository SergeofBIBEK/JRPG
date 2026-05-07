class_name InteractionTarget
extends Node2D

var _behaviors: Array[InteractionBehavior] = [];

func _ready() -> void:
	_refresh_behaviors();
	
func _refresh_behaviors() -> void:
	_behaviors.clear();
	
	for child in get_children():
		if child is InteractionBehavior:
			_behaviors.append(child);

func handle_interaction(interaction_index: int):
	if (interaction_index >= 0 and interaction_index < _behaviors.size()):
		var behavior = _behaviors[interaction_index];
		behavior.process_interaction();
