class_name Game;
extends Node2D;

@export var starting_map: PackedScene;
@export var fade_duration: float = 0.5;

@onready var map_container: Node2D = $MapContainer;
@onready var player: Player = $Player;
@onready var fade_overlay: FadeOverlay = $FadeOverlay;
@onready var transition_manager: TransitionManager = $TransitionManager;

var current_map: Node2D;
var current_map_path: String = "";
var _battle_scene: BattleScene = null;
var _battle_scene_packed: PackedScene = preload("res://scenes/battle/battle_scene.tscn");

func _ready() -> void:
	Events.battle_requested.connect(_on_battle_requested);
	Events.battle_ended.connect(_on_battle_ended);
	Events.return_to_title.connect(_on_return_to_title);

	# Check if we're loading from a save
	var load_data = SaveManager.consume_pending_load();
	if not load_data.is_empty():
		_load_from_save(load_data);
	else:
		_init_party();
		_init_inventory();
		_load_map(starting_map, "PlayerSpawn");
		current_map_path = starting_map.resource_path;

	# Wait for the scene tree to settle before fading in
	await get_tree().process_frame;
	await get_tree().process_frame;
	await fade_overlay.fade_in(fade_duration);
	transition_manager.unlock();

func _init_party() -> void:
	var hero_path = "res://data/characters/hero.tres";
	var hero = load(hero_path) as CharacterData;
	if hero:
		# Duplicate so runtime changes don't write back to the .tres file
		var hero_instance = hero.duplicate() as CharacterData;
		hero_instance.source_path = hero_path;
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

func _load_from_save(save_data: Dictionary) -> void:
	# Party and inventory were already deserialized by SaveManager
	# Load the saved map
	var map_path = save_data.get("current_map", "") as String;
	if map_path == "" or not ResourceLoader.exists(map_path):
		push_error("Game: invalid map path in save data: " + map_path);
		_load_map(starting_map, "PlayerSpawn");
		current_map_path = starting_map.resource_path;
		return;

	var map_scene = load(map_path) as PackedScene;
	if map_scene == null:
		push_error("Game: failed to load saved map: " + map_path);
		_load_map(starting_map, "PlayerSpawn");
		current_map_path = starting_map.resource_path;
		return;

	current_map_path = map_path;
	current_map = map_scene.instantiate();
	map_container.add_child(current_map);

	# Restore player position
	var pos_data = save_data.get("player_position", {}) as Dictionary;
	var px = pos_data.get("x", 0.0) as float;
	var py = pos_data.get("y", 0.0) as float;
	player.global_position = Vector2(px, py);

	# Restore player facing
	var saved_facing = save_data.get("player_facing", "down") as String;
	player.facing = saved_facing;

func change_map(map_scene_path: String, spawn_location: String) -> void:
	var map_scene = load(map_scene_path) as PackedScene;
	if map_scene == null:
		push_error("Game: failed to load map at: " + map_scene_path);
		return;

	if current_map:
		map_container.remove_child(current_map);
		current_map.queue_free();

	current_map_path = map_scene_path;
	_load_map(map_scene, spawn_location);

func _load_map(map_scene: PackedScene, spawn_location: String) -> void:
	current_map = map_scene.instantiate();
	map_container.add_child(current_map);

	# Track the path if we don't already have it
	if current_map_path == "":
		current_map_path = map_scene.resource_path;

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

func _on_battle_requested() -> void:
	transition_manager._locked = true;
	await fade_overlay.fade_out(fade_duration);
	map_container.visible = false;
	player.visible = false;
	player.process_mode = Node.PROCESS_MODE_DISABLED;
	_battle_scene = _battle_scene_packed.instantiate() as BattleScene;
	add_child(_battle_scene);
	await fade_overlay.fade_in(fade_duration);

func _on_battle_ended() -> void:
	await fade_overlay.fade_out(fade_duration);
	if _battle_scene:
		remove_child(_battle_scene);
		_battle_scene.queue_free();
		_battle_scene = null;
	map_container.visible = true;
	player.visible = true;
	player.process_mode = Node.PROCESS_MODE_INHERIT;
	await fade_overlay.fade_in(fade_duration);
	transition_manager._locked = false;

func _on_return_to_title() -> void:
	get_tree().paused = false;
	# Clear manager state so title screen starts fresh
	PartyManager.clear();
	ItemManager.clear();
	QuestManager.clear();
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn");
