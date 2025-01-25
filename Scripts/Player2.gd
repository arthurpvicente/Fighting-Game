extends CharacterBody2D

# Signals used for interactions between health, health packs, and other players
signal changed_health
signal update_healthpack
signal update_OtherPlayer

# References to weapon nodes and sprites
@onready var melee_weapon1 = get_node("../Player1/MeleeWeapon1")
@onready var ranged_weapon1 = get_node("../Player1/RangedWeapon1")

@onready var melee_weapon2 = get_node("MeleeWeapon2")
@onready var melee_weapon_sprite2 = get_node("MeleeWeapon2/Sprite2D")

@onready var ranged_weapon2 = get_node("RangedWeapon2")

@onready var RedRifle = get_node("../RedRifle")
@onready var RedSaber = get_node("../RedSaber")

# Preloaded bullet scene for ranged attack
@onready var bullet2 :PackedScene = preload("res://Scenes/bullet2.tscn"	)

# Node references for UI and effects
@onready var Player1WinLogo = get_node("../Player1WinLogo")
@onready var Player2WinLogo = get_node("../Player2WinLogo")
@onready var sprites: AnimatedSprite2D = $Sprites
@onready var muzzle = get_node("Muzzle")

#Sounds effect
@onready var sfx_jump = $"../sfx_jump"  # testing jump effect
@onready var sfx_healing = $"../sfx_healing"
@onready var sfx_laserhit = $"../sfx_laserhit"
@onready var sfx_punch = $"../sfx_punch"
@onready var sfx_saber = $"../sfx_saber"

# Switch certain states cooldown
@onready var timer : Timer = $Timer2

# Physics and movement-related constants
const gravity = 1000
@export var speed : int = 1000
@export var max_horizontal_speed : int = 350
@export var slow_down_speed : int = 10000

@export var jump : int = -700
@export var jump_horizontal_speed : int = 1500
@export var max_jump_horizontal_speed : int = 350

# Health management variables
@export var isHealthPackOn = true
@export var maxHealth = 100
@export var currentHealth = 100
var test_value = 0

# Damage values for different attacks
var dmg1 = 5
var dmg2 = 10

# State-related variables
@export var gettingMeleeHit = false
@export var gettingRangeHit = false

# State machine definition
enum State {
	Idle, Walk, Jump, Crouch, Punch, Punch_Jump, Punch_Walk,
	Gun_Jump, Gun_Shoot, Gun_Shoot_Jump, Gun_Walk, Gun_Walk_Shoot,
	Sword_Attack, Sword_Jump, Sword_Walk, Idle_Gun, Idle_Sword, Sword_Attack_Walk, Sword_Attack_Jump
	}

var current_state : State # Tracks the player's current state
var muzzle_pos # Stores the initial position of the muzzle

# Initialize variables on ready
func _ready() -> void:
	current_state = State.Idle
	muzzle_pos = muzzle.position
	timer.stop() # Make sure timer doesn't start

# Physics processing: manages movement, state changes, and collisions
func _physics_process(delta: float) -> void:
	deadCheck()
	
	player_falling(delta)
	player_idle(delta)
	player_walk(delta)
	player_jump(delta)
	player_crouch(delta)
	
	move_and_slide() # Applies velocity for character movement
	
	player_animations()
	
	melee_attack(delta)
	player_muzzle_pos()
	range_attack(delta)
	
	gettingMeleeDamaged()
	
	#print("State: ", State.keys()[current_state])

# Adds gravity when player is in the air
func player_falling(delta):
	if !is_on_floor():
		velocity.y += gravity * delta

# Handles idle state logic based on movement and floor conditions
func player_idle(delta): # The Print function in here if active will flood the output, making debugging hard
	if velocity.x == 0 and is_on_floor() and current_state != State.Crouch and current_state != State.Gun_Shoot and current_state != State.Sword_Attack and current_state != State.Punch:
		current_state = State.Idle
		#print("101, Idle")
		if ranged_weapon2.visible:
			current_state = State.Idle_Gun
			#print("105, Idle_Gun")
		elif melee_weapon2.visible:
			current_state = State.Idle_Sword
			#print("108, Idle_Sword")

