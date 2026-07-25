class_name BattleScene;
extends CanvasLayer;

@onready var message_bar: PanelContainer = $BattleRoot/MessageBar;
@onready var message_label: Label = $BattleRoot/MessageBar/MessageLabel;

@onready var command_label_0: Label = $BattleRoot/BottomLeftColumn/CommandMenu/CmdMargin/CmdVBox/CommandLabel0;
@onready var command_label_1: Label = $BattleRoot/BottomLeftColumn/CommandMenu/CmdMargin/CmdVBox/CommandLabel1;
@onready var command_label_2: Label = $BattleRoot/BottomLeftColumn/CommandMenu/CmdMargin/CmdVBox/CommandLabel2;
@onready var command_label_3: Label = $BattleRoot/BottomLeftColumn/CommandMenu/CmdMargin/CmdVBox/CommandLabel3;

@onready var party_panels: Array[PanelContainer] = [
	$BattleRoot/RightColumn/PartyPanel0,
	$BattleRoot/RightColumn/PartyPanel1,
	$BattleRoot/RightColumn/PartyPanel2,
	$BattleRoot/RightColumn/PartyPanel3,
];
@onready var party_name_0: Label = $BattleRoot/RightColumn/PartyPanel0/Margin0/VBox0/PartyName0;
@onready var party_hp_0: Label = $BattleRoot/RightColumn/PartyPanel0/Margin0/VBox0/PartyHP0;
@onready var party_mp_0: Label = $BattleRoot/RightColumn/PartyPanel0/Margin0/VBox0/PartyMP0;

@onready var party_name_1: Label = $BattleRoot/RightColumn/PartyPanel1/Margin1/VBox1/PartyName1;
@onready var party_hp_1: Label = $BattleRoot/RightColumn/PartyPanel1/Margin1/VBox1/PartyHP1;
@onready var party_mp_1: Label = $BattleRoot/RightColumn/PartyPanel1/Margin1/VBox1/PartyMP1;

@onready var party_name_2: Label = $BattleRoot/RightColumn/PartyPanel2/Margin2/VBox2/PartyName2;
@onready var party_hp_2: Label = $BattleRoot/RightColumn/PartyPanel2/Margin2/VBox2/PartyHP2;
@onready var party_mp_2: Label = $BattleRoot/RightColumn/PartyPanel2/Margin2/VBox2/PartyMP2;

@onready var party_name_3: Label = $BattleRoot/RightColumn/PartyPanel3/Margin3/VBox3/PartyName3;
@onready var party_hp_3: Label = $BattleRoot/RightColumn/PartyPanel3/Margin3/VBox3/PartyHP3;
@onready var party_mp_3: Label = $BattleRoot/RightColumn/PartyPanel3/Margin3/VBox3/PartyMP3;

@onready var info_text: Label = $BattleRoot/BottomLeftColumn/InfoBox/InfoMargin/InfoText;

@onready var enemy_name_label: Label = $BattleRoot/EnemyInfoPanel/EnemyInfoMargin/EnemyInfoVBox/EnemyNameLabel;
@onready var enemy_hp_label: Label = $BattleRoot/EnemyInfoPanel/EnemyInfoMargin/EnemyInfoVBox/EnemyHPLabel;

@onready var player_sprite: Sprite2D = $BattleRoot/PlayerSprite;
@onready var enemy_node: ColorRect = $BattleRoot/EnemyPlaceholder;

var _command_labels: Array[Label] = [];
var _command_names: Array[String] = ["Attack", "Defend", "Item", "Run"];
var _command_descriptions: Array[String] = [
	"Deal damage to the enemy.",
	"Reduce incoming damage this turn.",
	"Use an item from your inventory.",
	"Flee from battle.",
];
var _current_index: int = 0;
var _message_tween: Tween = null;

var _in_item_menu: bool = false;
var _item_list: Array[ItemData] = [];
var _item_index: int = 0;



var _player_rest_pos: Vector2;
var _enemy_rest_pos: Vector2;
var _attack_tween: Tween = null;
var _hit_tween: Tween = null;

func _ready() -> void:
	_command_labels = [command_label_0, command_label_1, command_label_2, command_label_3];
	message_bar.modulate.a = 0.0;

	Events.battle_state_changed.connect(_on_battle_state_changed);
	Events.battle_message.connect(_on_battle_message);
	Events.battle_hp_updated.connect(_on_battle_hp_updated);
	Events.battle_enemy_hp_updated.connect(_on_battle_enemy_hp_updated);
	Events.battle_player_attack_anim.connect(_on_player_attack_anim);
	Events.battle_enemy_attack_anim.connect(_on_enemy_attack_anim);
	Events.battle_player_hit_anim.connect(_on_player_hit_anim);
	Events.battle_enemy_hit_anim.connect(_on_enemy_hit_anim);

	_player_rest_pos = player_sprite.position;
	_enemy_rest_pos = enemy_node.position;

	_populate_party_panels();
	_update_cursor();
	BattleManager.start_random_battle();
	_update_enemy_info();

