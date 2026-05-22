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

func display_prompts():
	var world_position = global_position;
	var action_list: Array[InteractionPromptData] = [];
	var button_prompts = ["_", "z", "x", "c"];
	var max_prompts = min(_behaviors.size(), 4);
	
	for index in range(max_prompts):
		var behavior = _behaviors[index];
		action_list.append(InteractionPromptData.new(behavior.interaction_name, button_prompts[index]));

	Events.show_interaction_prompt.emit(world_position, action_list);

func clear_prompts():
	print('should stop displaying prompts');
	Events.hide_interaction_prompt.emit();
