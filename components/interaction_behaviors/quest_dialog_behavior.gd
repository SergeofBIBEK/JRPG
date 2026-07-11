class_name QuestDialogBehavior;
extends InteractionBehavior;

@export var portrait_texture: Texture2D;
@export var dialog_name: String;

@export_group("Default Dialog")
@export var dialog_lines: Array[String] = ["..."];

@export_group("Alternate Dialog")
@export var alt_dialog_lines: Array[String] = [];

@export_group("Conditions")
## Flag that must be set for the alternate dialog to trigger.
@export var required_flag: String = "";
## Item that must be in inventory for the alternate dialog to trigger.
@export var required_item: ItemData;
## If true, the required item is consumed when the alternate dialog plays.
@export var consume_item: bool = false;

@export_group("Rewards")
## Flag to set after this conversation finishes (set on any conversation).
@export var flag_to_set: String = "";
## Flag to set only when the alternate dialog plays.
@export var alt_flag_to_set: String = "";
@export var reward_item: ItemData;
@export var reward_quantity: int = 1;
@export var reward_gold: int = 0;

var _is_interacting: bool = false;

func _init():
	interaction_name = "Talk";

func process_interaction():
	if _is_interacting:
		return;
	_is_interacting = true;

	var use_alt := _check_conditions();
	var lines: Array[String];

	if use_alt and alt_dialog_lines.size() > 0:
		lines = alt_dialog_lines;
		_apply_alt_rewards();
	else:
		lines = dialog_lines;

	# Set the always-set flag
	if flag_to_set != "":
		QuestManager.set_flag(flag_to_set);

	Events.show_dialog.emit(portrait_texture, lines, dialog_name);
	await Events.dialog_finished;
	_is_interacting = false;

func _check_conditions() -> bool:
	var flag_met := true;
	var item_met := true;

	if required_flag != "":
		flag_met = QuestManager.has_flag(required_flag);

	if required_item != null:
		item_met = ItemManager.has_item(required_item);

	return flag_met and item_met;

func _apply_alt_rewards() -> void:
	if consume_item and required_item != null:
		ItemManager.remove_item(required_item, 1);

	if reward_item != null:
		ItemManager.add_item(reward_item, reward_quantity);

	if alt_flag_to_set != "":
		QuestManager.set_flag(alt_flag_to_set);