# Handles walking movement and state updates
func player_walk(delta):
	if !is_on_floor():
		return
	
	var direction = input_movement()
	
	if direction: # Makes movements smoother
		velocity.x += direction * speed * delta
		velocity.x = clamp(velocity.x, -max_horizontal_speed, max_horizontal_speed)
	else:
		velocity.x = move_toward(velocity.x, 0, slow_down_speed * delta)
	
	if direction != 0:
		if !melee_weapon2.visible and !ranged_weapon2.visible and current_state != State.Punch_Walk:
			current_state = State.Walk
			print("125, Walk")
		if melee_weapon2.visible and current_state != State.Sword_Attack_Walk:
			current_state = State.Sword_Walk
			print("128, Sword_Walk")
		if ranged_weapon2.visible and current_state != State.Gun_Walk_Shoot:
			current_state = State.Gun_Walk
			print("131, Gun_Walk")
		
		# Adjusts sprite orientation based on direction
		var tween = create_tween()
		if direction > 0:
			sprites.flip_h = false
			melee_weapon_sprite2.flip_h = false
			tween.tween_property(melee_weapon2, "position", Vector2(50, -10), 0)
		else:
			sprites.flip_h = true
			melee_weapon_sprite2.flip_h = true
			tween.tween_property(melee_weapon2, "position", Vector2(-50, -10), 0)
	

# Handles crouch state logic
func player_crouch(delta: float):
	if Input.is_action_just_pressed("Crouch2"):
		if !is_on_floor():
			velocity.y += gravity * delta * 35 # Change how much faster character is falling
			current_state = State.Crouch
			print("151, Crouch")
		else: 
			current_state = State.Crouch
	elif Input.is_action_just_released("Crouch2"): # Switches state from crouch to idle upon release of button
		if is_on_floor() and current_state != State.Gun_Shoot and current_state != State.Sword_Attack:
			current_state = State.Idle
			print("157, Crouch -> Idle")

# Handles jumping logic and horizontal movement during jumps
func player_jump(delta):
	var direction = input_movement()
	
	if is_on_floor() and Input.is_action_just_pressed("Jump2"):
		velocity.y = jump
		sfx_jump.play() #Play the jump sound
		if !melee_weapon2.visible and !ranged_weapon2.visible:
			current_state = State.Jump
			print("168, Jump")
		if melee_weapon2.visible:
			current_state = State.Sword_Jump
			print("171, Sword_Jump")
		if ranged_weapon2.visible:
			current_state = State.Gun_Jump
			print("173, Gun_Jump")
	
	if !is_on_floor() and (current_state == State.Jump or current_state == State.Sword_Jump or current_state == State.Gun_Jump):
		velocity.x += direction * jump_horizontal_speed * delta
		velocity.x = clamp(velocity.x, -max_jump_horizontal_speed, max_jump_horizontal_speed)
	
	if velocity.x != 0 and !is_on_floor(): # On air + moving
		if !melee_weapon2.visible and !ranged_weapon2.visible:
			if current_state != State.Punch_Jump: # Jump doesn't override punch_jump
				current_state = State.Jump
				print("183, Jump")
			if velocity.x != 0 and Input.is_action_just_pressed("Damage2"): # Attack in air
				current_state = State.Punch_Jump
				timer.start(0.15) # Cooldown for switching states
				print("187, Punch_Jump -> Jump while moving")
		if melee_weapon2.visible:
			if current_state != State.Sword_Attack_Jump:
				current_state = State.Sword_Jump
				print("186, Sword_Jump")
			if velocity.x != 0 and Input.is_action_just_pressed("Damage2"): # Attack in air
				current_state = State.Sword_Attack_Jump
				timer.start(0.3) # Cooldown for switching states
				print("190, Sword_Attack_Jump -> Sword_Jump while moving")
		if ranged_weapon2.visible:
			if current_state != State.Gun_Shoot_Jump:
				current_state = State.Gun_Jump
				print("194, Gun_Jump")
			if velocity.x != 0 and Input.is_action_just_pressed("Damage2"): # Attack in air
				current_state = State.Gun_Shoot_Jump
				timer.start(0.3) # Cooldown for switching states
				print("198, Gun_Shoot_Jump -> Gun_Jump while moving")
		
		var tween = create_tween()
		if velocity.x > 0:
			sprites.flip_h = false
			melee_weapon_sprite2.flip_h = false
			tween.tween_property(melee_weapon2, "position", Vector2(50, -10), 0)
		else:
			sprites.flip_h = true
			melee_weapon_sprite2.flip_h = true
			tween.tween_property(melee_weapon2, "position", Vector2(-50, -10), 0)

