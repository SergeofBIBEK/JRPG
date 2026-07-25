extends Node;

enum State {
	INACTIVE,
	PLAYER_COMMAND,
	PLAYER_ACTION,
	ENEMY_ACTION,
	VICTORY,
	DEFEAT,
	FLED,
}

var current_state: State = State.INACTIVE;

var enemy: EnemyData = null;

var _selected_command: String = "";
var _selected_item: ItemData = null;
var _is_defending: bool = false;

const PHASE_DELAY: float = 1.2;
const ANIM_DELAY: float = 0.35;

# ── Enemy Pool ────────────────────────────────────────────────────────
var _enemy_pool: Array[EnemyData] = [];

func _ready() -> void:
	_enemy_pool = [
		preload("res://data/enemies/goblin.tres"),
		preload("res://data/enemies/slime.tres"),
		preload("res://data/enemies/wolf.tres"),
	];

func start_random_battle() -> void:
	var template = _enemy_pool.pick_random();
	start_battle(template);

func start_battle(enemy_data: EnemyData) -> void:
	enemy = enemy_data.duplicate();
	enemy.current_hp = enemy.max_hp;

	_selected_command = "";
	_selected_item = null;
	_is_defending = false;

	_change_state(State.PLAYER_COMMAND);
	Events.battle_message.emit("A " + enemy.enemy_name + " appeared!");
	Events.battle_enemy_hp_updated.emit();

func select_command(command_name: String) -> void:
	if current_state != State.PLAYER_COMMAND:
		return;
	_selected_command = command_name;
	_change_state(State.PLAYER_ACTION);
	_execute_player_action();

func select_item(item: ItemData) -> void:
	if current_state != State.PLAYER_COMMAND:
		return;
	_selected_command = "Item";
	_selected_item = item;
	_change_state(State.PLAYER_ACTION);
	_execute_player_action();

func is_active() -> bool:
	return current_state != State.INACTIVE;

func _calculate_damage(attacker_atk: int, defender_def: int) -> int:
	var base_damage = (attacker_atk * 2) - defender_def;
	var variance = maxi(1, base_damage / 8);
	var final_damage = base_damage + randi_range(-variance, variance);
	return maxi(1, final_damage);

func _change_state(new_state: State) -> void:
	current_state = new_state;
	Events.battle_state_changed.emit(State.keys()[new_state]);

func _execute_player_action() -> void:
	match _selected_command:
		"Attack":
			_do_attack();
		"Defend":
			_do_defend();
		"Item":
			_do_item();
		"Run":
			_do_run();

func _do_attack() -> void:
	var party = PartyManager.get_party();
	var attacker_name = "Hero";
	var attacker_atk = 10;
	if party.size() > 0:
		attacker_name = party[0].character_name;
		attacker_atk = party[0].attack;

	AudioManager.play_sfx("attack_swing");
	Events.battle_player_attack_anim.emit();
	await get_tree().create_timer(ANIM_DELAY).timeout;

	var damage = _calculate_damage(attacker_atk, enemy.defense);
	enemy.take_damage(damage);
	AudioManager.play_sfx("hit");
	Events.battle_enemy_hit_anim.emit();
	Events.battle_message.emit(attacker_name + " attacks! " + str(damage) + " damage dealt.");
	Events.battle_enemy_hp_updated.emit();

	await _phase_delay();

	if await _check_victory():
		return;
	_start_enemy_action();

func _do_defend() -> void:
	var party = PartyManager.get_party();
	var defender_name = "Hero";
	if party.size() > 0:
		defender_name = party[0].character_name;

	_is_defending = true;
	Events.battle_message.emit(defender_name + " is defending.");

	await _phase_delay();
	_start_enemy_action();

