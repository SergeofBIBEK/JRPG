extends Node;

func _ready() -> void:
	Events.menu_save_requested.connect(_on_save_requested);

func _on_save_requested() -> void:
	print("[SaveManager] Received menu_save_requested — ready to save game data");
