class_name QuitScreen;
extends MenuScreen;

func _init() -> void:
	screen_name = "Quit";
	screen_order = 3;

func activate() -> void:
	super.activate();

func enter() -> void:
	print("[QuitScreen] Returning to title screen...");
	Events.return_to_title.emit();
