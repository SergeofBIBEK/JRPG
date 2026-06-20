class_name BattleScene;
extends CanvasLayer;

# -- Message bar (top overlay) --
@onready var message_bar: PanelContainer = $BattleRoot/MessageBar;
@onready var message_label: Label = $BattleRoot/MessageBar/MessageLabel;

# -- Command labels --
@onready var command_label_0: Label = $BattleRoot/BottomLeftColumn/CommandMenu/CmdMargin/CmdVBox/CommandLabel0;
@onready var command_label_1: Label = $BattleRoot/BottomLeftColumn/CommandMenu/CmdMargin/CmdVBox/CommandLabel1;
@onready var command_label_2: Label = $BattleRoot/BottomLeftColumn/CommandMenu/CmdMargin/CmdVBox/CommandLabel2;
@onready var command_label_3: Label = $BattleRoot/BottomLeftColumn/CommandMenu/CmdMargin/CmdVBox/CommandLabel3;

# -- Party panels --
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

# -- Info box --
@onready var info_text: Label = $BattleRoot/BottomLeftColumn/InfoBox/InfoMargin/InfoText;

# -- State --
var _command_labels: Array[Label] = [];
var _command_names: Array[String] = ["Attack", "Defend", "Item", "Run"];
var _command_descriptions: Array[String] = [
	"Deal damage to the enemy.",
	"Reduce incoming damage this turn.",
	"Use an item from your inventory.",
	"Flee from battle.",
];
var _current_index: int = 0;
var _battle_over: bool = false;
var _message_tween: Tween = null;

func _ready() -> void:
	_command_labels = [command_label_0, command_label_1, command_label_2, command_label_3];
	# Hide message bar initially
	message_bar.modulate.a = 0.0;
	_populate_party_panels();
	_update_cursor();
	_show_message("A wild enemy appeared!");

func _unhandled_input(event: InputEvent) -> void:
	if _battle_over:
		return;

	if event.is_action_pressed("move_up"):
		_navigate(-1);
		get_viewport().set_input_as_handled();
	elif event.is_action_pressed("move_down"):
		_navigate(1);
		get_viewport().set_input_as_handled();
	elif event.is_action_pressed("interact"):
		_execute_command(_current_index);
		get_viewport().set_input_as_handled();

func _navigate(direction: int) -> void:
	_current_index = wrapi(_current_index + direction, 0, _command_labels.size());
	_update_cursor();

func _update_cursor() -> void:
	for i in range(_command_labels.size()):
		if i == _current_index:
			_command_labels[i].text = "▶ " + _command_names[i];
		else:
			_command_labels[i].text = "   " + _command_names[i];

	info_text.text = _command_descriptions[_current_index];

func _execute_command(index: int) -> void:
	match _command_names[index]:
		"Attack":
			var party = PartyManager.get_party();
			var attacker_name = "Hero";
			if party.size() > 0:
				attacker_name = party[0].character_name;
			_show_message(attacker_name + " attacks! 12 damage dealt.");
		"Defend":
			var party = PartyManager.get_party();
			var defender_name = "Hero";
			if party.size() > 0:
				defender_name = party[0].character_name;
			_show_message(defender_name + " is defending.");
		"Item":
			var items = ItemManager.get_all_items();
			if items.is_empty():
				_show_message("No items in inventory.");
			else:
				var item_lines: String = "Items: ";
				var entries: Array[String] = [];
				for item in items:
					entries.append(item.item_name + " x" + str(items[item]));
				item_lines += ", ".join(entries);
				_show_message(item_lines);
		"Run":
			_battle_over = true;
			_show_message("Ran away!");
			await get_tree().create_timer(1.0).timeout;
			Events.battle_ended.emit();

## Show a temporary message in the top bar, then fade it out.
func _show_message(msg: String) -> void:
	# Kill any existing fade tween
	if _message_tween and _message_tween.is_valid():
		_message_tween.kill();

	message_label.text = msg;
	message_bar.modulate.a = 1.0;

	# Hold for 2 seconds, then fade out over 0.8 seconds
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
			party_names[i].text = member.character_name;
			party_hps[i].text = "HP: " + str(member.current_hp) + "/" + str(member.max_hp);
			party_mps[i].text = "MP: " + str(member.current_mp) + "/" + str(member.max_mp);
			party_panels[i].visible = true;
		else:
			party_panels[i].visible = false;
