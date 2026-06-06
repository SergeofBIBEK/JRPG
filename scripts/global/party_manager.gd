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

func _on_status_requested() -> void:
	Events.menu_status_data.emit(_party);
