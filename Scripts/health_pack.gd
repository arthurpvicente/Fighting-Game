extends Area2D
var isHealthPackOn = true



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_player_2_update_healthpack() -> void:
	hide()
	


func _on_player_1_update_healthpack() -> void:
	hide()
	


func _on_health_pack_interval_timeout() -> void:
	show()
