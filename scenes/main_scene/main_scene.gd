extends Node2D

@onready var enemies = $Enemies
@onready var friendly_units = $FriendlyUnits
@onready var spawn_point = $SpawnPoint
@onready var target_point = $TargetPoint

var enemy_scene: PackedScene = preload("res://scenes/enemy/enemy.tscn")
var friend_unit_scene: PackedScene = preload("res://scenes/unit/friendly/friend_unit.tscn")

func _process(_delta):
	#if Input.is_action_just_pressed("load_enemy"):
		#load_enemy()
	if Input.is_action_just_pressed("load_friend"):
		load_friend()
	#if Input.is_action_just_pressed("load_enemy_at_mouse"):
		#load_enemy_at_mouse()

func load_friend() -> void:
	var rng = RandomNumberGenerator.new()
	var friend = friend_unit_scene.instantiate()
	friendly_units.add_child(friend)
	var spawn: Vector2 = Vector2(spawn_point.global_position.x + rng.randf_range(-100.0, 150.0),
		spawn_point.global_position.y)
	friend.setup_unit(spawn, target_point.global_position)

#func load_enemy() -> void:
	#var rng = RandomNumberGenerator.new()
	#var enemy = enemy_unit_scene.instantiate()
	#enemies.add_child(enemy)
	#var spawn: Vector2 = Vector2(target_point.global_position.x + rng.randf_range(-100.0, 150.0),
		#target_point.global_position.y)
	#enemy.setup_unit(spawn, spawn_point.global_position)

#func load_enemy_at_mouse() -> void:
	#var enemy = enemy_unit_scene.instantiate()
	#enemies.add_child(enemy)
	#enemy.setup_unit(get_global_mouse_position(), spawn_point.global_position)
