class_name TransitionManager;
extends Node;

@export var fade_duration: float = 0.3;
@export var fade_in_delay: float = 0.5;

var _locked: bool = true;
var _overlay: ColorRect;

func _ready() -> void:
	Events.transition_requested.connect(_on_transition_requested);
	_create_overlay();
	_fade_in();

func _create_overlay() -> void:
	var canvas_layer = CanvasLayer.new();
	canvas_layer.layer = 100;
	add_child(canvas_layer);

	_overlay = ColorRect.new();
	_overlay.color = Color.BLACK;
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE;
	canvas_layer.add_child(_overlay);
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);

func _fade_in() -> void:
	_overlay.modulate.a = 1.0;
	await get_tree().process_frame;
	await get_tree().process_frame;
	var tween = create_tween();
	tween.tween_interval(fade_in_delay);
	tween.tween_property(_overlay, "modulate:a", 0.0, fade_duration);
	tween.tween_callback(_unlock);

func _fade_out(callback: Callable) -> void:
	_overlay.modulate.a = 0.0;
	var tween = create_tween();
	tween.tween_property(_overlay, "modulate:a", 1.0, fade_duration);
	tween.tween_callback(callback);

func _unlock() -> void:
	_locked = false;

func _on_transition_requested(target_scene_path: String, spawn_location: String) -> void:
	if _locked:
		return;

	if target_scene_path == "":
		push_error("TransitionManager: target_scene_path is empty, cannot transition.");
		return;

	var scene = load(target_scene_path) as PackedScene;
	if scene == null:
		push_error("TransitionManager: failed to load scene at: " + target_scene_path);
		return;

	_locked = true;
	_fade_out(func():
		Events.pending_spawn_location = spawn_location;
		get_tree().change_scene_to_packed(scene);
	);
