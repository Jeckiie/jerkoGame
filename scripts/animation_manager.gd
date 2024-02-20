class_name AnimationManager


static func animate_character(animated_sprite: AnimatedSprite2D, velocity: Vector2) -> void:
	var total_vel = velocity.x + velocity.y
	var animation_number = get_animation_number(velocity.angle())
	if total_vel < -5 or total_vel > 5:
		animated_sprite.play("walk%s" % animation_number)
	else:
		animated_sprite.play("idle%s" % animation_number)

static func animate_attack(animated_sprite: AnimatedSprite2D, velocity: Vector2) -> void:
	var animation_number = get_animation_number(velocity.angle())
	animated_sprite.play("attack%s" % animation_number)

static func animate_idle(animated_sprite: AnimatedSprite2D, velocity: Vector2) -> void:
	var animation_number = get_animation_number(velocity.angle())
	animated_sprite.play("idle%s" % animation_number)

## Don't call anywhere else other than this method
static func get_animation_number(angle: float) -> int:
	var animation_number = 99
	var angle_degress_by_fortyfive = rad_to_deg(angle) / 45
	if angle_degress_by_fortyfive >= 0.5:
		if angle_degress_by_fortyfive >= 1.5:
			if angle_degress_by_fortyfive >= 2.5:
				if angle_degress_by_fortyfive >= 3.5:
					animation_number = 6
				else:
					animation_number = 7
			else:
				animation_number = 0
		else:
			animation_number = 1
	elif angle_degress_by_fortyfive <= -0.5:
		if angle_degress_by_fortyfive <= -1.5:
			if angle_degress_by_fortyfive <= -2.5:
				if angle_degress_by_fortyfive <= -3.5:
					animation_number = 6
				else:
					animation_number = 5
			else:
				animation_number = 4
		else:
			animation_number = 3
	else:
		animation_number = 2
	return animation_number
