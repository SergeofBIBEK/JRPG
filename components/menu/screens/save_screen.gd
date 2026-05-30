class_name SaveScreen;
extends MenuScreen;

func _init() -> void:
	screen_name = "Save";
	screen_order = 2;

func activate() -> void:
	super.activate();
	print("[SaveScreen] Activated — emitting menu_save_requested");
	Events.menu_save_requested.emit();
