class_name PickupBehavior;
extends InteractionBehavior;

@export var portrait_texture: Texture2D;
@export var item: ItemData;
@export var quantity: int = 1;
@export var pickup_dialog_lines: Array[String] = ["You found something!"];
@export var already_picked_up_lines: Array[String] = ["There's nothing here."];

## Unique flag name for this pickup. If empty, one is generated from the node path.
@export var pickup_flag: String = "";

var _is_interacting: bool = false;

func _init():
	interaction_name = "Check";

func _ready() -> void:
	if pickup_flag == "":
		pickup_flag = "pickup_" + str(get_path());

func process_interaction():
	if _is_interacting:
		return;
	_is_interacting = true;

	var lines: Array[String];

	if QuestManager.has_flag(pickup_flag):
		lines = already_picked_up_lines;
	else:
		lines = pickup_dialog_lines;
		if item:
			ItemManager.add_item(item, quantity);
		QuestManager.set_flag(pickup_flag);

	Events.show_dialog.emit(portrait_texture, lines, "");
	await Events.dialog_finished;
	_is_interacting = false;