# Handles animation updates based on the player's state
func player_animations():
	if current_state == State.Idle:
		sprites.play("Idle")
	elif current_state == State.Walk:
		sprites.play("Walk")
	elif current_state == State.Jump:
			sprites.play("Jump")
	elif current_state == State.Crouch:
		sprites.play("Crouch")
	elif current_state == State.Punch:
		sprites.play("Punch")
	elif current_state == State.Punch_Walk:
		sprites.play("Punch_Walk")
	elif current_state == State.Punch_Jump:
		sprites.play("Punch_Jump")
	elif current_state == State.Gun_Jump:
		sprites.play("Gun_Jump")
	elif current_state == State.Gun_Shoot:
		sprites.play("Gun_Shoot")
	elif current_state == State.Gun_Shoot_Jump:
		sprites.play("Gun_Shoot_Jump")
	elif current_state == State.Gun_Walk:
		sprites.play("Gun_Walk")
	elif current_state == State.Gun_Walk_Shoot:
		sprites.play("Gun_Walk_Shoot")
	elif current_state == State.Idle_Gun: 
		sprites.play("Idle_Gun")
	elif current_state == State.Sword_Attack:
		sprites.play("Sword_Attack")
	elif current_state == State.Sword_Jump:
		sprites.play("Sword_Jump")
	elif current_state == State.Sword_Walk:
		sprites.play("Sword_Walk")
	elif current_state == State.Idle_Sword:
		sprites.play("Idle_Sword")
	elif current_state == State.Sword_Attack_Walk:
		sprites.play("Sword_Attack_Walk")
	elif current_state == State.Sword_Attack_Jump:
		sprites.play("Sword_Attack_Jump")

# Manages melee attack actions and states
func melee_attack(delta : float):
	if Input.is_action_just_pressed("Damage2") and melee_weapon2.visible:
		if !is_on_floor() and velocity.x == 0:
			current_state = State.Sword_Attack_Jump
			timer.start(0.1) # Cooldown for switching states
			print("251, Sword_Attack_Jump -> Sword_Jump")
		elif is_on_floor():
			if velocity.x == 0:
				current_state = State.Sword_Attack
				timer.start(0.1) # Cooldown for switching states
				print("256, Sword_Attack -> Idle_Sword")
				sfx_saber.play()
			else:
				current_state = State.Sword_Attack_Walk
				timer.start(0.1) # Cooldown for switching states
				print("260, Sword_Attack_Walk -> Sword_Walk")
	
	if Input.is_action_just_pressed("Damage2") and !melee_weapon2.visible and !ranged_weapon2.visible:
		if !is_on_floor() and velocity.x == 0:
			current_state = State.Punch_Jump
			timer.start(0.15) # Cooldown for switching states
			print("269, Punch_Jump -> Jump while not moving")
		elif is_on_floor():
			if velocity.x == 0:
				current_state = State.Punch
				timer.start(0.1) # Cooldown for switching states
				print("274, Punch -> Idle")
				sfx_punch.play() # Play the sword sound
			else:
				current_state = State.Punch_Walk
				timer.start(0.1) # Cooldown for switching states
				print("279, Punch_Walk -> Walk")

# Handles input for movement (left or right)
func input_movement():
	var direction : float = Input.get_axis("Move_Left2", "Move_Right2")
	
	return direction

# Handles ranged attack actions by spawning bullets and ranged attack states
func range_attack(delta : float):
	var direction : float = -1 if sprites.flip_h else 1
	
	if Input.is_action_just_pressed("Damage2") and ranged_weapon2.visible:
		var bullet_temp = bullet2.instantiate() as Node2D
		get_parent().add_child(bullet_temp)
		bullet_temp.direction = direction
		bullet_temp.move_x_direction = true
		bullet_temp.global_position = muzzle.global_position
		
		# Play the laser sound when the ranged attack occurs
		sfx_laserhit.play()  # Play the laser sound effect
		
		if !is_on_floor() and velocity.x == 0:
			current_state = State.Gun_Shoot_Jump
			timer.start(0.3) # Cooldown for switching states
			print("294, Gun_Shoot_Jump -> Gun_Jump while not moving")
		elif is_on_floor():
			if velocity.x == 0:
				current_state = State.Gun_Shoot
				timer.start(0.6) # Cooldown for switching states
				print("299, Gun_Shoot -> Gun_Idle")
			else:
				current_state = State.Gun_Walk_Shoot
				timer.start(0.3) # Cooldown for switching states
				print("303, Gun_W_S -> Gun_Walk")

