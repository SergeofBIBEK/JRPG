extends Node;

var _party: Array[CharacterData] = [];

func _ready() -> void:
	Events.menu_status_requested.connect(_on_status_requested);

func add_member(character: CharacterData) -> void:
	if character not in _party:
		_party.append(character);

func remove_member(character: CharacterData) -> void:
	_party.erase(character);

func get_party() -> Array[CharacterData]:
	return _party;

func get_member(index: int) -> CharacterData:
	if index >= 0 and index < _party.size():
		return _party[index];
	return null;

func party_size() -> int:
	return _party.size();

func clear() -> void:
	_party.clear();

func serialize() -> Array:
	var result: Array = [];
	for character in _party:
		result.append({
			"source_path": character.source_path,
			"character_name": character.character_name,
			"level": character.level,
			"current_hp": character.current_hp,
			"max_hp": character.max_hp,
			"current_mp": character.current_mp,
			"max_mp": character.max_mp,
			"attack": character.attack,
			"defense": character.defense,
			"speed": character.speed,
			"experience": character.experience,
			"gold": character.gold,
		});
	return result;

func deserialize(data: Array) -> void:
	clear();
	for entry in data:
		var source = entry.get("source_path", "") as String;
		var character: CharacterData;
		if source != "" and ResourceLoader.exists(source):
			character = load(source).duplicate() as CharacterData;
		else:
			character = CharacterData.new();
		character.source_path = source;
		character.character_name = entry.get("character_name", "???");
		character.level = entry.get("level", 1);
		character.current_hp = entry.get("current_hp", 100);
		character.max_hp = entry.get("max_hp", 100);
		character.current_mp = entry.get("current_mp", 30);
		character.max_mp = entry.get("max_mp", 30);
		character.attack = entry.get("attack", 10);
		character.defense = entry.get("defense", 8);
		character.speed = entry.get("speed", 6);
		character.experience = entry.get("experience", 0);
		character.gold = entry.get("gold", 0);
		_party.append(character);

func _on_status_requested() -> void:
	Events.menu_status_data.emit(_party);
