@tool
class_name InteractionPrompt;
extends Control;

@onready var _text_label: RichTextLabel = find_child(
	"InteractionPromptText",
	true,
	false
) as RichTextLabel;

@export var screen_offset := Vector2(32, -32);

var _target_world_position: Vector2;

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = [];
	
	var interactionPromptText = find_child(
		"InteractionPromptText",
		true,
		false
	);
	
	if (interactionPromptText == null):
		warnings.append("InteractionHandler requires a child InteractionPromptText.");
	elif (not is_instance_of(interactionPromptText, RichTextLabel)):
		warnings.append("InteractionPromptText child must be of type RichTextLabel");
	
	return warnings;

func _init() -> void:
	visible = false;

func _ready():
	Events.show_interaction_prompt.connect(display_prompts);
	Events.hide_interaction_prompt.connect(clear_prompts);

func _process(_delta: float) -> void:
	if (_target_world_position != null):
		update_label_position();

func display_prompts(target_position: Vector2, action_list: Array[InteractionPromptData]):
	var action_list_not_empty = action_list.size() > 0;
	
	if (action_list_not_empty):
		update_label_content(action_list);
		_target_world_position = target_position;
		visible = true;

func clear_prompts():
	visible = false;

func update_label_content(action_list: Array[InteractionPromptData]):
	_text_label.clear();
	
	for i in action_list.size():
		var action = action_list[i];
		
		_text_label.add_text("[ ");
		_text_label.add_text(action.action_input_name);
		_text_label.add_text(" ] ");
		_text_label.add_text(action.action_name);
		
		if i < action_list.size() - 1:
			_text_label.add_text("\n");

func update_label_position():
	var canvas_transform := get_viewport().get_canvas_transform();
	position = canvas_transform * _target_world_position + screen_offset;