func _exit_tree() -> void:
	if Events.battle_state_changed.is_connected(_on_battle_state_changed):
		Events.battle_state_changed.disconnect(_on_battle_state_changed);
	if Events.battle_message.is_connected(_on_battle_message):
		Events.battle_message.disconnect(_on_battle_message);
	if Events.battle_hp_updated.is_connected(_on_battle_hp_updated):
		Events.battle_hp_updated.disconnect(_on_battle_hp_updated);
	if Events.battle_enemy_hp_updated.is_connected(_on_battle_enemy_hp_updated):
		Events.battle_enemy_hp_updated.disconnect(_on_battle_enemy_hp_updated);
	if Events.battle_player_attack_anim.is_connected(_on_player_attack_anim):
		Events.battle_player_attack_anim.disconnect(_on_player_attack_anim);
	if Events.battle_enemy_attack_anim.is_connected(_on_enemy_attack_anim):
		Events.battle_enemy_attack_anim.disconnect(_on_enemy_attack_anim);
	if Events.battle_player_hit_anim.is_connected(_on_player_hit_anim):
		Events.battle_player_hit_anim.disconnect(_on_player_hit_anim);
	if Events.battle_enemy_hit_anim.is_connected(_on_enemy_hit_anim):
		Events.battle_enemy_hit_anim.disconnect(_on_enemy_hit_anim);

func _unhandled_input(event: InputEvent) -> void:
	if BattleManager.current_state != BattleManager.State.PLAYER_COMMAND:
		return;

	if event.is_action_pressed("move_up"):
		_navigate(-1);
		AudioManager.play_sfx("menu_cursor");
		var vp = get_viewport();
		if vp: vp.set_input_as_handled();
	elif event.is_action_pressed("move_down"):
		_navigate(1);
		AudioManager.play_sfx("menu_cursor");
		var vp = get_viewport();
		if vp: vp.set_input_as_handled();
	elif event.is_action_pressed("interact"):
		AudioManager.play_sfx("menu_select");
		_confirm_selection();
		var vp = get_viewport();
		if vp: vp.set_input_as_handled();
	elif event.is_action_pressed("menu"):
		if _in_item_menu:
			AudioManager.play_sfx("menu_cancel");
			_close_item_menu();
			var vp = get_viewport();
			if vp: vp.set_input_as_handled();

func _navigate(direction: int) -> void:
	if _in_item_menu:
		if _item_list.size() == 0:
			return;
		_item_index = wrapi(_item_index + direction, 0, _item_list.size());
		_update_item_cursor();
	else:
		_current_index = wrapi(_current_index + direction, 0, _command_labels.size());
		_update_cursor();

func _confirm_selection() -> void:
	if _in_item_menu:
		_select_item();
	else:
		_execute_command(_current_index);

func _update_cursor() -> void:
	for i in range(_command_labels.size()):
		if i == _current_index:
			_command_labels[i].text = "▶ " + _command_names[i];
		else:
			_command_labels[i].text = "   " + _command_names[i];

	info_text.text = _command_descriptions[_current_index];

func _execute_command(index: int) -> void:
	var command = _command_names[index];
	if command == "Item":
		_open_item_menu();
	else:
		BattleManager.select_command(command);

func _open_item_menu() -> void:
	var inventory = ItemManager.get_all_items();
	_item_list.clear();
	for item in inventory:
		_item_list.append(item);

	if _item_list.is_empty():
		_show_message("No items in inventory.");
		return;

	_in_item_menu = true;
	_item_index = 0;
	_update_item_cursor();
	info_text.text = "Choose an item. Press ESC to go back.";

func _update_item_cursor() -> void:
	for i in range(_command_labels.size()):
		if i < _item_list.size():
			var item = _item_list[i];
			var qty = ItemManager.get_item_count(item);
			if i == _item_index:
				_command_labels[i].text = "▶ " + item.item_name + " x" + str(qty);
			else:
				_command_labels[i].text = "   " + item.item_name + " x" + str(qty);
			_command_labels[i].visible = true;
		else:
			_command_labels[i].text = "";
			_command_labels[i].visible = false;

func _select_item() -> void:
	if _item_index >= _item_list.size():
		return;
	var item = _item_list[_item_index];
	_close_item_menu();
	BattleManager.select_item(item);

func _close_item_menu() -> void:
	_in_item_menu = false;
	for label in _command_labels:
		label.visible = true;
	_update_cursor();

func _on_battle_state_changed(new_state: String) -> void:
	match new_state:
		"PLAYER_COMMAND":
			_current_index = 0;
			_update_cursor();
		"VICTORY", "DEFEAT", "FLED":
			for label in _command_labels:
				label.text = "";
			info_text.text = "";

