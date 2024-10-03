extends CharacterBody3D


var player = null
const SPEED = 4.0
const ATTACKRANGE = 2.5
var state_machine
var health = 6


# path ps1 Style -> @export var player_path := "/root/ps1_postprocessing/SubViewport/ambient/NavigationRegion3D/Player"

# path vhs Sytle -> @export var player_path := "/root/vhs/CanvasLayer/ColorRect/ambient/NavigationRegion3D/Player"


#path vhs and ps1 style combined ->
@export var player_path := "/root/vhsAndPs1/SubViewportContainer/SubViewport/CanvasLayer/ColorRect/ambient/NavigationRegion3D/Player"
@onready var nav_agent = $NavigationAgent3D
@onready var animTree = $AnimationTree
@onready var zombieSound: AudioStreamPlayer3D = $Zombie8
@onready var timer: Timer = $Timer
@onready var blood: CPUParticles3D = $CPUParticles3D
@onready var armature: Node3D = $enemy/Armature



func _ready() -> void:
	player = get_node(player_path)
	state_machine = animTree.get("parameters/playback")


func _process(delta: float) -> void:
	velocity = Vector3.ZERO
	match state_machine.get_current_node():
		"run":
			nav_agent.set_target_position(player.global_transform.origin)
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point - global_transform.origin).normalized() * SPEED
			look_at(Vector3(global_position.x + velocity.x, global_position.y, global_position.z + velocity.z), Vector3.UP)
			rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10.0)
		"kick":
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	
	
	animTree.set("parameters/conditions/kick", _target_in_range())
	animTree.set("parameters/conditions/run", !_target_in_range())
	
	move_and_slide()


func _target_in_range():
	return global_position.distance_to(player.global_position) < ATTACKRANGE


func _hit_finished():
	if global_position.distance_to(player.global_position) < ATTACKRANGE + 1.0:
		var dir = global_position.direction_to(player.global_position)
		player.hit(dir)


func _on_timer_timeout() -> void:
	zombieSound.play()
	timer.start()


func _on_area_3d_body_part_hit(dam: Variant) -> void:
	health -= dam
	if health <= 0:
		armature.visible = false
		blood.emitting = true
		await get_tree().create_timer(1.0).timeout
		queue_free()
