class_name DialogBehavior;
extends InteractionBehavior;

@export var portrait_texture: Texture2D;
@export var dialog_name: String;
@export var dialog_lines: Array[String] = ["..."];

func process_interaction():
	Events.show_dialog.emit(portrait_texture, dialog_lines, dialog_name);
	await Events.dialog_finished;

func _init():
	interaction_name = "Talk";
