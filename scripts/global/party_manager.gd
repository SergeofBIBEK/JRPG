extends Node;

func _ready() -> void:
	Events.menu_status_requested.connect(_on_status_requested);

func _on_status_requested() -> void:
	print("[PartyManager] Received menu_status_requested — ready to serve party data");
