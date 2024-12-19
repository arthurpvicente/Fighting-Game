extends Area2D

#default fall speed
var fall_speed = 200 

#initialize velocity as a Vector2
var velocity = Vector2() 

#track whether the object is falling
var is_falling = false  

#time to wait before the next fall
var time_until_fall = 4  

func _ready():
	#ensure randomness each time the game runs
	randomize()  
	#set an initial random fall time
	reset_fall_timer()  

func reset_fall_timer():
	#random delay between 1 and 5 seconds
	time_until_fall = randf_range(1.0, 5.0)  

func _process(delta):
	if not is_falling:
		#decrease the timer
		time_until_fall -= delta  
		if time_until_fall <= 0:
			#trigger the fall
			is_falling = true  
	else:
		#handle falling logic
		_physics_process(delta)  

func _physics_process(delta):
	if is_falling:
		#update the vertical velocity
		velocity.y = fall_speed  
		#move the Area2D manually
		position += velocity * delta  
		#call a function to determine when to stop
		check_if_stopped()  

func check_if_stopped():
	if position.y >= 800:  
		#stop falling
		is_falling = false  
		#reset vertical velocity
		velocity.y = 0  
		#set a new random fall timer
		reset_fall_timer()  
		#Makes sure it doesn't continue falling
		fall_speed = 0
