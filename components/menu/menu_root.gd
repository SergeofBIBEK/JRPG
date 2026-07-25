class_name MenuRoot;
extends CanvasLayer;

var _screens: Array[MenuScreen] = [];
var _menu_labels: Array[Label] = [];
var _selected_index: int = 0;
var _is_open: bool = false;
var _active_screen: MenuScreen = null;
var _screen_focused: bool = false;

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

func _consume_input() -> void:
	var vp = get_viewport();
	if vp:
		vp.set_input_as_handled();

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if _is_open:
			AudioManager.play_sfx("menu_cancel");
			if _screen_focused:
				_exit_screen();
			else:
				_close_menu();
		else:
			AudioManager.play_sfx("menu_select");
			_open_menu();
		_consume_input();
		return;

	if not _is_open:
		return;

	# When a screen is focused, let the screen handle input
	if _screen_focused:
		if event.is_action_pressed("interact2"):
			AudioManager.play_sfx("menu_cancel");
			_exit_screen();
			_consume_input();
		return;

	if event.is_action_pressed("move_up"):
		_selected_index = wrapi(_selected_index - 1, 0, _screens.size());
		_update_selection();
		AudioManager.play_sfx("menu_cursor");
		_consume_input();
	elif event.is_action_pressed("move_down"):
		_selected_index = wrapi(_selected_index + 1, 0, _screens.size());
		_update_selection();
		AudioManager.play_sfx("menu_cursor");
		_consume_input();
	elif event.is_action_pressed("interact"):
		AudioManager.play_sfx("menu_select");
		_enter_screen();
		_consume_input();

func _open_menu() -> void:
	_is_open = true;
	_screen_focused = false;
	_background.visible = true;
	_menu_container.visible = true;
	_selected_index = 0;
	_update_selection();
	get_tree().paused = true;
	Events.menu_opened.emit();

func _close_menu() -> void:
	_is_open = false;
	_screen_focused = false;
	_background.visible = false;
	_menu_container.visible = false;

	if _active_screen:
		_active_screen.deactivate();
		_active_screen = null;

	get_tree().paused = false;
	Events.menu_closed.emit();

func _enter_screen() -> void:
	if _active_screen:
		_screen_focused = true;
		_active_screen.enter();

func _exit_screen() -> void:
	if _active_screen:
		_screen_focused = false;
		_active_screen.exit();

func _update_selection() -> void:
	# Deactivate previous screen
	if _active_screen:
		_active_screen.deactivate();
		_active_screen = null;

	# Update label styling
	for i in _menu_labels.size():
		var label = _menu_labels[i];
		if i == _selected_index:
			label.add_theme_color_override("font_color", Color.YELLOW);
			label.text = "> " + _screens[i].screen_name;
		else:
			label.add_theme_color_override("font_color", Color.WHITE);
			label.text = _screens[i].screen_name;

	# Activate the selected screen immediately (show + load data)
	if _selected_index >= 0 and _selected_index < _screens.size():
		_active_screen = _screens[_selected_index];
		_active_screen.activate();
