extends Control;

enum MenuOption { NEW_GAME, CONTINUE, QUIT }

var _options: Array[Dictionary] = [];
var _option_labels: Array[Label] = [];
var _selected_index: int = 0;
var _is_active: bool = true;

# Load screen state
var _showing_load_screen: bool = false;
var _load_slot_panels: Array[PanelContainer] = [];
var _load_selected_slot: int = 0;

@onready var _title_label: Label = $VBoxContainer/TitleLabel;
@onready var _menu_container: VBoxContainer = $VBoxContainer/MenuContainer;
@onready var _load_container: VBoxContainer = $VBoxContainer/LoadContainer;
@onready var _fade_rect: ColorRect = $FadeRect;

func _ready() -> void:
	_options = [
		{ "name": "New Game", "action": MenuOption.NEW_GAME },
		{ "name": "Continue", "action": MenuOption.CONTINUE },
		{ "name": "Quit", "action": MenuOption.QUIT },
	];

	_build_menu();
	_build_load_screen();
	_show_main_menu();

	# Fade in
	_fade_rect.modulate.a = 1.0;
	var tween = create_tween();
	tween.tween_property(_fade_rect, "modulate:a", 0.0, 0.5);

func _build_menu() -> void:
	for child in _menu_container.get_children():
		child.queue_free();
	_option_labels.clear();

	for option in _options:
		var label = Label.new();
		label.text = option["name"];
		label.add_theme_font_size_override("font_size", 16);
		_menu_container.add_child(label);
		_option_labels.append(label);

	_update_menu_highlight();

func _build_load_screen() -> void:
	for child in _load_container.get_children():
		child.queue_free();
	_load_slot_panels.clear();

	var title = Label.new();
	title.text = "Select Save File";
	title.add_theme_font_size_override("font_size", 14);
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5));
	_load_container.add_child(title);

	for i in SaveManager.MAX_SLOTS:
		var panel = _create_load_slot_panel(i);
		_load_container.add_child(panel);
		_load_slot_panels.append(panel);

	var hint = Label.new();
	hint.text = "[X] Back";
	hint.add_theme_font_size_override("font_size", 10);
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5));
	_load_container.add_child(hint);

func _create_load_slot_panel(slot: int) -> PanelContainer:
	var panel = PanelContainer.new();
	var style = StyleBoxFlat.new();
	style.bg_color = Color(0.12, 0.12, 0.18, 0.8);
	style.corner_radius_top_left = 3;
	style.corner_radius_top_right = 3;
	style.corner_radius_bottom_left = 3;
	style.corner_radius_bottom_right = 3;
	style.content_margin_left = 8;
	style.content_margin_right = 8;
	style.content_margin_top = 6;
	style.content_margin_bottom = 6;
	panel.add_theme_stylebox_override("panel", style);

	var hbox = HBoxContainer.new();
	hbox.add_theme_constant_override("separation", 12);
	panel.add_child(hbox);

	var slot_label = Label.new();
	slot_label.text = "Slot " + str(slot + 1);
	slot_label.add_theme_font_size_override("font_size", 12);
	slot_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7));
	slot_label.custom_minimum_size.x = 44;
	hbox.add_child(slot_label);

	var info = SaveManager.get_slot_info(slot);
	if info.is_empty():
		var empty_label = Label.new();
		empty_label.text = "— Empty —";
		empty_label.add_theme_font_size_override("font_size", 11);
		empty_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4));
		hbox.add_child(empty_label);
	else:
		var details = VBoxContainer.new();
		details.add_theme_constant_override("separation", 1);
		hbox.add_child(details);

		var name_lbl = Label.new();
		name_lbl.text = info.get("character_name", "???") + "  Lv." + str(info.get("level", 1));
		name_lbl.add_theme_font_size_override("font_size", 11);
		details.add_child(name_lbl);

		var map_name = SaveManager._format_map_name(info.get("current_map", ""));
		var map_lbl = Label.new();
		map_lbl.text = map_name;
		map_lbl.add_theme_font_size_override("font_size", 10);
		map_lbl.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9));
		details.add_child(map_lbl);

	return panel;

