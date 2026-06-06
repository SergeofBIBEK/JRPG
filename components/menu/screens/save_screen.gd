class_name SaveScreen;
extends MenuScreen;

func _init() -> void:
	screen_name = "Save";
	screen_order = 2;

func activate() -> void:
	super.activate();

func enter() -> void:
	print("[SaveScreen] Save requested — emitting menu_save_requested");
	Events.menu_save_requested.emit();
