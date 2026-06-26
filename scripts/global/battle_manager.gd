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

var enemy_name: String = "";
var enemy_hp: int = 0;
var enemy_max_hp: int = 0;

var _selected_command: String = "";
var _selected_item: ItemData = null;

const PLAYER_ATTACK_DAMAGE: int = 12;
const ENEMY_ATTACK_DAMAGE: int = 8;
const ITEM_HEAL_AMOUNT: int = 20;
const PHASE_DELAY: float = 1.2;

func start_battle() -> void:
	enemy_name = "Goblin";
	enemy_max_hp = 40;
	enemy_hp = enemy_max_hp;

	_selected_command = "";
	_selected_item = null;

	_change_state(State.PLAYER_COMMAND);
	Events.battle_message.emit("A " + enemy_name + " appeared!");

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
	if party.size() > 0:
		attacker_name = party[0].character_name;

	enemy_hp = maxi(enemy_hp - PLAYER_ATTACK_DAMAGE, 0);
	Events.battle_message.emit(attacker_name + " attacks! " + str(PLAYER_ATTACK_DAMAGE) + " damage dealt.");

	await _phase_delay();

	if await _check_victory():
		return;
	_start_enemy_action();

func _do_defend() -> void:
	var party = PartyManager.get_party();
	var defender_name = "Hero";
	if party.size() > 0:
		defender_name = party[0].character_name;

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
	hero.heal_hp(ITEM_HEAL_AMOUNT);
	ItemManager.remove_item(_selected_item, 1);

	Events.battle_message.emit(hero.character_name + " used " + _selected_item.item_name + "! Healed " + str(ITEM_HEAL_AMOUNT) + " HP.");
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
	target.current_hp = maxi(target.current_hp - ENEMY_ATTACK_DAMAGE, 0);
	Events.battle_message.emit(enemy_name + " attacks! " + str(ENEMY_ATTACK_DAMAGE) + " damage to " + target.character_name + ".");
	Events.battle_hp_updated.emit();

	await _phase_delay();

	if await _check_defeat():
		return;
	_change_state(State.PLAYER_COMMAND);

func _check_victory() -> bool:
	if enemy_hp <= 0:
		_change_state(State.VICTORY);
		Events.battle_message.emit("Victory! " + enemy_name + " was defeated!");
		await _phase_delay();
		_end_battle();
		return true;
	return false;

func _check_defeat() -> bool:
	var party = PartyManager.get_party();
	var all_dead = true;
	for member in party:
		if member.is_alive():
			all_dead = false;
			break;
	if all_dead:
		_change_state(State.DEFEAT);
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
