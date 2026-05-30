class_name ItemsScreen;
extends MenuScreen;

func _init() -> void:
	screen_name = "Items";
	screen_order = 0;

func activate() -> void:
	super.activate();
	print("[ItemsScreen] Activated — emitting menu_items_requested");
	Events.menu_items_requested.emit();
