class_name ItemsScreen;
extends MenuScreen;

var _item_list: VBoxContainer;
var _empty_label: Label;

func _init() -> void:
	screen_name = "Items";
	screen_order = 0;

func _ready() -> void:
	_build_ui();
	Events.menu_items_data.connect(_on_items_data);

func _build_ui() -> void:
	for child in get_children():
		child.queue_free();

	var scroll = ScrollContainer.new();
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED;
	add_child(scroll);

	_item_list = VBoxContainer.new();
	_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL;
	_item_list.add_theme_constant_override("separation", 4);
	scroll.add_child(_item_list);

	_empty_label = Label.new();
	_empty_label.text = "No items.";
	_empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6));
	_empty_label.add_theme_font_size_override("font_size", 12);
	_item_list.add_child(_empty_label);

func activate() -> void:
	super.activate();
	Events.menu_items_requested.emit();

func _on_items_data(inventory: Dictionary) -> void:
	# Clear previous entries
	for child in _item_list.get_children():
		child.queue_free();

	if inventory.is_empty():
		var lbl = Label.new();
		lbl.text = "No items.";
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6));
		lbl.add_theme_font_size_override("font_size", 12);
		_item_list.add_child(lbl);
		return;

	for item: ItemData in inventory:
		var qty: int = inventory[item];
		var row = _create_item_row(item, qty);
		_item_list.add_child(row);

func _create_item_row(item: ItemData, qty: int) -> HBoxContainer:
	var row = HBoxContainer.new();
	row.add_theme_constant_override("separation", 8);

	var name_label = Label.new();
	name_label.text = item.item_name;
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL;
	name_label.add_theme_font_size_override("font_size", 12);
	row.add_child(name_label);

	var qty_label = Label.new();
	qty_label.text = "x" + str(qty);
	qty_label.add_theme_font_size_override("font_size", 12);
	qty_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6));
	row.add_child(qty_label);

	return row;
