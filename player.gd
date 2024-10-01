extends CharacterBody3D

var speed
const WALK_SPEED = 4.0
const SPRINT_SPEED = 6.0
const JUMP_VELOCITY = 4.5
const sensitivity = 0.003
const sensitivityThirdPerson = 0.4
const HIT_STAGGER = 8.0

const bob_freq = 2.0
const bob_amp = 0.08
var t_bob = 0.0

const base_fov = 75.0
const fov_change = 1.5

var wasInAir = false
var firstPerson = true
var running = false
var is_locked = false


var bullet = load("res://bullet.tscn")
var instance

signal playerHit

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var cameraMount = $cameraMount
@onready var thirdPerson = $cameraMount/Camera3D
@onready var steps1 = $footsteps/Dirty1
@onready var stepTimer = $footsteps/StepTimer
@onready var landSound = $footsteps/Dirty2
@onready var animationPlayer: AnimationPlayer = $visuals/regina/AnimationPlayer
@onready var visuals: Node3D = $visuals
@onready var jump_anim: AnimationPlayer = $Head/JumpAnim
@onready var gunAnim = $Head/Camera3D/FAMAS/AnimationPlayer
@onready var gunBarrel: RayCast3D = $Head/Camera3D/FAMAS/RayCast3D
@onready var shootSound: AudioStreamPlayer = $"JdSherbert-FirearmFx-WeaponSfxPack-WaltherP38-Fire-1"



func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if firstPerson:
		camera.make_current()
		thirdPerson.current = false
		if event is InputEventMouseMotion:
			# Rotación del cuerpo en primera persona
			rotate_y(-event.relative.x * sensitivity)
			head.rotate_x(-event.relative.y * sensitivity)
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-60), deg_to_rad(40))
	else:
		thirdPerson.make_current()
		camera.current = false
		if event is InputEventMouseMotion:
			# Rotación de la cámara en tercera persona
			rotate_y(deg_to_rad(-event.relative.x * sensitivityThirdPerson))
			cameraMount.rotate_x(deg_to_rad(-event.relative.y * sensitivityThirdPerson))
			cameraMount.rotation.x = clamp(cameraMount.rotation.x, deg_to_rad(-20), deg_to_rad(40))

func _physics_process(delta: float) -> void:
	if !animationPlayer.is_playing():
		is_locked = false


	# Añadir la gravedad.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Manejar el salto.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Manejar el sprint.
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
		running = true
	else:
		speed = WALK_SPEED
		running = false

	# Obtener la dirección de movimiento y normalizarla.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Mover al personaje y rotarlo hacia la dirección en la que se mueve.
	if is_on_floor():
		if direction.length() > 0:
			if !is_locked:
				if running:
					if animationPlayer.current_animation != "running":
						animationPlayer.play("running")
				else:
					if animationPlayer.current_animation != "walking":
						animationPlayer.play("walking")
				# Rotar el personaje para que mire hacia la dirección de movimiento.
				visuals.look_at(position + direction, Vector3.UP)

				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
		else:
			# Suavizar la velocidad cuando no hay entrada de movimiento.
			velocity.x = lerp(velocity.x, 0.0, delta * 10.0)  # Convertimos el 0 a float
			velocity.z = lerp(velocity.z, 0.0, delta * 10.0)  # Convertimos el 0 a float
	else:
		# Ajuste más lento del movimiento en el aire.
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 2.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 2.0)

	# Control de sonidos de pasos.
	if direction.length() > 0 and is_on_floor() and !is_locked:
		landSound.stop()
		if stepTimer.time_left <= 0:
			steps1.pitch_scale = randf_range(0.8, 1.2)
			steps1.play()
			if speed == SPRINT_SPEED:
				stepTimer.start(0.4)
			else:
				stepTimer.start(0.7)

	# Cambiar a animación de "idle" si no hay movimiento.
	if direction.length() == 0 and is_on_floor():
		if !is_locked:
			if animationPlayer.current_animation != "idle":
				animationPlayer.play("idle")

	# Reproducir sonido al aterrizar.
	if not is_on_floor():
		wasInAir = true
	else:
		if wasInAir:
			if direction.length() == 0:
				landSound.play()
				wasInAir = false

	# Alternar entre primera y tercera persona.
	if Input.is_action_just_pressed("toggle to first person or third person"):
		firstPerson = !firstPerson

	# Movimiento del personaje.
	move_and_slide()

	# Movimiento de la cámara (headbob) en primera persona.
	if firstPerson:
		t_bob += delta * velocity.length() * float(is_on_floor())
		camera.transform.origin = _headbob(t_bob)

	# Ajustar el FOV de la cámara según la velocidad.
	var velocity_clamped = clamp(velocity.length(), 8.5, SPRINT_SPEED * 2)
	var target_fov = base_fov + fov_change * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	if Input.is_action_just_pressed("shoot"):
		shootSound.play()
		if !gunAnim.is_playing():
			gunAnim.play("shoot")
			instance =  bullet.instantiate()
			instance.position = gunBarrel.global_position
			instance.transform.basis = gunBarrel.global_transform.basis
			get_parent().add_child(instance)

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bob_freq) * bob_amp
	pos.x = cos(time * bob_freq) * bob_amp
	return pos

func hit(dir):
	emit_signal("playerHit")
	velocity += dir * HIT_STAGGER
