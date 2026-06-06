class_name QuitScreen;
extends MenuScreen;

func _init() -> void:
	screen_name = "Quit";
	screen_order = 3;

func activate() -> void:
	super.activate();

func enter() -> void:
	print("[QuitScreen] Quitting game...");
	get_tree().quit();
