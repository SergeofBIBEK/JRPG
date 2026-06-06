class_name ItemData;
extends Resource;

enum ItemType {
	CONSUMABLE,
	KEY_ITEM,
}

enum TargetType {
	SINGLE_ALLY,
	ALL_ALLIES,
	SINGLE_ENEMY,
}

@export var item_name: String = "";
@export_multiline var description: String = "";
@export var item_type: ItemType = ItemType.CONSUMABLE;
@export var target_type: TargetType = TargetType.SINGLE_ALLY;

@export_group("Effects")
@export var hp_restore: int = 0;
@export var mp_restore: int = 0;
@export var revives: bool = false;
@export var revive_hp_percent: float = 0.5;
