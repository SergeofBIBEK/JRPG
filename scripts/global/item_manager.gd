extends Node;

func _ready() -> void:
	Events.menu_items_requested.connect(_on_items_requested);

func _on_items_requested() -> void:
	print("[ItemManager] Received menu_items_requested — ready to serve item data");
