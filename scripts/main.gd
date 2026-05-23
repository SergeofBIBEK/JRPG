class_name Map;
extends Node2D;

@export var player_scene: PackedScene;

@onready var player_spawn: Marker2D = $PlayerSpawn;

func _ready() -> void:
	var player = player_scene.instantiate();
	add_child(player);

	var spawn_point := _get_spawn_point();
	player.global_position = spawn_point.global_position;

func _get_spawn_point() -> Marker2D:
	var location_name = Events.pending_spawn_location;
	Events.pending_spawn_location = "";

	if location_name != "":
		var target = get_node_or_null(location_name);
		if target is Marker2D:
			return target;

	return player_spawn;
