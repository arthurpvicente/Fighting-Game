extends Area2D

@export var speed :int = 3000
@export var direction : int
var damage :int = 5
var move_x_direction : bool

func _physics_process(delta: float) -> void:
	if move_x_direction:
		move_local_x(direction * speed * delta)

func _on_timer_timeout() -> void:
	queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	print("Collision with: ", body.name)
	if body.is_in_group("Player"):  # Check if it's a player
		body.range_damage(get_damage())
	queue_free()

func get_damage() -> int:
	return damage
