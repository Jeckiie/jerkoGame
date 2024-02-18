extends CharacterBody2D

@export var SPEED: float = 75

@onready var navigation_agent_2d = $NavigationAgent2D
@onready var sprite_2d = $Sprite2D

var _test_attack: bool = false

func _ready():
	var target = Vector2(randi() % 230 + 250, 1000)
	navigation_agent_2d.target_position = target
	sprite_2d.look_at(target)
	pass

func _physics_process(_delta):
	if _test_attack:
		return
	if navigation_agent_2d.is_navigation_finished() == false:
		var next_path_position: Vector2 = navigation_agent_2d.get_next_path_position()
		sprite_2d.look_at(next_path_position)
		velocity = global_position.direction_to(next_path_position) * SPEED
		move_and_slide()
		#var direction: Vector2 = to_local(next_path_position).normalized()
		#var intended_velocity = direction * SPEED
		#navigation_agent_2d.set_velocity(intended_velocity)
		


func _on_navigation_agent_2d_velocity_computed(_safe_velocity):
	#velocity = safe_velocity
	#move_and_slide()
	pass


func _on_area_2d_area_entered(area: Area2D):
	if area.get_parent().is_in_group("unit"):
		_test_attack = true
		velocity = Vector2.ZERO


func _on_area_2d_body_entered(body):
	if body.is_in_group("unit"):
		_test_attack = true
		velocity = Vector2.ZERO
