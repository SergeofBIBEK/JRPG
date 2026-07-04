class_name StatusScreen;
extends MenuScreen;

var _party_list: VBoxContainer;

func _init() -> void:
	screen_name = "Status";
	screen_order = 1;

func _ready() -> void:
	_build_ui();
	Events.menu_status_data.connect(_on_status_data);

func _build_ui() -> void:
	# Remove any editor placeholder children
	for child in get_children():
		child.queue_free();

	var scroll = ScrollContainer.new();
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED;
	add_child(scroll);

	_party_list = VBoxContainer.new();
	_party_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL;
	_party_list.add_theme_constant_override("separation", 12);
	scroll.add_child(_party_list);

func activate() -> void:
	super.activate();
	Events.menu_status_requested.emit();

func _on_status_data(party: Array[CharacterData]) -> void:
	for child in _party_list.get_children():
		child.queue_free();

	if party.is_empty():
		var lbl = Label.new();
		lbl.text = "No party members.";
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6));
		lbl.add_theme_font_size_override("font_size", 12);
		_party_list.add_child(lbl);
		return;

	for character: CharacterData in party:
		var card = _create_character_card(character);
		_party_list.add_child(card);

func _create_character_card(character: CharacterData) -> PanelContainer:
	var panel = PanelContainer.new();

	var style = StyleBoxFlat.new();
	style.bg_color = Color(0.12, 0.12, 0.18, 0.8);
	style.corner_radius_top_left = 4;
	style.corner_radius_top_right = 4;
	style.corner_radius_bottom_left = 4;
	style.corner_radius_bottom_right = 4;
	style.content_margin_left = 10;
	style.content_margin_right = 10;
	style.content_margin_top = 8;
	style.content_margin_bottom = 8;
	panel.add_theme_stylebox_override("panel", style);

	var vbox = VBoxContainer.new();
	vbox.add_theme_constant_override("separation", 4);
	panel.add_child(vbox);

	# Row 1: Name + Level
	var header = HBoxContainer.new();
	vbox.add_child(header);

	var name_label = Label.new();
	name_label.text = character.character_name;
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL;
	name_label.add_theme_font_size_override("font_size", 14);
	name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5));
	header.add_child(name_label);

	var level_label = Label.new();
	level_label.text = "Lv. " + str(character.level);
	level_label.add_theme_font_size_override("font_size", 12);
	level_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7));
	header.add_child(level_label);

	# Row 2: EXP + Gold
	var info_row = HBoxContainer.new();
	info_row.add_theme_constant_override("separation", 16);
	vbox.add_child(info_row);

	var exp_label = Label.new();
	exp_label.text = "EXP " + str(character.experience) + "/" + str(character.exp_to_next_level());
	exp_label.add_theme_font_size_override("font_size", 10);
	exp_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0));
	info_row.add_child(exp_label);

	var gold_label = Label.new();
	gold_label.text = "Gold " + str(character.gold);
	gold_label.add_theme_font_size_override("font_size", 10);
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3));
	info_row.add_child(gold_label);

	# Row 3: HP bar
	var hp_row = _create_stat_row(
		"HP",
		str(character.current_hp) + " / " + str(character.max_hp),
		Color(0.3, 0.8, 0.3)
	);
	vbox.add_child(hp_row);

	# Row 3: MP bar
	var mp_row = _create_stat_row(
		"MP",
		str(character.current_mp) + " / " + str(character.max_mp),
		Color(0.3, 0.5, 0.9)
	);
	vbox.add_child(mp_row);

	# Row 4: ATK / DEF / SPD
	var stats_row = HBoxContainer.new();
	stats_row.add_theme_constant_override("separation", 16);
	vbox.add_child(stats_row);

	for stat_pair in [["ATK", character.attack], ["DEF", character.defense], ["SPD", character.speed]]:
		var stat_label = Label.new();
		stat_label.text = str(stat_pair[0]) + " " + str(stat_pair[1]);
		stat_label.add_theme_font_size_override("font_size", 10);
		stat_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6));
		stats_row.add_child(stat_label);

	return panel;

func _create_stat_row(label_text: String, value_text: String, color: Color) -> HBoxContainer:
	var row = HBoxContainer.new();
	row.add_theme_constant_override("separation", 8);

	var label = Label.new();
	label.text = label_text;
	label.custom_minimum_size.x = 24;
	label.add_theme_font_size_override("font_size", 11);
	label.add_theme_color_override("font_color", color);
	row.add_child(label);

	var value = Label.new();
	value.text = value_text;
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL;
	value.add_theme_font_size_override("font_size", 11);
	row.add_child(value);

	return row;