# Range atk dmg logic + HP UI change
func range_damage(amount : int) -> void:
	currentHealth -= amount
	changed_health.emit(currentHealth)

# Adjusts the muzzle position to maintain consistency with sprite orientation
func player_muzzle_pos():
	var direction = input_movement()
	
	if direction > 0:
		muzzle.position.x = muzzle_pos.x
	if direction < 0:
		muzzle.position.x = -muzzle_pos.x

func gettingMeleeDamaged():
	if Input.is_action_just_pressed("Damage") and gettingMeleeHit and !melee_weapon1.visible:	
		print("fist")
		currentHealth = currentHealth - dmg1
		changed_health.emit(currentHealth)
	if Input.is_action_just_pressed("Damage") and gettingMeleeHit and melee_weapon1.visible:
		print("sword")
		currentHealth = currentHealth - dmg2
		changed_health.emit(currentHealth)

func _on_melee_weapon_1_body_entered(body: Node2D) -> void:
	gettingMeleeHit = true
	print(gettingMeleeHit)

func _on_melee_weapon_1_body_exited(body: Node2D) -> void:
	gettingMeleeHit = false
	print(gettingMeleeHit)

func _on_health_pack_body_entered(body: Node2D) -> void:
	if body.name == "Player2" and isHealthPackOn:
		currentHealth = currentHealth + 10
		sfx_healing.play() # Play the sound after healing
		if currentHealth > maxHealth:
			currentHealth = 100
		changed_health.emit(currentHealth)
		#update when pack spawning is implimented
		isHealthPackOn = false
		update_healthpack.emit()
		update_OtherPlayer.emit(isHealthPackOn)

func deadCheck(): # Shows win screen
	if currentHealth <= 0 and !Player2WinLogo.visible: #Makes sure whoever dies first loses (doesn't display both win screen)
		Player1WinLogo.show()
		queue_free()

func _on_player_1_update_other_player(newIsHealthPackOn) -> void:
	isHealthPackOn = newIsHealthPackOn

func _on_health_pack_interval_timeout() -> void:
	isHealthPackOn = true

# Timer logic for what happens when the timer/cooldown is done
func _on_timer_2_timeout():
	if is_on_floor() and current_state == State.Punch:
		current_state = State.Idle
		print("timeout Idle")
	elif !is_on_floor() and current_state == State.Punch_Jump:
		current_state = State.Jump
		print("timeout Idle")
	elif is_on_floor() and current_state == State.Punch_Walk:
		current_state = State.Walk
		print("timeout Idle")
	elif is_on_floor() and current_state == State.Gun_Shoot:
		current_state = State.Idle_Gun
		print("timeout Idle_Gun")
	elif is_on_floor() and current_state == State.Gun_Walk_Shoot:
		current_state = State.Gun_Walk
		print("timeout Gun_Walk")
	elif !is_on_floor() and current_state == State.Gun_Shoot_Jump:
		current_state = State.Gun_Jump
		print("timeout Gun_Jump")
	elif is_on_floor() and current_state == State.Sword_Attack:
		current_state = State.Idle_Sword
		print("timeout Idle_Sword")
	elif !is_on_floor() and current_state == State.Sword_Attack_Jump:
		current_state = State.Sword_Jump
		print("timeout Sword_Jump")
	elif is_on_floor() and current_state == State.Sword_Attack_Walk:
		current_state = State.Sword_Walk
		print("timeout Sword_Walk")

# "Picks up" Gun
func _on_red_rifle_body_entered(body: Node2D) -> void:
	ranged_weapon2.show()
	RedRifle.queue_free()
	RedSaber.queue_free()

# "Picks up" Sword
func _on_red_saber_body_entered(body: Node2D) -> void:
	melee_weapon2.show()
	RedSaber.queue_free()
	RedRifle.queue_free()
