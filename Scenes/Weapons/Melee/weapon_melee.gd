## 近战武器基类（预留扩展，未来实现挥砍、突刺等近战攻击逻辑）
extends Weapon
class_name WeaponMelee

## 挥击粒子发射器，播放近战挥砍特效
@onready var slash: GPUParticles2D = %SlashParticle
## 武器精灵，显示近战武器外观
@onready var sprite: Sprite2D = $Pivot/Sprite2D
## 动画播放器，控制挥砍和待机状态切换
@onready var anim_player: AnimationPlayer = $AnimationPlayer
## 挥砍音效播放器
@onready var slash_sound: AudioStreamPlayer = $SlashSound
## 冷却计时器，控制近战攻击间隔
@onready var cooldown: Timer = $Cooldown
## 可攻击状态标记（类似射程冷却，计时器归零后重置）
var can_use: bool

## 访问数据冷却时间
func _ready() -> void:
	cooldown.wait_time = data.cooldown

## 引入使用武器函数
func use_weapon() -> void:
	if not can_use:
		return
	
	can_use = false
	cooldown.start()
	slash_sound.play()
	anim_player.play("slash")
	
	slash.global_rotation = pivot.global_rotation
	slash.emitting = true

## 输入监听，点击鼠标或按下射击键触发近战攻击
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		use_weapon()

## 冷却计时器超时回调，重置可攻击状态并切回待机动画
func _on_cooldown_timeout() -> void:
	can_use = true
	anim_player.play("idle")
