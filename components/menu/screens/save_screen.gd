class_name SaveScreen;
extends MenuScreen;

var _slot_container: VBoxContainer;
var _status_label: Label;
var _slot_panels: Array[PanelContainer] = [];
var _selected_slot: int = 0;
var _is_focused: bool = false;
var _showing_confirm: bool = false;

func _init() -> void:
	screen_name = "Save";
	screen_order = 2;

func _ready() -> void:
	_build_ui();
	Events.save_completed.connect(_on_save_completed);

func _build_ui() -> void:
	for child in get_children():
		child.queue_free();

	var vbox = VBoxContainer.new();
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);
	vbox.add_theme_constant_override("separation", 6);
	add_child(vbox);

	var title = Label.new();
	title.text = "Save Game";
	title.add_theme_font_size_override("font_size", 14);
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5));
	vbox.add_child(title);

	_slot_container = VBoxContainer.new();
	_slot_container.add_theme_constant_override("separation", 4);
	vbox.add_child(_slot_container);

	_status_label = Label.new();
	_status_label.text = "";
	_status_label.add_theme_font_size_override("font_size", 11);
	_status_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4));
	vbox.add_child(_status_label);

func activate() -> void:
	super.activate();
	_refresh_slots();
	_selected_slot = 0;
	_is_focused = false;
	_showing_confirm = false;
	_status_label.text = "";
	_update_slot_highlight();

func enter() -> void:
	_is_focused = true;
	_update_slot_highlight();

func exit() -> void:
	_is_focused = false;
	_showing_confirm = false;
	_status_label.text = "";
	_update_slot_highlight();

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _is_focused:
		return;

	if _showing_confirm:
		# Waiting for confirm/cancel on overwrite
		if event.is_action_pressed("interact"):
			AudioManager.play_sfx("menu_select");
			_do_save(_selected_slot);
			_showing_confirm = false;
			var vp = get_viewport();
			if vp: vp.set_input_as_handled();
		elif event.is_action_pressed("interact2"):
			AudioManager.play_sfx("menu_cancel");
			_status_label.text = "";
			_showing_confirm = false;
			var vp = get_viewport();
			if vp: vp.set_input_as_handled();
		return;

	if event.is_action_pressed("move_up"):
		_selected_slot = wrapi(_selected_slot - 1, 0, SaveManager.MAX_SLOTS);
		_update_slot_highlight();
		AudioManager.play_sfx("menu_cursor");
		var vp = get_viewport();
		if vp: vp.set_input_as_handled();
	elif event.is_action_pressed("move_down"):
		_selected_slot = wrapi(_selected_slot + 1, 0, SaveManager.MAX_SLOTS);
		_update_slot_highlight();
		AudioManager.play_sfx("menu_cursor");
		var vp = get_viewport();
		if vp: vp.set_input_as_handled();
	elif event.is_action_pressed("interact"):
		AudioManager.play_sfx("menu_select");
		_attempt_save(_selected_slot);
		var vp = get_viewport();
		if vp: vp.set_input_as_handled();

func _attempt_save(slot: int) -> void:
	if SaveManager.has_save(slot):
		_status_label.text = "Overwrite? [Z] Yes  [X] No";
		_status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3));
		_showing_confirm = true;
	else:
		_do_save(slot);

func _do_save(slot: int) -> void:
	var success = SaveManager.save_game(slot);
	if success:
		AudioManager.play_sfx("save_confirm");
		_status_label.text = "Saved!";
		_status_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4));
	else:
		_status_label.text = "Save failed!";
		_status_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3));
	_refresh_slots();
	_update_slot_highlight();

func _on_save_completed(_slot: int) -> void:
	pass;

func _refresh_slots() -> void:
	for child in _slot_container.get_children():
		child.queue_free();
	_slot_panels.clear();

	for i in SaveManager.MAX_SLOTS:
		var panel = _create_slot_panel(i);
		_slot_container.add_child(panel);
		_slot_panels.append(panel);

func _create_slot_panel(slot: int) -> PanelContainer:
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

func _update_slot_highlight() -> void:
	for i in _slot_panels.size():
		var panel = _slot_panels[i];
		var style = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat;
		if i == _selected_slot and _is_focused:
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
