## 敌人基类，实现追踪玩家、朝向翻转、生命系统和死亡逻辑
##
## [b]模块关系[/b]：
## Global.player_ref → 敌人追踪玩家位置
## HealthComponent → on_unit_damaged/on_unit_dead → 敌人更新血条/播放死亡
## Enemy → EventBus.on_enemy_die → EnemySpawner 监听计数
## Bullet → body.health_component.take_damage() → 敌人受伤
extends CharacterBody2D
class_name Enemy

## 敌人最大生命值，用于初始化 HealthComponent 和血条比例计算
@export var max_health := 5.0
## 碰撞伤害值（接触玩家时造成的伤害，预留功能）
@export var collision_damage := 2.0
## 死亡时播放的粒子纹理，不同敌人可配置不同的死亡特效外观
@export var dead_texture: Texture2D
@export_group("Enemy Chase")
## 追踪玩家的移动速度（像素/秒），用于 _physics_process 中计算 velocity
@export var chase_speed := 40.0
@export_group("Enemy Weapon")
## 基础移动速度（预留，未来区分行走/攻击状态速度）
@export var move_speed := 40.0
## 敌人武器配置数据（预留，未来实现远程攻击敌人）
@export var weapon: WeaponData

## 角色动画精灵，播放移动/死亡动画并通过 flip_h 控制朝向
@onready var anim_sprite: AnimatedSprite2D = $AnimSprite
## 玩家检测区域，玩家进入时触发死亡动画
@onready var player_detector: Area2D = $PlayerDetector
## 受伤音效播放器（预留，未来受击时播放）
@onready var hurt_sound: AudioStreamPlayer = $HurtSound

## 敌人头顶血条，显示当前生命值比例（0~1）
@onready var health_bar: ProgressBar = $HealthBar
## 生命组件，处理受伤/治疗/死亡的信号分发
@onready var health_component: HealthComponent = $HealthComponent

## 控制敌人是否可移动（被击晕、冻结等状态时设为 false）
var can_move: bool = true
## 标记敌人是否已被击杀，防止重复触发死亡逻辑
var is_killed: bool

## 初始化：设置血条满值并从 export 属性读取最大生命值
func _ready() -> void:
	health_bar.value = 1.0
	health_component.init_health(max_health)

## 物理帧处理：守卫条件 → 追踪玩家 → 移动 → 翻转朝向
##
## [b]难点说明[/b]：双重守卫条件
## 1. Global.player_ref 为空时退出（玩家未生成或已销毁）
## 2. can_move 为 false 时退出（控制状态，如被击晕）
func _physics_process(_delta: float) -> void:
	# 守卫条件 1：玩家引用不存在时跳过（防止 null 访问崩溃）
	if not Global.player_ref: return
	# 守卫条件 2：不可移动状态时跳过
	if not can_move: return
	
	# 计算从自身指向玩家的单位方向向量（长度为 1.0）
	var dir := global_position.direction_to(Global.player_ref.global_position)
	# 方向向量 × 追踪速度 = 追踪移动速度
	velocity = dir * chase_speed
	move_and_slide()
	rotate_enemy()

## 根据玩家位置翻转精灵朝向
##
## [b]难点说明[/b]：使用 flip_h 而非 scale.x 翻转
## 因为敌人只需翻转动画精灵，不需要像玩家那样翻转 Shadow + 角色整体
## 通过比较 x 坐标判断玩家在左侧还是右侧
func rotate_enemy() -> void:
	# 敌人在玩家右侧 → 面朝左 → 翻转精灵
	if global_position.x > Global.player_ref.global_position.x:
		anim_sprite.flip_h = true
	# 敌人在玩家左侧 → 面朝右 → 正常朝向
	elif global_position.x < Global.player_ref.global_position.x:
		anim_sprite.flip_h = false

## 敌人死亡统一处理：生成死亡粒子特效 → 通知生成器 → 销毁自身
##
## [b]难点说明[/b]：死亡逻辑提取为独立函数
## 被两个路径调用：1. 玩家接触（_on_player_detector_body_entered）
## 2. 生命值归零（_on_health_component_on_unit_dead）
## 避免两处重复代码，确保死亡行为一致
func enemy_dead() -> void:
	# 在敌人位置生成死亡粒子特效（纹理由 dead_texture 配置）
	Global.create_dead_particle(dead_texture, global_position)
	# 通知 EnemySpawner 有一个敌人已死亡
	EventBus.on_enemy_die.emit()
	queue_free()

## 玩家进入检测区域时的信号回调：直接执行死亡流程
func _on_player_detector_body_entered(_body: Node2D) -> void:
	enemy_dead()


## 生命组件受伤信号回调：更新血条 + 播放受击闪白特效
##
## [b]难点说明[/b]：受击闪白实现方式
## 通过临时替换 anim_sprite.material 为 Global.HIT_MATERIAL（白色闪屏 Shader）
## 延时 0.15 秒后恢复为 null（原始材质），实现短暂闪白效果
## 若不使用 await 而直接用 Timer，需要额外回调函数，代码更冗长
func _on_health_component_on_unit_damaged(_amount: float) -> void:
	# 更新血条比例：当前生命值 / 最大生命值
	health_bar.value = health_component.current_health / max_health
	# 施加闪白材质（受击视觉反馈）
	anim_sprite.material = Global.HIT_MATERIAL
	# 延时 0.15 秒后恢复原始材质
	await get_tree().create_timer(0.15).timeout
	anim_sprite.material = null



## 生命组件死亡信号回调：生命值归零时执行死亡流程
func _on_health_component_on_unit_dead() -> void:
	enemy_dead()
