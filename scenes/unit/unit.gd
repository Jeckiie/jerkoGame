extends CharacterBody2D

class_name Unit

@export_category("Movement")
@export var SPEED: float = 100.0
@export var MASS: int = 10
@export var SLOW_DOWN_AREA: float = 200.0
@export var MAX_AVOIDANCE_FORCE: float = 50.0
@export var FRIEND_DETECTION_RANGE: float = 40.0
@export_category("Battle")
@export var DETECTION_RANGE: float = 200.0
@export var RANGE: float = 40.0
@export var OPPOSITE_GROUP: String
@export var MAX_HEALTH: int = 4
@export var DAMAGE: int = 2
@export var ATTACK_SPEED: int = 3

@onready var navigation_agent_2d = $NavigationAgent2D
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var enemy_detect = $EnemyDetect
@onready var detect_ray_cast = $EnemyDetect/DetectRayCast
@onready var attack_detect = $AttackDetect
@onready var attack_ray_cast = $AttackDetect/AttackRayCast
@onready var friend_detect = $FriendDetect
@onready var friend_ray_cast = $FriendDetect/FriendRayCast
@onready var attack_timer = $AttackTimer
@onready var health_bar = $HealthBar

var _enemy_collider: CharacterBody2D # enemy that should be attacked
var _closest_enemy: Node
var _distance_to_closest_enemy: float = 9999.0
var _closest_friend: Node
var _distance_to_closest_friend: float = 9999.0
var _is_attacking: bool = false
var _target: Vector2

func _ready():
	attack_timer.wait_time = ATTACK_SPEED
	health_bar.set_max_health(MAX_HEALTH)
	detect_ray_cast.target_position = Vector2(0, DETECTION_RANGE)
	attack_ray_cast.target_position = Vector2(0, RANGE)
	friend_ray_cast.target_position = Vector2(0, FRIEND_DETECTION_RANGE)
	animated_sprite_2d.play("idle0")
	SignalManager.on_unit_hit.connect(on_unit_hit)

func _physics_process(_delta):
	raycast_to_enemy()
	raycast_to_friend()
	update_navigation()
	update_animation(_is_attacking)
	#print("velocityX: %.3f" % (velocity.x + velocity.y))

func setup_unit(spawn_location: Vector2, target_location: Vector2) -> void:
	global_position = spawn_location
	_target = target_location
	set_new_target(_target)

func update_navigation() -> void:
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
		move_and_slide()

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

func set_closest_enemy() -> void:
	# this if condition is just placeholder, fix this later. When enemy is killed, distance should
	# be reset to 9999.0
	if navigation_agent_2d.target_position == _target: 
		_distance_to_closest_enemy = 9999.0
	if _closest_enemy != null:
		if enemy_got_out_of_range():
			_closest_enemy = null
			_distance_to_closest_enemy = 9999.0
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
	_enemy_collider = attack_ray_cast.get_collider()
	if _enemy_collider != null and _enemy_collider.is_in_group(OPPOSITE_GROUP):
		AnimationManager.animate_attack(animated_sprite_2d, velocity)
		_is_attacking = true
		attack_timer.start()

func calculate_velocity() -> void:
	var steering: Vector2 = Vector2.ZERO
	var group: String = get_groups()[0]
	steering = steering + MovementManager.get_seek_steering(navigation_agent_2d, self, SPEED, SLOW_DOWN_AREA)
	#steering = steering + get_flee_steering()
	steering = steering + MovementManager.get_collision_avoidance_steering(friend_ray_cast, self,
						 				group, FRIEND_DETECTION_RANGE, MAX_AVOIDANCE_FORCE)
	steering = steering / MASS
	velocity = truncate(velocity + steering, SPEED)

func truncate(vector: Vector2, max_value: float) -> Vector2:
	var i = max_value / vector.length()
	i = min(i, 1.0)
	return vector * i

func update_animation(attacking: bool) -> void:
	#sprite_2d.rotation = velocity.angle()
	#if velocity.angle() == 0:
		#sprite_2d.look_at(navigation_agent_2d.target_position)
	if !attacking:
		AnimationManager.animate_character(animated_sprite_2d, velocity)

func take_damage(damage: float) -> void:
	var is_dead: bool = health_bar.reduce_health(damage)
	if is_dead:
		queue_free()

#signal from signal manager
func on_unit_hit(damage: int, character: CharacterBody2D) -> void:
	if character != null and self == character:
		take_damage(damage)

func _on_animated_sprite_2d_animation_finished():
	var current_animation: String = animated_sprite_2d.animation
	if current_animation.begins_with("attack"):
		AnimationManager.animate_idle(animated_sprite_2d, velocity)
		if _enemy_collider != null:
			SignalManager.on_unit_hit.emit(DAMAGE, _enemy_collider)
			if _enemy_collider.health_bar.value <= 0:
				attack_timer.stop()
				attack_timer.emit_signal("timeout")

func _on_attack_timer_timeout():
	_is_attacking = false
		#if _closest_enemy != null:
	#	_closest_enemy.queue_free()

#func get_collision_avoidance_steering() -> Vector2:
	#var collider = friend_ray_cast.get_collider()
	#if collider != null and collider.is_in_group(get_groups()[0]):
		##var dynamic_length: float = velocity.length() / SPEED
		#var ahead = global_position + velocity.normalized() * FRIEND_DETECTION_RANGE #* dynamic_length
		#var avoidance_force: Vector2 = ahead - collider.global_position
		#avoidance_force = avoidance_force.normalized() * MAX_AVOIDANCE_FORCE
		#return avoidance_force
	#else:
		#return Vector2.ZERO
#
#func get_seek_steering() -> Vector2:
	#var desired_velocity: Vector2 = navigation_agent_2d.target_position - global_position
	#var distance = desired_velocity.length()
	## TODO: AREA SLOW DOWN - EXPORT VARIABLE
	#if distance < 200:
		#desired_velocity = desired_velocity.normalized() * SPEED * (distance / 200)
	#else:
		#desired_velocity = desired_velocity.normalized() * SPEED
	#return desired_velocity - velocity

