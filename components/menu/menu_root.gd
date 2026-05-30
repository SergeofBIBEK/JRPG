class_name MenuRoot;
extends CanvasLayer;

var _screens: Array[MenuScreen] = [];
var _menu_labels: Array[Label] = [];
var _selected_index: int = 0;
var _is_open: bool = false;
var _active_screen: MenuScreen = null;

@onready var _background: ColorRect = $Background;
@onready var _menu_container: HBoxContainer = $MenuContainer;
@onready var _menu_list: VBoxContainer = $MenuContainer/MenuList;
@onready var _screen_container: PanelContainer = $MenuContainer/ScreenContainer;

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS;
	_discover_screens();
	_build_menu_list();
	_close_menu();

func _discover_screens() -> void:
	_screens.clear();

	for child in get_children():
		if child is MenuScreen:
			_screens.append(child);
			child.visible = false;

	_screens.sort_custom(func(a: MenuScreen, b: MenuScreen):
		return a.screen_order < b.screen_order;
	);

func _build_menu_list() -> void:
	for child in _menu_list.get_children():
		child.queue_free();

	_menu_labels.clear();

	for screen in _screens:
		var label = Label.new();
		label.text = screen.screen_name;
		label.add_theme_font_size_override("font_size", 16);
		_menu_list.add_child(label);
		_menu_labels.append(label);

	_update_selection();

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if _is_open:
			_close_menu();
		else:
			_open_menu();
		get_viewport().set_input_as_handled();
		return;

	if not _is_open:
		return;

	if event.is_action_pressed("move_up"):
		_selected_index = wrapi(_selected_index - 1, 0, _screens.size());
		_update_selection();
		get_viewport().set_input_as_handled();
	elif event.is_action_pressed("move_down"):
		_selected_index = wrapi(_selected_index + 1, 0, _screens.size());
		_update_selection();
		get_viewport().set_input_as_handled();
	elif event.is_action_pressed("interact"):
		_activate_screen(_selected_index);
		get_viewport().set_input_as_handled();

func _open_menu() -> void:
	_is_open = true;
	_background.visible = true;
	_menu_container.visible = true;
	_selected_index = 0;
	_update_selection();
	get_tree().paused = true;
	Events.menu_opened.emit();

func _close_menu() -> void:
	_is_open = false;
	_background.visible = false;
	_menu_container.visible = false;

	if _active_screen:
		_active_screen.deactivate();
		_active_screen = null;

	get_tree().paused = false;
	Events.menu_closed.emit();

func _activate_screen(index: int) -> void:
	if index < 0 or index >= _screens.size():
		return;

	if _active_screen:
		_active_screen.deactivate();

	_active_screen = _screens[index];
	_active_screen.activate();

func _update_selection() -> void:
	for i in _menu_labels.size():
		var label = _menu_labels[i];
		if i == _selected_index:
			label.add_theme_color_override("font_color", Color.YELLOW);
			label.text = "> " + _screens[i].screen_name;
		else:
			label.add_theme_color_override("font_color", Color.WHITE);
			label.text = _screens[i].screen_name;
