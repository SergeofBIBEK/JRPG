class_name FadeOverlay;
extends CanvasLayer;

var _color_rect: ColorRect;

func _ready() -> void:
	layer = 100;
	_color_rect = ColorRect.new();
	_color_rect.color = Color.BLACK;
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE;
	add_child(_color_rect);
	_color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);
	# Start fully opaque so nothing is visible until fade_in is called
	_color_rect.modulate.a = 1.0;

func fade_in(duration: float = 0.3) -> void:
	_color_rect.modulate.a = 1.0;
	var tween = create_tween();
	tween.tween_property(_color_rect, "modulate:a", 0.0, duration);
	await tween.finished;

func fade_out(duration: float = 0.3) -> void:
	_color_rect.modulate.a = 0.0;
	var tween = create_tween();
	tween.tween_property(_color_rect, "modulate:a", 1.0, duration);
	await tween.finished;
