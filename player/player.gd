class_name Player
extends CharacterBody2D

const MAX_SPEED = 130
const ACCEL = 1125

var speed_mul := 1.
@onready var aim_hint: Node2D = %AimHint

var _weapon_node: Node
@onready var current_weapon := "Basic":
	set(v):
		current_weapon = v
		if (not is_node_ready()): return

		if _weapon_node != null and _weapon_node.has_method("unequipped"):
			_weapon_node.unequipped()

		_weapon_node = %Weapons.get_node_or_null(v)
		_weapon_node.equipped()

func _ready() -> void:
	_weapon_node = %Weapons.get_node_or_null(current_weapon)
	_weapon_node.equipped.call_deferred()

func _process(delta: float) -> void:
	var aim = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	aim = aim.normalized()

	aim_hint.visible = not aim.is_zero_approx() and current_weapon == "Hyperbeam"
	aim_hint.global_rotation = aim.angle()

	if _weapon_node == null: return
	if aim.is_zero_approx():
		_weapon_node.fire_released(delta)
	else:
		_weapon_node.fire_pressed(delta, get_parent(), aim)

func _physics_process(delta: float) -> void:
	var input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var desired_velocity = input * MAX_SPEED * speed_mul

	velocity = velocity.move_toward(
		desired_velocity, 
		ACCEL * delta
	)

	move_and_slide()

	var dir := Vector2.RIGHT.rotated(rotation)
	var v := dir.slerp(input.normalized(), .5)
	rotation = v.angle()

func _on_hurt_box_body_entered(body: Node2D) -> void:
	World.get_instance(self).main_cam.shake(.4, 2)
	body.queue_free()

	Game.instance.health = move_toward(Game.instance.health, 0, 3)

	if Game.instance.health <= 0:
		var img := get_tree().current_scene.get_viewport().get_texture().get_image()
		DeathScreen.screenshot = ImageTexture.create_from_image(img)
		get_tree().change_scene_to_file("res://uis/death_screen.tscn")

