class_name EnemyData;
extends Resource;

@export var enemy_name: String = "";
@export var level: int = 1;

@export_group("HP")
@export var max_hp: int = 40;
@export var current_hp: int = 40;

@export_group("Stats")
@export var attack: int = 8;
@export var defense: int = 4;
@export var speed: int = 5;

@export_group("Rewards")
@export var exp_reward: int = 10;
@export var gold_reward: int = 5;

func is_alive() -> bool:
	return current_hp > 0;

func take_damage(amount: int) -> int:
	var clamped = mini(amount, current_hp);
	current_hp = maxi(current_hp - clamped, 0);
	return clamped;
