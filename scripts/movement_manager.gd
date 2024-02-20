class_name MovementManager

static func get_seek_steering(navigation_agent_2d: NavigationAgent2D,
						character: CharacterBody2D, 
						speed: float,
						slow_down_area: float) -> Vector2:
	var desired_velocity: Vector2 = navigation_agent_2d.target_position - character.global_position
	var distance = desired_velocity.length()
	if distance < slow_down_area:
		desired_velocity = desired_velocity.normalized() * speed * (distance / slow_down_area)
	else:
		desired_velocity = desired_velocity.normalized() * speed
	return desired_velocity - character.velocity

static func get_flee_steering(ray_cast: RayCast2D,
							character: CharacterBody2D,
							speed: float,
							group: String) -> Vector2:
	var collider = ray_cast.get_collider()
	if collider != null and collider.is_in_group(group):
		var desired_velocity: Vector2 = character.global_position - collider.global_position 
		desired_velocity = desired_velocity.normalized() * speed
		return desired_velocity - character.velocity
	else:
		return Vector2.ZERO

static func get_collision_avoidance_steering(ray_cast: RayCast2D,
											character: CharacterBody2D,
											group: String,
											friend_detection_range: float,
											max_avoidance_force: float) -> Vector2:
	var collider = ray_cast.get_collider()
	if collider != null and collider.is_in_group(group):
		#var dynamic_length: float = velocity.length() / SPEED
		var ahead = character.global_position + character.velocity.normalized() * friend_detection_range #* dynamic_length
		var avoidance_force: Vector2 = ahead - collider.global_position
		avoidance_force = avoidance_force.normalized() * max_avoidance_force
		return avoidance_force
	else:
		return Vector2.ZERO
