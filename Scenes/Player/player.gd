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
## 生命值组件，处理受伤/治疗/死亡逻辑
@onready var health_component: HealthComponent = $HealthComponent
## 武器控制器，存储 target_pos 供 WeaponRange 自行读取并旋转
@onready var weapon_controller: WeaponController = $WeaponController

## 控制玩家是否可移动（被击晕、死亡等状态时设为 false）
var can_move: bool = true
## 当前帧的速度向量（方向 × 速度）
var movement: Vector2
## 当前输入方向（归一化向量，用于判断朝向）
var direction: Vector2
## 射击冷却倒计时（秒），每次射击后重置为武器数据中的 cooldown 值
var cooldown: float

## 初始化角色属性，从 PlayerData 资源读取配置
func _ready() -> void:
	health_component.init_health(data.max_hp)

## 每帧处理：设置瞄准目标 → 武器自旋转 → 射击冷却判断
##
## [b]难点说明[/b]：旋转职责下放
## Player 仅设置 weapon_controller.target_pos = 鼠标位置
## WeaponRange._process() 自行读取 target_pos 并执行旋转+翻转
## 不再调用 weapon_controller.rotate_weapon()（该方法已移除）
##
## [b]难点说明[/b]：射击冷却机制
## cooldown 每帧递减，归零时允许射击
## 射击后立即重置为武器数据中的 cooldown 值（控制射速）
## 使用 is_action_pressed 支持长按连射（冷却结束自动发射下一发）
func _process(delta: float) -> void:
	# 将鼠标全局位置设为武器瞄准目标（WeaponRange 每帧自行读取此值并旋转）
	weapon_controller.target_pos = get_global_mouse_position()
	
	# 冷却倒计时递减
	cooldown -= delta
	if Input.is_action_pressed("shoot"):
		if cooldown <= 0:
			# 调用当前武器的攻击方法（生成子弹/挥砍等）
			weapon_controller.current_weapon.use_weapon()
			# 重置冷却为武器数据中设定的射击间隔
			cooldown = weapon_controller.current_weapon.data.cooldown

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

## 受伤信号回调，将生命值变化广播到事件总线供 HUD 监听
func _on_health_component_on_unit_damaged(amount: float) -> void:
	EventBus.on_player_health_updated.emit(health_component.current_health, data.max_hp)

## 死亡信号回调，移除玩家实体
func _on_health_component_on_unit_dead() -> void:
	queue_free()

## 治疗信号回调，可在此扩展治疗特效等逻辑
func _on_health_component_on_unit_healed(amount: float) -> void:
	pass
