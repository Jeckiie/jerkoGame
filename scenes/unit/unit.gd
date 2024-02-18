extends CharacterBody2D

class_name Unit

@export_category("Movement")
@export var SPEED: float = 100
@export var MASS: int = 10
@export var FRIEND_DETECTION_RANGE: float = 40.0
@export_category("Battle")
@export var DETECTION_RANGE: float = 200.0
@export var RANGE: float = 40.0

const OPPOSITE_GROUP: String = "enemy"

@onready var navigation_agent_2d = $NavigationAgent2D
@onready var enemy_detect = $EnemyDetect
@onready var detect_ray_cast = $EnemyDetect/DetectRayCast
@onready var sprite_2d = $Sprite2D
@onready var attack_detect = $AttackDetect
@onready var attack_ray_cast = $AttackDetect/AttackRayCast
@onready var friend_detect = $FriendDetect
@onready var friend_ray_cast = $FriendDetect/FriendRayCast
@onready var test_attack_timer = $TestAttackTimer

var _closest_enemy: Node
var _distance_to_closest_enemy: float = 9999.0
var _closest_friend: Node
var _distance_to_closest_friend: float = 9999.0
var _is_attacking: bool = false
var _target: Vector2

func _ready():
	var rng = RandomNumberGenerator.new()
	test_attack_timer.wait_time = rng.randi_range(1, 3)
	detect_ray_cast.target_position = Vector2(0, DETECTION_RANGE)
	attack_ray_cast.target_position = Vector2(0, RANGE)
	friend_ray_cast.target_position = Vector2(0, FRIEND_DETECTION_RANGE)

func _physics_process(_delta):
	raycast_to_enemy()
	raycast_to_friend()
	update_navigation()

func setup_unit(spawn_location: Vector2, target_location: Vector2) -> void:
	global_position = spawn_location
	_target = target_location
	set_new_target(_target)

func update_navigation() -> void:
	#if navigation_agent_2d.is_navigation_finished() == false:
		#var mouse = get_global_mouse_position()
		#navigation_agent_2d.target_position = mouse
		#sprite_2d.look_at(mouse)
		#
		##velocity = global_position.direction_to(navigation_agent_2d.target_position) * SPEED
		#move_and_slide()
		
		
	if _is_attacking:
		return
	attack_if_enemy_in_range()
	var collider = detect_ray_cast.get_collider()
	if collider != null and collider.is_in_group(OPPOSITE_GROUP):
		if _closest_enemy != null:
			set_new_target(_closest_enemy.global_position)
	else:
		set_new_target(_target)
	if navigation_agent_2d.is_navigation_finished() == false:
		calculate_velocity()
#		velocity = global_position.direction_to(navigation_agent_2d.target_position) * SPEED
		move_and_slide()

func truncate(vector: Vector2, max_value: float) -> Vector2:
	var i = max_value / vector.length()
	i = min(i, 1.0)
	return vector * i

func raycast_to_enemy() -> void:
	set_closest_enemy()
	if _closest_enemy != null:
		enemy_detect.look_at(_closest_enemy.global_position)
		attack_detect.look_at(_closest_enemy.global_position)
	else:
		enemy_detect.look_at(_target)
		attack_detect.look_at(_target)

func raycast_to_friend() -> void:
	set_closest_friend()
	if _closest_friend != null:
		friend_detect.look_at(_closest_friend.global_position)
	else:
		friend_detect.look_at(Vector2.ZERO)

func set_new_target(new_target: Vector2) -> void:
	navigation_agent_2d.target_position = new_target
	#sprite_2d.look_at(navigation_agent_2d.target_position)

func set_closest_enemy() -> void:
	if _closest_enemy != null:
		if enemy_got_out_of_range():
			_closest_enemy = null
			_distance_to_closest_enemy = 9999.0
		else:
			return
	var enemies = get_tree().get_nodes_in_group(OPPOSITE_GROUP)
	for enemy in enemies:
		var distance_to_enemy = global_position.distance_to(enemy.global_position)
		if (distance_to_enemy < _distance_to_closest_enemy):
			_distance_to_closest_enemy = distance_to_enemy
			_closest_enemy = enemy

func set_closest_friend() -> void:
	if _closest_friend != null:
		if friend_got_out_of_range():
			_closest_friend = null
			_distance_to_closest_friend = 9999.0
		else:
			return
	var friends = get_tree().get_nodes_in_group(get_groups()[0])
	friends.erase(self)
	for friend in friends:
		var distance_to_friend = global_position.distance_to(friend.global_position)
		if (distance_to_friend < _distance_to_closest_friend):
			_distance_to_closest_friend = distance_to_friend
			_closest_friend = friend

func enemy_got_out_of_range() -> bool:
	var distance_to_enemy = global_position.distance_to(_closest_enemy.global_position)
	if distance_to_enemy > DETECTION_RANGE:
		return true
	return false

func friend_got_out_of_range() -> bool:
	var distance_to_friend = global_position.distance_to(_closest_friend.global_position)
	if distance_to_friend > FRIEND_DETECTION_RANGE:
		return true
	return false

func attack_if_enemy_in_range() -> void:
	var collider = attack_ray_cast.get_collider()
	if collider != null and collider.is_in_group(OPPOSITE_GROUP):
		_is_attacking = true
		velocity = Vector2.ZERO
		test_attack_timer.start()

func calculate_velocity() -> void:
	var steering: Vector2 = Vector2.ZERO
	steering = steering + get_seek_steering()
	#steering = steering + get_flee_steering()
	steering = steering + get_collision_avoidance_steering()
	steering = steering / MASS
	rotate_sprite()
	velocity = truncate(velocity + steering, SPEED)

func get_collision_avoidance_steering() -> Vector2:
	var collider = friend_ray_cast.get_collider()
	if collider != null and collider.is_in_group(get_groups()[0]):
		#var dynamic_length: float = velocity.length() / SPEED
		var ahead = global_position + velocity.normalized() * FRIEND_DETECTION_RANGE #* dynamic_length
		var avoidance_force: Vector2 = ahead - collider.global_position
		# TODO: MAX AVOIDANCE FORCE - EXPORT VARIABLE
		avoidance_force = avoidance_force.normalized() * 50
		return avoidance_force
	else:
		return Vector2.ZERO


#func get_flee_steering() -> Vector2:
	#var collider = friend_ray_cast.get_collider()
	#if collider != null and collider.is_in_group(get_groups()[0]):
		#var desired_velocity: Vector2 = global_position - collider.global_position 
		#desired_velocity = desired_velocity.normalized() * SPEED
		#return desired_velocity - velocity
	#else:
		#return Vector2.ZERO

func get_seek_steering() -> Vector2:
	var desired_velocity: Vector2 = navigation_agent_2d.target_position - global_position
	var distance = desired_velocity.length()
	# TODO: AREA SLOW DOWN - EXPORT VARIABLE
	if distance < 200:
		desired_velocity = desired_velocity.normalized() * SPEED * (distance / 200)
	else:
		desired_velocity = desired_velocity.normalized() * SPEED
	return desired_velocity - velocity

func rotate_sprite() -> void:
	sprite_2d.rotation = velocity.angle()
	if velocity.angle() == 0:
		sprite_2d.look_at(navigation_agent_2d.target_position)

func _on_test_attack_timer_timeout():
	#_is_attacking = false
	#if _closest_enemy != null:
		#_closest_enemy.queue_free()
	pass

