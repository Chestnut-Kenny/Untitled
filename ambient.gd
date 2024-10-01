extends Node3D

@onready var hit = $UI/ColorRect
@onready var spawns = $spawn
@onready var navigation_region = $NavigationRegion3D
@onready var tone_moaning: AudioStreamPlayer = $ToneMoaning
@onready var sound: Timer = $sound


var enemy = load("res://enemy.tscn")
var instance

func _ready() -> void:
	randomize()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_player_player_hit() -> void:
	hit.visible = true
	await get_tree().create_timer(0.2).timeout
	hit.visible= false


func _get_random_child(parent_node):
	var random_id = randi() % parent_node.get_child_count()
	return parent_node.get_child(random_id)

func _on_enemy_timer_timeout() -> void:
	var spawn_point = _get_random_child(spawns).global_position
	instance = enemy.instantiate()
	instance.position = spawn_point
	navigation_region.add_child(instance)


func _on_sound_timeout() -> void:
	tone_moaning.play()
	sound.start()
