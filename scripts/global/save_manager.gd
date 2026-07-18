extends Node;

const SAVE_DIR: String = "user://";
const SAVE_PREFIX: String = "save_slot_";
const SAVE_EXT: String = ".json";
const SAVE_VERSION: int = 1;
const MAX_SLOTS: int = 3;

func _ready() -> void:
	Events.menu_save_requested.connect(_on_save_requested);
	Events.load_requested.connect(_on_load_requested);

# ── Public API ───────────────────────────────────────────────────────

func save_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		push_error("[SaveManager] Invalid slot: " + str(slot));
		return false;

	var game = _get_game_node();
	if game == null:
		push_error("[SaveManager] Cannot find Game node in tree.");
		return false;

	var save_data: Dictionary = {};
	save_data["version"] = SAVE_VERSION;
	save_data["timestamp"] = Time.get_datetime_string_from_system();

	# Party
	save_data["party"] = PartyManager.serialize();

	# Inventory
	save_data["inventory"] = ItemManager.serialize();

	# Quest flags
	save_data["quest_flags"] = QuestManager.serialize();

	# Map and player position
	save_data["current_map"] = game.current_map_path;
	save_data["player_position"] = {
		"x": game.player.global_position.x,
		"y": game.player.global_position.y,
	};
	save_data["player_facing"] = game.player.facing;

	# Write to file
	var path = _slot_path(slot);
	var json_string = JSON.stringify(save_data, "\t");
	var file = FileAccess.open(path, FileAccess.WRITE);
	if file == null:
		push_error("[SaveManager] Failed to open save file: " + path);
		return false;

	file.store_string(json_string);
	file.close();

	print("[SaveManager] Game saved to slot " + str(slot));
	Events.save_completed.emit(slot);
	return true;

func load_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		push_error("[SaveManager] Invalid slot: " + str(slot));
		return false;

	var path = _slot_path(slot);
	if not FileAccess.file_exists(path):
		push_error("[SaveManager] No save file at: " + path);
		return false;

	var file = FileAccess.open(path, FileAccess.READ);
	if file == null:
		push_error("[SaveManager] Failed to open save file: " + path);
		return false;

	var json_string = file.get_as_text();
	file.close();

	var json = JSON.new();
	var parse_result = json.parse(json_string);
	if parse_result != OK:
		push_error("[SaveManager] Failed to parse save file: " + json.get_error_message());
		return false;

	var save_data = json.data as Dictionary;
	if save_data == null:
		push_error("[SaveManager] Save data is not a dictionary.");
		return false;

	# Restore managers
	PartyManager.deserialize(save_data.get("party", []));
	ItemManager.deserialize(save_data.get("inventory", []));
	QuestManager.deserialize(save_data.get("quest_flags", []));

	print("[SaveManager] Game loaded from slot " + str(slot));
	return true;

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot));

func get_slot_info(slot: int) -> Dictionary:
	if not has_save(slot):
		return {};

	var file = FileAccess.open(_slot_path(slot), FileAccess.READ);
	if file == null:
		return {};

	var json_string = file.get_as_text();
	file.close();

	var json = JSON.new();
	if json.parse(json_string) != OK:
		return {};

	var data = json.data as Dictionary;
	if data == null:
		return {};

	# Extract summary info
	var info: Dictionary = {};
	info["timestamp"] = data.get("timestamp", "");
	info["current_map"] = data.get("current_map", "");

	var party = data.get("party", []) as Array;
	if party.size() > 0:
		var leader = party[0] as Dictionary;
		info["character_name"] = leader.get("character_name", "???");
		info["level"] = leader.get("level", 1);
	else:
		info["character_name"] = "???";
		info["level"] = 1;

	return info;

func get_save_data(slot: int) -> Dictionary:
	if not has_save(slot):
		return {};

	var file = FileAccess.open(_slot_path(slot), FileAccess.READ);
	if file == null:
		return {};

	var json_string = file.get_as_text();
	file.close();

	var json = JSON.new();
	if json.parse(json_string) != OK:
		return {};

	return json.data as Dictionary;

func delete_save(slot: int) -> void:
	var path = _slot_path(slot);
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path);

func any_save_exists() -> bool:
	for i in MAX_SLOTS:
		if has_save(i):
			return true;
	return false;

# ── Helpers ──────────────────────────────────────────────────────────

func _slot_path(slot: int) -> String:
	return SAVE_DIR + SAVE_PREFIX + str(slot) + SAVE_EXT;

func _get_game_node() -> Node:
	var tree = get_tree();
	if tree == null:
		return null;
	var root = tree.current_scene;
	if root is Game:
		return root;
	# Search children in case Game is nested
	for child in root.get_children():
		if child is Game:
			return child;
	return null;

func _format_map_name(map_path: String) -> String:
	var filename = map_path.get_file().get_basename();
	return filename.replace("_", " ").capitalize();

# ── Signal Handlers ──────────────────────────────────────────────────

func _on_save_requested() -> void:
	# The SaveScreen handles slot selection and calls save_game directly
	pass;

func _on_load_requested(slot: int) -> void:
	if not has_save(slot):
		push_warning("[SaveManager] No save in slot " + str(slot));
		return;

	var save_data = get_save_data(slot);
	if save_data.is_empty():
		return;

	# Restore manager state
	PartyManager.deserialize(save_data.get("party", []));
	ItemManager.deserialize(save_data.get("inventory", []));
	QuestManager.deserialize(save_data.get("quest_flags", []));

	# Transition to game scene with save data
	var game_scene_path = "res://scenes/game.tscn";
	get_tree().paused = false;

	# Store load data so Game can pick it up
	_pending_load_data = save_data;
	get_tree().change_scene_to_file(game_scene_path);

var _pending_load_data: Dictionary = {};

func consume_pending_load() -> Dictionary:
	var data = _pending_load_data;
	_pending_load_data = {};
	return data;
