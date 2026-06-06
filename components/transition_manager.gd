class_name TransitionManager;
extends Node;

@export var fade_duration: float = 0.3;

var _locked: bool = true;

func _ready() -> void:
	Events.transition_requested.connect(_on_transition_requested);

func unlock() -> void:
	_locked = false;

func _on_transition_requested(target_map_path: String, spawn_location: String) -> void:
	if _locked:
		return;

	if target_map_path == "":
		push_error("TransitionManager: target_map_path is empty, cannot transition.");
		return;

	_locked = true;
	var game = get_parent() as Game;

	await game.fade_overlay.fade_out(fade_duration);
	game.change_map(target_map_path, spawn_location);
	await game.fade_overlay.fade_in(fade_duration);

	_locked = false;
