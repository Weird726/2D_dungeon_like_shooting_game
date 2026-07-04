## 敌人基类，实现追踪玩家、朝向翻转和接触死亡逻辑
##
## [b]模块关系[/b]：
## Global.player_ref → 敌人追踪玩家位置
## Enemy → EventBus.on_enemy_die → EnemySpawner 监听计数
## PlayerDetector（Area2D）→ 玩家接触时触发死亡动画
extends CharacterBody2D
class_name Enemy

## 角色动画精灵，播放移动/死亡动画并通过 flip_h 控制朝向
@onready var anim_sprite: AnimatedSprite2D = $AnimSprite
## 玩家检测区域，玩家进入时触发死亡动画
@onready var player_detector: Area2D = $PlayerDetector
## 受伤音效播放器（预留，未来受击时播放）
@onready var hurt_sound: AudioStreamPlayer = $HurtSound

## 控制敌人是否可移动（被击晕、冻结等状态时设为 false）
var can_move: bool = true

## 物理帧处理：守卫条件 → 追踪玩家 → 移动 → 翻转朝向
##
## [b]难点说明[/b]：双重守卫条件
## 1. Global.player_ref 为空时退出（玩家未生成或已销毁）
## 2. can_move 为 false 时退出（控制状态，如被击晕）
func _physics_process(delta: float) -> void:
	# 守卫条件 1：玩家引用不存在时跳过（防止 null 访问崩溃）
	if not Global.player_ref: return
	# 守卫条件 2：不可移动状态时跳过
	if not can_move: return
	
	# 计算从自身指向玩家的单位方向向量（长度为 1.0）
	var dir := global_position.direction_to(Global.player_ref.global_position)
	# 方向向量 × 固定速度 = 追踪移动速度
	velocity = dir * 50.0
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


## 玩家进入检测区域时的信号回调：播放死亡动画后通知生成器并销毁自身
##
## [b]难点说明[/b]：使用 await 等待动画播完再销毁
## animation_finished 信号在动画播放完成时触发
## 若直接 queue_free() 会导致动画被截断
## 死亡后发射 on_enemy_die 信号，EnemySpawner 监听后累加击杀计数
func _on_player_detector_body_entered(body: Node2D) -> void:
	anim_sprite.play("die")
	# 等待动画播放完成（异步挂起，不阻塞主线程）
	await anim_sprite.animation_finished
	# 通知 EnemySpawner 有一个敌人已死亡
	EventBus.on_enemy_die.emit()
	queue_free()
