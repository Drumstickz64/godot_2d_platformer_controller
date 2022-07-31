class_name PlatformerCharacter2D
extends KinematicBody2D

const APEX_SPEED_BONUS := 1.2

export var max_move_speed: float
export var acceleration: float
export var friction: float
export var jump_power: float
export var gravity: float
export var fall_gravity_modifier := 1.0
export var early_jump_end_gravity_modifier := 1.0
export var max_fall_speed: float
export var __coyote_timer: NodePath
export var __jump_buffer_clear_timer: NodePath

var velocity: Vector2
var hinput: float
var _did_jump: bool
var _did_coyote: bool
var _ended_jump_early: bool
var _is_jump_buffered: bool
var _is_at_jump_apex: bool
var _is_airborne: bool

onready var coyote_timer: Timer = get_node(__coyote_timer)
onready var jump_buffer_clear_timer: Timer = get_node(__jump_buffer_clear_timer)


func _ready() -> void:
	jump_buffer_clear_timer.connect("timeout", self, "clear_jump_buffer")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		_is_jump_buffered = true
		jump_buffer_clear_timer.start()


func _physics_process(delta: float) -> void:
	hinput = Input.get_axis("move_left", "move_right")
	
	apply_gravity(delta)
	
	if _is_airborne and is_on_floor():
		on_land()
	else:
		_is_airborne = true

	_is_at_jump_apex = Input.is_action_pressed("jump") and _did_jump and abs(velocity.y) <= 96.0

	if should_coyote():
		activate_coyote_time()
	
	if _is_jump_buffered and can_jump():
		jump()
		clear_jump_buffer()
	
	if Input.is_action_just_released("jump") and _did_jump and velocity.y < 0.0:
		_ended_jump_early = true
	
	if not is_zero_approx(hinput):
		apply_acceleration(delta)

	if not sign(hinput) == sign(velocity.x):
		apply_friction(delta)
	
	velocity = move_and_slide(velocity, Vector2.UP, true)


func apply_gravity(delta: float) -> void:
	var modifier := 1.0
	modifier *= fall_gravity_modifier if velocity.y > 0.0 else 1.0
	modifier *= early_jump_end_gravity_modifier if _ended_jump_early else 1.0
	modifier *= 0.5 if _is_at_jump_apex else 1.0
	velocity.y = move_toward(velocity.y, max_fall_speed, gravity * modifier * delta)


func jump() -> void:
	velocity.y = -jump_power
	_did_jump = true


func can_jump() -> bool:
	return is_on_floor() or (not _did_jump and not coyote_timer.is_stopped())


func on_land() -> void:
	_is_airborne = false
	_did_jump = false
	_did_coyote = false
	_ended_jump_early = false


func should_coyote() -> bool:
	return not is_on_floor() and not _did_jump and not _did_coyote


func activate_coyote_time() -> void:
	coyote_timer.start()
	_did_coyote = true


func apply_friction(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)


func apply_acceleration(delta: float) -> void:
	var modifier := APEX_SPEED_BONUS if _is_at_jump_apex else 1.0
	velocity.x = move_toward(velocity.x, max_move_speed * modifier * sign(hinput), acceleration * delta)


func clear_jump_buffer() -> void:
	_is_jump_buffered = false
