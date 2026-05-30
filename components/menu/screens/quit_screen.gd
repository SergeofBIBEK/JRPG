class_name QuitScreen;
extends MenuScreen;

func _init() -> void:
	screen_name = "Quit";
	screen_order = 3;

func activate() -> void:
	super.activate();
	print("[QuitScreen] Activated — emitting menu_quit_requested");
	Events.menu_quit_requested.emit();
	print("[QuitScreen] Quitting game...");
	get_tree().quit();
