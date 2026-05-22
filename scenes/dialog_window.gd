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

func _init() -> void:
	visible = false;

func _ready():
	Events.show_dialog.connect(display_dialog);
	Events.hide_dialog.connect(close_dialog);
	
func display_dialog(dialog_image: Texture2D, dialog_text: Array[String], dialog_name: String):
	_name_label.clear();
	_text_label.clear();
	
	_portrait_texture.texture = dialog_image;
	_name_label.add_text(dialog_name);
	for text in dialog_text:
		_text_label.add_text(text);
	visible = true;

func close_dialog():
	visible = false;
