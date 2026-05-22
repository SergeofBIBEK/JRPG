class_name DialogBehavior;
extends InteractionBehavior;

@export var portrait_texture: Texture2D;
@export var dialog_name: String;

func process_interaction():
	var dialog_text: Array[String] = ["Hello there! I am Godot dude! This dialog box is totally working! What will you build next?"];
	Events.show_dialog.emit(portrait_texture, dialog_text, dialog_name);
	await get_tree().create_timer(5.0).timeout
	Events.hide_dialog.emit();

func _init():
	interaction_name = "Talk";
