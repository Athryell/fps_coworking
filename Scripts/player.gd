extends CharacterBody3D

@export var MAX_HEALTH = 5
var _health

const SPEED = 5.0
const JUMP_VELOCITY = 5.5
const SPRINT_MULTIPLIER = 2
const BASE_SPRINT_MULTIPLIER = 1
var mouse_sensitivity = 700
var sprint

#var movement_velocity: Vector3
var rotation_target: Vector3

var input_mouse: Vector2
var mouse_captured := true

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera = $Camera3D
@onready var anim_player = $AnimationPlayer
@onready var raycast = $Camera3D/RayCast3D
@onready var mesh = $MeshInstance3D

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())


func _ready():
	if not is_multiplayer_authority():
		return
	
	_health = MAX_HEALTH
	
	position = Vector3(randi_range(-26, 14), 0, randi_range(-2, 12))
	var new_mat := StandardMaterial3D.new()
	new_mat.albedo_color = Color(randf(), randf(), randf())
	mesh.set_material_override(new_mat)
	
	sprint = BASE_SPRINT_MULTIPLIER
	camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta):
	if not is_multiplayer_authority():
		return
	
	if Input.is_action_just_pressed("mouse_capture"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		mouse_captured = true
	
	if Input.is_action_just_pressed("mouse_capture_exit"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouse_captured = false
		
		input_mouse = Vector2.ZERO
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta


	if Input.is_action_pressed("sprint"):
		
		camera.fov +=2
		camera.fov = clamp(camera.fov,85,100)
		sprint = SPRINT_MULTIPLIER
	if  Input.is_action_just_released("sprint"):
		var tween = get_tree().create_tween()
		tween.tween_property(camera, "fov", 85, 0.5).set_trans(Tween.TRANS_SINE)
		#camera.fov = 85
		sprint = BASE_SPRINT_MULTIPLIER
	# Rotation
	
	camera.rotation.z = lerp_angle(camera.rotation.z, -input_mouse.x * 25 * delta, delta * 5)	
	
	camera.rotation.x = lerp_angle(camera.rotation.x, rotation_target.x, delta * 25)
	rotation.y = lerp_angle(rotation.y, rotation_target.y, delta * 25)
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED * sprint
		velocity.z = direction.z * SPEED * sprint
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	if anim_player.current_animation == "shoot":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor():
		anim_player.play("move")
	else:
		anim_player.play("idle")

	move_and_slide()


func _unhandled_input(event):
	if not is_multiplayer_authority():
		return
		
	if event is InputEventMouseMotion and mouse_captured:
		input_mouse = event.relative / mouse_sensitivity
		
		rotation_target.y -= event.relative.x / mouse_sensitivity
		rotation_target.x -= event.relative.y / mouse_sensitivity
	
	if Input.is_action_just_pressed("shoot") and anim_player.current_animation != "shoot":
		play_shoot_effects.rpc()
		if raycast.is_colliding():
			var hit_player = raycast.get_collider()
			hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority())


@rpc("call_local")
func play_shoot_effects():
	anim_player.stop()
	anim_player.play("shoot")


@rpc("any_peer")
func receive_damage():
	_health -= 1
	if _health <= 0:
		respawn()

func respawn():
	_health = MAX_HEALTH
	position = Vector3.ZERO


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		anim_player.play("idle")
		
