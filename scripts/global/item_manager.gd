extends Node;

## Inventory stored as { ItemData resource : quantity int }
var _inventory: Dictionary = {};

func _ready() -> void:
	Events.menu_items_requested.connect(_on_items_requested);

func add_item(item: ItemData, quantity: int = 1) -> void:
	if item in _inventory:
		_inventory[item] += quantity;
	else:
		_inventory[item] = quantity;

func remove_item(item: ItemData, quantity: int = 1) -> bool:
	if item not in _inventory:
		return false;
	if _inventory[item] < quantity:
		return false;
	_inventory[item] -= quantity;
	if _inventory[item] <= 0:
		_inventory.erase(item);
	return true;

func get_item_count(item: ItemData) -> int:
	if item in _inventory:
		return _inventory[item];
	return 0;

func get_all_items() -> Dictionary:
	return _inventory;

func has_item(item: ItemData) -> bool:
	return item in _inventory and _inventory[item] > 0;

func clear() -> void:
	_inventory.clear();

func serialize() -> Array:
	var result: Array = [];
	for item: ItemData in _inventory:
		result.append({
			"resource_path": item.resource_path,
			"quantity": _inventory[item],
		});
	return result;

func deserialize(data: Array) -> void:
	clear();
	for entry in data:
		var path = entry.get("resource_path", "") as String;
		var qty = entry.get("quantity", 1) as int;
		if path != "" and ResourceLoader.exists(path):
			var item = load(path) as ItemData;
			if item:
				_inventory[item] = qty;
		else:
			push_warning("[ItemManager] Could not load item at: " + path);

func _on_items_requested() -> void:
	Events.menu_items_data.emit(_inventory);
