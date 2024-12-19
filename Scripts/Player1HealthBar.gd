extends ProgressBar

func _ready():
	value = value

func _on_player_1_changed_health(newHealth) -> void:
	value = newHealth