func _do_item() -> void:
	if _selected_item == null:
		Events.battle_message.emit("No item selected.");
		await _phase_delay();
		_start_enemy_action();
		return;

	var party = PartyManager.get_party();
	if party.size() == 0:
		return;

	var hero = party[0];
	var heal_amount = _selected_item.hp_restore;
	hero.heal_hp(heal_amount);
	ItemManager.remove_item(_selected_item, 1);
	AudioManager.play_sfx("item_use");

	Events.battle_message.emit(hero.character_name + " used " + _selected_item.item_name + "! Healed " + str(heal_amount) + " HP.");
	Events.battle_hp_updated.emit();

	_selected_item = null;

	await _phase_delay();

	if await _check_victory():
		return;
	_start_enemy_action();

func _do_run() -> void:
	Events.battle_message.emit("Ran away!");
	await _phase_delay();
	_change_state(State.FLED);
	await _phase_delay();
	_end_battle();

func _start_enemy_action() -> void:
	_change_state(State.ENEMY_ACTION);

	var party = PartyManager.get_party();
	if party.size() == 0:
		return;

	var target = party[0];
	var raw_damage = _calculate_damage(enemy.attack, target.defense);

	if _is_defending:
		raw_damage = maxi(1, ceili(raw_damage / 2.0));

	AudioManager.play_sfx("attack_swing");
	Events.battle_enemy_attack_anim.emit();
	await get_tree().create_timer(ANIM_DELAY).timeout;

	target.current_hp = maxi(target.current_hp - raw_damage, 0);
	AudioManager.play_sfx("hit");
	Events.battle_player_hit_anim.emit();
	Events.battle_message.emit(enemy.enemy_name + " attacks! " + str(raw_damage) + " damage to " + target.character_name + ".");
	Events.battle_hp_updated.emit();

	_is_defending = false;

	await _phase_delay();

	if await _check_defeat():
		return;
	_change_state(State.PLAYER_COMMAND);

func _check_victory() -> bool:
	if enemy == null or not enemy.is_alive():
		_change_state(State.VICTORY);
		AudioManager.play_music("victory", 0.3);
		Events.battle_message.emit("Victory! " + enemy.enemy_name + " was defeated!");
		await _phase_delay();
		await _award_rewards();
		_end_battle();
		return true;
	return false;

func _award_rewards() -> void:
	var exp_gained = enemy.exp_reward;
	var gold_gained = enemy.gold_reward;

	Events.battle_rewards.emit(exp_gained, gold_gained);
	Events.battle_message.emit("Gained " + str(exp_gained) + " EXP and " + str(gold_gained) + " Gold!");
	await _phase_delay();

	var party = PartyManager.get_party();
	for member in party:
		if member.is_alive():
			member.gold += gold_gained;
			# Capture stats before leveling
			var old_hp = member.max_hp;
			var old_mp = member.max_mp;
			var old_atk = member.attack;
			var old_def = member.defense;
			var old_spd = member.speed;
			var leveled = member.add_experience(exp_gained);
			if leveled:
				Events.battle_level_up.emit(member.character_name, member.level);
				Events.battle_message.emit(member.character_name + " reached Level " + str(member.level) + "!");
				Events.battle_hp_updated.emit();
				await _phase_delay();
				# Show stat increases
				var stats_msg = "HP+" + str(member.max_hp - old_hp);
				stats_msg += "  MP+" + str(member.max_mp - old_mp);
				stats_msg += "  ATK+" + str(member.attack - old_atk);
				stats_msg += "  DEF+" + str(member.defense - old_def);
				stats_msg += "  SPD+" + str(member.speed - old_spd);
				Events.battle_message.emit(stats_msg);
				await _phase_delay();
				await _phase_delay();

func _check_defeat() -> bool:
	var party = PartyManager.get_party();
	var all_dead = true;
	for member in party:
		if member.is_alive():
			all_dead = false;
			break;
	if all_dead:
		_change_state(State.DEFEAT);
		AudioManager.play_music("game_over", 0.3);
		Events.battle_message.emit("Defeat... The party has fallen.");
		await _phase_delay();
		_end_battle();
		return true;
	return false;

func _end_battle() -> void:
	_change_state(State.INACTIVE);
	Events.battle_ended.emit();

func _phase_delay() -> void:
	await get_tree().create_timer(PHASE_DELAY).timeout;
