class_name MenuScreen;
extends Control;

@export var screen_name: String = "";

@export var screen_order: int = 0;

func activate() -> void:
	visible = true;

func deactivate() -> void:
	visible = false;

## Called when the player presses the action key to "enter" this screen.
## Override in subclasses to enable in-screen navigation (e.g. selecting items).
func enter() -> void:
	pass;

## Called when the player backs out of this screen.
## Override in subclasses to clean up in-screen navigation state.
func exit() -> void:
	pass;
