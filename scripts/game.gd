class_name Game;
extends Node2D;

@export var starting_map: PackedScene;
@export var fade_duration: float = 0.5;

@onready var map_container: Node2D = $MapContainer;
@onready var player: Player = $Player;
@onready var fade_overlay: FadeOverlay = $FadeOverlay;
@onready var transition_manager: TransitionManager = $TransitionManager;

var current_map: Node2D;

func _ready() -> void:
	_init_party();
	_init_inventory();
	_load_map(starting_map, "PlayerSpawn");
	# Wait for the scene tree to settle before fading in
	await get_tree().process_frame;
	await get_tree().process_frame;
	await fade_overlay.fade_in(fade_duration);
	transition_manager.unlock();

func _init_party() -> void:
	var hero = load("res://data/characters/hero.tres") as CharacterData;
	if hero:
		# Duplicate so runtime changes don't write back to the .tres file
		var hero_instance = hero.duplicate() as CharacterData;
		PartyManager.add_member(hero_instance);

func _init_inventory() -> void:
	var potion = load("res://data/items/potion.tres") as ItemData;
	var ether = load("res://data/items/ether.tres") as ItemData;
	var phoenix_down = load("res://data/items/phoenix_down.tres") as ItemData;

	if potion:
		ItemManager.add_item(potion, 1);
	if ether:
		ItemManager.add_item(ether, 1);
	if phoenix_down:
		ItemManager.add_item(phoenix_down, 1);

func change_map(map_scene_path: String, spawn_location: String) -> void:
	var map_scene = load(map_scene_path) as PackedScene;
	if map_scene == null:
		push_error("Game: failed to load map at: " + map_scene_path);
		return;

	if current_map:
		map_container.remove_child(current_map);
		current_map.queue_free();

	_load_map(map_scene, spawn_location);

func _load_map(map_scene: PackedScene, spawn_location: String) -> void:
	current_map = map_scene.instantiate();
	map_container.add_child(current_map);

	var spawn_point = _get_spawn_point(spawn_location);
	player.global_position = spawn_point.global_position;

func _get_spawn_point(location_name: String) -> Marker2D:
	if location_name != "":
		var target = current_map.get_node_or_null(location_name);
		if target is Marker2D:
			return target;

	# Fallback to PlayerSpawn
	var fallback = current_map.get_node_or_null("PlayerSpawn");
	if fallback is Marker2D:
		return fallback;

	# Last resort — use map origin
	push_warning("Game: no spawn point found, using map origin.");
	var temp = Marker2D.new();
	temp.global_position = current_map.global_position;
	return temp;
