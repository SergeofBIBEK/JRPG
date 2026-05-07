class_name Map;
extends Node2D;

@export var player_scene: PackedScene;

@onready var player_spawn: Marker2D = $PlayerSpawn;

func _ready() -> void:
	var player = player_scene.instantiate();
	add_child(player);
	player.global_position = player_spawn.global_position;
