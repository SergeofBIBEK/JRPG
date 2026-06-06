class_name TransitionTrigger;
extends Area2D;

@export_file("*.tscn") var target_map_path: String;
@export var spawn_location: String = "";

func _ready() -> void:
	body_entered.connect(_on_body_entered);

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		Events.transition_requested.emit(target_map_path, spawn_location);
