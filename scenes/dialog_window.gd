@tool
class_name DialogWindow
extends Control

@onready var _text_label: RichTextLabel = find_child(
	"DialogText",
	true,
	false
) as RichTextLabel;

@onready var _name_label: RichTextLabel = find_child(
	"DialogName",
	true,
	false
) as RichTextLabel;

@onready var _portrait_texture: TextureRect = find_child(
	"PortraitTexture",
	true,
	false
) as TextureRect;

@onready var _advance_indicator: Label = find_child(
	"AdvanceIndicator",
	true,
	false
) as Label;

var _pages: Array[String] = [];
var _current_page: int = 0;
var _is_active: bool = false;

func _init() -> void:
	visible = false;

func _ready():
	Events.show_dialog.connect(display_dialog);
	Events.hide_dialog.connect(close_dialog);

func _unhandled_input(event: InputEvent) -> void:
	if not _is_active:
		return;

	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled();
		_advance_page();

func display_dialog(dialog_image: Texture2D, dialog_text: Array[String], dialog_name: String):
	_pages = dialog_text;
	_current_page = 0;
	_is_active = true;

	_portrait_texture.texture = dialog_image;
	_name_label.clear();
	_name_label.add_text(dialog_name);

	_show_current_page();
	visible = true;

func _show_current_page() -> void:
	_text_label.clear();
	if _current_page < _pages.size():
		_text_label.add_text(_pages[_current_page]);

	# Show or hide advance indicator
	if _advance_indicator:
		_advance_indicator.visible = _current_page < _pages.size() - 1;

func _advance_page() -> void:
	_current_page += 1;
	if _current_page >= _pages.size():
		close_dialog();
		Events.dialog_finished.emit();
	else:
		_show_current_page();

func close_dialog():
	_is_active = false;
	visible = false;