func _on_battle_message(text: String) -> void:
	_show_message(text);

func _on_battle_hp_updated() -> void:
	_populate_party_panels();

func _on_battle_enemy_hp_updated() -> void:
	_update_enemy_info();

func _show_message(msg: String) -> void:
	if _message_tween and _message_tween.is_valid():
		_message_tween.kill();

	message_label.text = msg;
	message_bar.modulate.a = 1.0;

	_message_tween = create_tween();
	_message_tween.tween_interval(2.0);
	_message_tween.tween_property(message_bar, "modulate:a", 0.0, 0.8);

func _populate_party_panels() -> void:
	var party = PartyManager.get_party();
	var party_names: Array[Label] = [party_name_0, party_name_1, party_name_2, party_name_3];
	var party_hps: Array[Label] = [party_hp_0, party_hp_1, party_hp_2, party_hp_3];
	var party_mps: Array[Label] = [party_mp_0, party_mp_1, party_mp_2, party_mp_3];

	for i in range(4):
		if i < party.size():
			var member = party[i];
			party_names[i].text = "Lv" + str(member.level) + "  " + member.character_name;
			party_hps[i].text = "HP: " + str(member.current_hp) + "/" + str(member.max_hp);
			party_mps[i].text = "MP: " + str(member.current_mp) + "/" + str(member.max_mp);
			party_panels[i].visible = true;
		else:
			party_panels[i].visible = false;

func _update_enemy_info() -> void:
	if BattleManager.enemy != null:
		enemy_name_label.text = BattleManager.enemy.enemy_name;
		enemy_hp_label.text = "HP: " + str(BattleManager.enemy.current_hp) + "/" + str(BattleManager.enemy.max_hp);
	else:
		enemy_name_label.text = "---";
		enemy_hp_label.text = "HP: --/--";

# ── Battle Animations ──────────────────────────────────────────────

func _on_player_attack_anim() -> void:
	if _attack_tween and _attack_tween.is_valid():
		_attack_tween.kill();
	player_sprite.position = _player_rest_pos;
	var lunge_target = _player_rest_pos + Vector2(-30, 0);
	_attack_tween = create_tween();
	_attack_tween.tween_property(player_sprite, "position", lunge_target, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK);
	_attack_tween.tween_property(player_sprite, "position", _player_rest_pos, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD);

func _on_enemy_attack_anim() -> void:
	if _attack_tween and _attack_tween.is_valid():
		_attack_tween.kill();
	enemy_node.position = _enemy_rest_pos;
	var lunge_target = _enemy_rest_pos + Vector2(30, 0);
	_attack_tween = create_tween();
	_attack_tween.tween_property(enemy_node, "position", lunge_target, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK);
	_attack_tween.tween_property(enemy_node, "position", _enemy_rest_pos, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD);

func _on_player_hit_anim() -> void:
	if _hit_tween and _hit_tween.is_valid():
		_hit_tween.kill();
	player_sprite.position = _player_rest_pos;
	player_sprite.modulate = Color.WHITE;
	var knockback_pos = _player_rest_pos + Vector2(12, 0);
	_hit_tween = create_tween();
	# Flash bright white
	_hit_tween.tween_property(player_sprite, "modulate", Color(4, 4, 4, 1), 0.04);
	_hit_tween.tween_property(player_sprite, "modulate", Color.WHITE, 0.04);
	_hit_tween.tween_property(player_sprite, "modulate", Color(4, 4, 4, 1), 0.04);
	_hit_tween.tween_property(player_sprite, "modulate", Color.WHITE, 0.04);
	# Knockback
	_hit_tween.parallel().tween_property(player_sprite, "position", knockback_pos, 0.08).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD);
	_hit_tween.tween_property(player_sprite, "position", _player_rest_pos, 0.15).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD);

func _on_enemy_hit_anim() -> void:
	if _hit_tween and _hit_tween.is_valid():
		_hit_tween.kill();
	enemy_node.position = _enemy_rest_pos;
	enemy_node.modulate = Color.WHITE;
	var knockback_pos = _enemy_rest_pos + Vector2(-12, 0);
	_hit_tween = create_tween();
	# Flash bright white
	_hit_tween.tween_property(enemy_node, "modulate", Color(4, 4, 4, 1), 0.04);
	_hit_tween.tween_property(enemy_node, "modulate", Color.WHITE, 0.04);
	_hit_tween.tween_property(enemy_node, "modulate", Color(4, 4, 4, 1), 0.04);
	_hit_tween.tween_property(enemy_node, "modulate", Color.WHITE, 0.04);
	# Knockback
	_hit_tween.parallel().tween_property(enemy_node, "position", knockback_pos, 0.08).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD);
	_hit_tween.tween_property(enemy_node, "position", _enemy_rest_pos, 0.15).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD);
