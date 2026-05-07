class_name Player;
extends CharacterBody2D;

@export var move_speed: float = 90.0;

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D;

var facing: String = "down";

func _physics_process(_delta: float) -> void:
	var input_dir := Vector2.ZERO;
	
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1;
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1;
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1;
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1;
		
	if abs(input_dir.x) > abs(input_dir.y):
		input_dir.y = 0;
	elif abs(input_dir.y) > abs(input_dir.x):
		input_dir.x = 0;
	else:
		input_dir.x = 0;
	
	velocity = input_dir * move_speed;
	
	move_and_slide();
	
	update_facing(input_dir);
	update_animation(input_dir);
	
func update_facing(input_dir: Vector2) -> void:
	if input_dir == Vector2.ZERO:
		return;
	
	if input_dir.x < 0:
		facing = "left";
	elif input_dir.x > 0:
		facing = "right";
	elif input_dir.y < 0:
		facing = "up";
	else:
		facing = "down";

func update_animation(input_dir: Vector2) -> void:
	var walking = input_dir != Vector2.ZERO;
	var animationToPlay := "idle_down";
	
	match facing:
		"down":
			sprite.flip_h = false;
			if walking:
				animationToPlay = "walk_down";
			else:
				animationToPlay = "idle_down";
		"up":
			sprite.flip_h = false;
			if walking:
				animationToPlay = "walk_up";
			else:
				animationToPlay = "idle_up";
		"left":
			sprite.flip_h = true;
			if walking:
				animationToPlay = "walk_side";
			else:
				animationToPlay = "idle_side";
		"right":
			sprite.flip_h = false;
			if walking:
				animationToPlay = "walk_side";
			else:
				animationToPlay = "idle_side";
		
	sprite.play(animationToPlay);
