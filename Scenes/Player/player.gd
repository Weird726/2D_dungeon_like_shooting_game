extends CharacterBody2D
class_name Player

## 玩家属性资源，包含移动速度、生命值等配置数据
@export var data: PlayerData

## 视觉容器父节点，翻转此节点可同时翻转 Shadow 和 AnimatedSprite2D
@onready var visuals: Node2D = $Visuals
## 角色脚下的阴影精灵，用于增强立体感
@onready var shadow: Sprite2D = $Visuals/Shadow
## 角色动画精灵，播放 idle/move 等动画
@onready var anim_sprite: AnimatedSprite2D = %AnimatedSprite2D

## 控制玩家是否可移动（被击晕、死亡等状态时设为 false）
var can_move: bool = true
## 当前帧的速度向量（方向 × 速度）
var movement: Vector2
## 当前输入方向（归一化向量，用于判断朝向）
var direction: Vector2

## 物理帧处理：读取输入 → 计算移动 → 播放动画 → 翻转朝向
func _physics_process(delta: float) -> void:
	if not can_move:
		return
	
	# 获取 WASD/方向键输入，返回归一化向量（长度 0~1）
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

## 根据输入方向翻转角色精灵，实现左右朝向
## 
## [b]难点说明[/b]：使用 scale.x 负值实现水平翻转，
## 而非修改 AnimatedSprite2D 的 flip_h，
## 因为需要同时翻转 Shadow 和角色精灵。
func rotate_player() -> void:
	if direction != Vector2.ZERO:
		if direction.x >= 0.1:
			# 向右：scale 为正（1.25 为放大倍数）
			visuals.scale = Vector2(1.25, 1.25)
		else:
			# 向左：scale.x 为负，实现水平镜像翻转
			visuals.scale = Vector2(-1.25, 1.25)