func _show_main_menu() -> void:
	_showing_load_screen = false;
	_menu_container.visible = true;
	_load_container.visible = false;
	_selected_index = 0;
	_update_menu_highlight();

func _show_load_screen() -> void:
	if not SaveManager.any_save_exists():
		return;
	_showing_load_screen = true;
	_menu_container.visible = false;
	_load_container.visible = true;
	_load_selected_slot = 0;
	# Rebuild slots to get fresh info
	_build_load_screen();
	_update_load_highlight();

func _consume_input() -> void:
	var vp = get_viewport();
	if vp:
		vp.set_input_as_handled();

func _unhandled_input(event: InputEvent) -> void:
	if not _is_active:
		return;

	if _showing_load_screen:
		_handle_load_input(event);
	else:
		_handle_menu_input(event);

func _handle_menu_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_selected_index = wrapi(_selected_index - 1, 0, _options.size());
		_update_menu_highlight();
		_consume_input();
	elif event.is_action_pressed("move_down"):
		_selected_index = wrapi(_selected_index + 1, 0, _options.size());
		_update_menu_highlight();
		_consume_input();
	elif event.is_action_pressed("interact"):
		_select_option(_options[_selected_index]["action"]);
		_consume_input();

func _handle_load_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_load_selected_slot = wrapi(_load_selected_slot - 1, 0, SaveManager.MAX_SLOTS);
		_update_load_highlight();
		_consume_input();
	elif event.is_action_pressed("move_down"):
		_load_selected_slot = wrapi(_load_selected_slot + 1, 0, SaveManager.MAX_SLOTS);
		_update_load_highlight();
		_consume_input();
	elif event.is_action_pressed("interact"):
		_try_load_slot(_load_selected_slot);
		_consume_input();
	elif event.is_action_pressed("interact2") or event.is_action_pressed("menu"):
		_show_main_menu();
		_consume_input();

func _select_option(action: MenuOption) -> void:
	match action:
		MenuOption.NEW_GAME:
			_start_new_game();
		MenuOption.CONTINUE:
			_show_load_screen();
		MenuOption.QUIT:
			get_tree().quit();

func _start_new_game() -> void:
	_is_active = false;
	# Clear any stale manager data
	PartyManager.clear();
	ItemManager.clear();
	QuestManager.clear();
	# Make sure SaveManager has no pending load
	SaveManager.consume_pending_load();

	# Fade out and change scene
	var tween = create_tween();
	tween.tween_property(_fade_rect, "modulate:a", 1.0, 0.5);
	await tween.finished;
	get_tree().change_scene_to_file("res://scenes/game.tscn");

func _try_load_slot(slot: int) -> void:
	if not SaveManager.has_save(slot):
		return;

	_is_active = false;

	# Fade out then load
	var tween = create_tween();
	tween.tween_property(_fade_rect, "modulate:a", 1.0, 0.5);
	await tween.finished;

	Events.load_requested.emit(slot);

func _update_menu_highlight() -> void:
	for i in _option_labels.size():
		var label = _option_labels[i];
		if i == _selected_index:
			label.add_theme_color_override("font_color", Color.YELLOW);
			label.text = "> " + _options[i]["name"];
		else:
			label.add_theme_color_override("font_color", Color.WHITE);
			label.text = "  " + _options[i]["name"];

	# Gray out Continue if no saves exist
	if _option_labels.size() > 1:
		var continue_label = _option_labels[1];
		if not SaveManager.any_save_exists():
			if _selected_index == 1:
				continue_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.3));
			else:
				continue_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4));

func _update_load_highlight() -> void:
	for i in _load_slot_panels.size():
		var panel = _load_slot_panels[i];
		var style = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat;
		if i == _load_selected_slot:
			style.border_width_left = 2;
			style.border_width_top = 2;
			style.border_width_right = 2;
			style.border_width_bottom = 2;
			style.border_color = Color(1.0, 0.9, 0.4);
			style.bg_color = Color(0.18, 0.18, 0.25, 0.9);
		else:
			style.border_width_left = 0;
			style.border_width_top = 0;
			style.border_width_right = 0;
			style.border_width_bottom = 0;
			style.bg_color = Color(0.12, 0.12, 0.18, 0.8);
		panel.add_theme_stylebox_override("panel", style);
