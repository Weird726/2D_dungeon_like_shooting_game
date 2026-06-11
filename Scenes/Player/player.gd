extends CharacterBody2D
class_name Player

@export var data: PlayerData

@onready var visuals: Node2D = $Visuals
@onready var shadow: Sprite2D = $Visuals/Shadow
@onready var anim_sprite: AnimatedSprite2D = %AnimatedSprite2D

var can_move := true
var movement: Vector2
var direction: Vector2

func _physics_process(delta: float) -> void:
	if not can_move:
		return
	
	direction = Input.get_vector("move_left","move_right","move_up","move_down")
	if direction != Vector2.ZERO:
		movement = direction * data.move_speed
		anim_sprite.play("move")
	else:
		movement = Vector2.ZERO
		anim_sprite.play("idle")
	
	velocity = movement
	move_and_slide()
	rotate_player()

func rotate_player() -> void:
	if direction != Vector2.ZERO:
		if direction.x >= 0.1:
			visuals.scale = Vector2(1.25, 1.25)
		else:
			visuals.scale = Vector2(-1.25, 1.25)
