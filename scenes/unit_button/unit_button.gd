extends TextureButton

var unit_scene: PackedScene = preload("res://scenes/unit/unit.tscn")
var spawn_point: PackedScene = preload("res://scenes/spawn_point/spawn_point.tscn")
var target_point: PackedScene = preload("res://scenes/target_point/target_point.tscn")

@onready var disabled_button_timer = $DisabledButtonTimer

var _units_group: String = "friendlyUnits"
var _spawn: Node
var _target: Node

func _ready() -> void:
	_spawn = spawn_point.instantiate()
	_target = target_point.instantiate()


func _on_button_down():
	instantiate_unit_and_set_navigation()
	self_modulate = Color(0, 0.8, 0.8, 1)
	disabled = true
	disabled_button_timer.start()
	

func instantiate_unit_and_set_navigation() -> void:
	var new_unit: Unit = unit_scene.instantiate()
	get_tree().get_first_node_in_group(_units_group).add_child(new_unit)
	new_unit.global_position = _spawn.global_position
	new_unit.start_navigation(_target.position)

func _on_disabled_button_timer_timeout():
	disabled = false
	self_modulate = Color(1, 1, 1, 1)
