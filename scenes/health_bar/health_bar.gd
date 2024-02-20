extends TextureProgressBar

class_name HealthBar

var _current_health: int

func set_max_health(max_health: int):
	max_value = max_health
	value = max_health
	_current_health = max_health

func reduce_health(damage: int) -> bool:
	_current_health -= damage
	if _current_health <= 0:
		value = 0
		return true
	else:
		value = _current_health
		return false
