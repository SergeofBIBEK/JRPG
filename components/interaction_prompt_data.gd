class_name InteractionPromptData
extends RefCounted

var action_name: String;
var action_input_name: String;

func _init(initial_action_name, initial_action_intput_name) -> void:
	action_name = initial_action_name;
	action_input_name = initial_action_intput_name;
