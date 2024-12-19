extends ProgressBar

func _ready():
	value = value

func _on_player_2_changed_health(newHealth) -> void:
	value = newHealth
