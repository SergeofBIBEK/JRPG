class_name MenuScreen;
extends Control;

@export var screen_name: String = "";

@export var screen_order: int = 0;

func activate() -> void:
	visible = true;

func deactivate() -> void:
	visible = false;
