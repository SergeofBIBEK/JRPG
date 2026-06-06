class_name CharacterData;
extends Resource;

@export var character_name: String = "";
@export var level: int = 1;

@export_group("HP")
@export var max_hp: int = 100;
@export var current_hp: int = 100;

@export_group("MP")
@export var max_mp: int = 30;
@export var current_mp: int = 30;

@export_group("Stats")
@export var attack: int = 10;
@export var defense: int = 8;
@export var speed: int = 6;

func is_alive() -> bool:
	return current_hp > 0;

func heal_hp(amount: int) -> void:
	current_hp = mini(current_hp + amount, max_hp);

func heal_mp(amount: int) -> void:
	current_mp = mini(current_mp + amount, max_mp);

func revive(hp_percent: float = 0.5) -> void:
	if not is_alive():
		current_hp = maxi(1, int(max_hp * hp_percent));
