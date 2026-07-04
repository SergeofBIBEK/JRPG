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

@export_group("Progression")
@export var experience: int = 0;
@export var gold: int = 0;

func is_alive() -> bool:
	return current_hp > 0;

func heal_hp(amount: int) -> void:
	current_hp = mini(current_hp + amount, max_hp);

func heal_mp(amount: int) -> void:
	current_mp = mini(current_mp + amount, max_mp);

func revive(hp_percent: float = 0.5) -> void:
	if not is_alive():
		current_hp = maxi(1, int(max_hp * hp_percent));

func exp_to_next_level() -> int:
	return level * 20 + 10;

func add_experience(amount: int) -> bool:
	experience += amount;
	if experience >= exp_to_next_level():
		level_up();
		return true;
	return false;

func level_up() -> void:
	experience -= exp_to_next_level();
	level += 1;
	max_hp += 8;
	max_mp += 3;
	attack += 2;
	defense += 2;
	speed += 1;
	# Full restore on level up
	current_hp = max_hp;
	current_mp = max_mp;
