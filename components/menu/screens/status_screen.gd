class_name StatusScreen;
extends MenuScreen;

func _init() -> void:
	screen_name = "Status";
	screen_order = 1;

func activate() -> void:
	super.activate();
	print("[StatusScreen] Activated — emitting menu_status_requested");
	Events.menu_status_requested.emit();
