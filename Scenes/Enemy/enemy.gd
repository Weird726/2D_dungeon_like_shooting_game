## 敌人基类，实现追踪玩家、朝向翻转、生命系统和死亡逻辑
##
## [b]模块关系[/b]：
## Global.player_ref → 敌人追踪玩家位置
## HealthComponent → on_unit_damaged/on_unit_dead → 敌人更新血条/播放死亡
## Enemy → EventBus.on_enemy_die → EnemySpawner 监听计数
## Bullet → body.health_component.take_damage() → 敌人受伤
## WeaponController → 存储 target_pos，WeaponRange 自行读取并旋转
extends CharacterBody2D
class_name Enemy

## 敌人行为类型：Chase = 直接追踪玩家，Weapon = 移动+射击（状态机控制）
@export_enum("Chase", "Weapon") var enemy_type = "Chase"
## Weapon 类型敌人的移动状态机
##
## [b]难点说明[/b]：三状态循环
## FINDING_DESTINATION → MOVING → ATTACKING → FINDING_DESTINATION → ...
## 仅控制移动行为，武器射击由 _process 中的 mange_weapon() 独立管理（不受状态机限制）
enum EnemyStates {
	FINDING_DESTINATION,  ## 从房间获取随机目标位置
	MOVING,               ## 向目标位置移动
	ATTACKING,            ## 到达目标后停留 1 秒（预留攻击动画等）
}

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
## 敌人武器配置数据，非空时敌人会装备武器并朝玩家方向瞄准
@export var weapon: WeaponData

## 角色动画精灵，播放移动/死亡动画并通过 flip_h 控制朝向
@onready var anim_sprite: AnimatedSprite2D = $AnimSprite
## 玩家检测区域，玩家进入时触发死亡动画
@onready var player_detector: Area2D = $PlayerDetector
## 受伤音效播放器（预留，未来受击时播放）
@onready var hurt_sound: AudioStreamPlayer = $HurtSound
## 敌人检测区域，用于检测附近其他敌人实现分离行为（防止重叠堆叠）
@onready var enemy_detector: Area2D = $EnemyDetector

## 敌人头顶血条，显示当前生命值比例（0~1）
@onready var health_bar: ProgressBar = $HealthBar
## 生命组件，处理受伤/治疗/死亡的信号分发
@onready var health_component: HealthComponent = $HealthComponent
## 敌人武器控制器，存储 target_pos 供 WeaponRange 读取（不再直接控制旋转）
@onready var weapon_controller: WeaponController = $WeaponController

## 控制敌人是否可移动（被击晕、冻结等状态时设为 false）
var can_move: bool = true
## 标记敌人是否已被击杀，防止重复触发死亡逻辑
var is_killed: bool
## 武器射击冷却倒计时（秒），归零时允许再次射击，射击后重置为武器数据中的 cooldown
var cooldown: float

## 敌人所在房间引用，由 EnemySpawner.spawn_enemies() 在生成时赋值
## 用于 Weapon 类型敌人调用 get_free_spawn_position() 获取随机移动目标
var parent_room: LevelRoom
## Weapon 类型敌人的当前移动状态（状态机驱动）
var enemy_state: EnemyStates
## Weapon 类型敌人的移动目标位置（世界坐标），由 FINDING_DESTINATION 状态随机生成
var move_destination: Vector2

## 初始化：设置血条满值、生命值，并装备武器（若有配置）
##
## [b]难点说明[/b]：equip_weapon 传入 is_ai = true
## 告知 WeaponRange 当前为 AI 控制模式，使用玩家位置而非鼠标位置旋转武器
func _ready() -> void:
	health_bar.value = 1.0
	health_component.init_health(max_health)
	
	# 防御性检查：weapon 为空时跳过装备（非武器敌人无需武器控制器）
	if not weapon: return
	weapon_controller.equip_weapon(weapon, true)

## 每帧处理：朝向翻转 + 武器瞄准/射击（不受状态机限制）
##
## [b]难点说明[/b]：_process vs _physics_process 分离
## 旋转朝向和武器瞄准放在 _process（渲染帧），移动放在 _physics_process（物理帧）
## 因为 look_at() 需要每帧平滑更新，而 move_and_slide() 需要固定时间步长
##
## [b]难点说明[/b]：mange_weapon 不受 enemy_state 限制
## 武器瞄准和射击独立于移动状态机运行，确保敌人在任何状态下都能持续射击
## 否则 ATTACKING 状态仅 1 秒，武器冷却 > 1 秒时永远无法射出第二发
func _process(delta: float) -> void:
	if not Global.player_ref: return
	rotate_enemy()
	mange_weapon(delta)

## 物理帧处理：守卫条件 → 按敌人类型分发移动逻辑
##
## [b]难点说明[/b]：双重守卫条件
## 1. Global.player_ref 为空时退出（玩家未生成或已销毁）
## 2. can_move 为 false 时退出（控制状态，如被击晕）
func _physics_process(_delta: float) -> void:
	# 守卫条件 1：玩家引用不存在时跳过（防止 null 访问崩溃）
	if not Global.player_ref: return
	# 守卫条件 2：不可移动状态时跳过
	if not can_move: return
	
	match enemy_type:
		"Chase":
			run_enemy_chase()
		"Weapon":
			run_enemy_weapon()

## Chase 类型移动：直线追踪玩家 + Boids 分离避让
##
## [b]难点说明[/b]：分离行为（Boids Separation）
## 通过 enemy_detector 检测附近敌人，施加与距离成反比的排斥力
## 排斥力公式：系数 × 归一化方向 / 距离 → 距离越近排斥力越大
func run_enemy_chase() -> void:
	# 计算从自身指向玩家的单位方向向量（长度为 1.0）
	var dir := global_position.direction_to(Global.player_ref.global_position)
	# 分离行为（Boids Separation）：检测附近敌人并施加排斥力
	# 排斥力公式：系数 × 归一化方向 / 距离 → 距离越近排斥力越大
	for enemy: Enemy in enemy_detector.get_overlapping_bodies():
		if enemy != self and enemy.is_inside_tree():
			var vector = global_position - enemy.global_position
			dir += 30 * vector.normalized() / vector.length()
	# 方向向量 × 追踪速度 = 追踪移动速度
	velocity = dir * chase_speed
	move_and_slide()

## Weapon 类型移动：三状态循环（找位置 → 移动 → 停留）
##
## [b]难点说明[/b]：状态机仅控制移动，不影响武器射击
## FINDING_DESTINATION：从 parent_room 获取随机地砖位置作为移动目标
## MOVING：直线移动到目标位置，到达后切换到 ATTACKING
## ATTACKING：停留 1 秒（await），然后回到 FINDING_DESTINATION 循环
##
## [b]难点说明[/b]：await 在 _physics_process 中的行为
## await 使当前协程挂起，但 _physics_process 每帧仍会被引擎调用
## 挂起期间其他代码（如 _process）正常执行，不会阻塞
func run_enemy_weapon() -> void:
	match enemy_state:
		EnemyStates.FINDING_DESTINATION:
			# 从房间获取随机地砖位置（本地坐标）→ 转换为世界坐标
			var local_pos = parent_room.get_free_spawn_position()
			move_destination = parent_room.to_global(local_pos)
			enemy_state = EnemyStates.MOVING
		
		EnemyStates.MOVING:
			# 向目标位置直线移动
			var dir = global_position.direction_to(move_destination)
			velocity = dir * move_speed
			move_and_slide()
			# 到达目标（距离 < 2 像素）→ 停止并切换到停留状态
			if global_position.distance_to(move_destination) < 2.0:
				velocity = Vector2.ZERO
				enemy_state = EnemyStates.ATTACKING
		
		EnemyStates.ATTACKING:
			# 停留 1 秒后重新寻找下一个移动目标
			velocity = Vector2.ZERO
			move_and_slide()
			await get_tree().create_timer(1.0).timeout
			enemy_state = EnemyStates.FINDING_DESTINATION

## 管理武器朝向 + 冷却射击：设置目标位置 → 武器自旋转 → 冷却判断 → 开火
##
## [b]难点说明[/b]：旋转职责下放
## Enemy 仅设置 weapon_controller.target_pos，WeaponRange._process() 自行读取并旋转
## 不再调用 weapon_controller.rotate_weapon()（该方法已移除）
## 武器旋转和翻转完全由 WeaponRange 自管理，降低跨类耦合
##
## [b]难点说明[/b]：射击冷却机制（与 Player._process 中的逻辑对称）
## 1. 每帧递减 cooldown，归零时允许射击
## 2. 射击后立即重置为武器数据中的 cooldown 值（控制射速）
func mange_weapon(delta: float) -> void:
	if not weapon: return
	if not weapon_controller: return
	# 将玩家位置设为武器瞄准目标（WeaponRange 每帧自行读取此值并旋转）
	weapon_controller.target_pos = Global.player_ref.global_position
	
	# 冷却倒计时递减，归零时执行射击
	cooldown -= delta
	if cooldown <= 0:
		# 调用当前武器的攻击方法（生成子弹等）
		weapon_controller.current_weapon.use_weapon()
		# 重置冷却为武器数据中设定的射击间隔
		cooldown = weapon_controller.current_weapon.data.cooldown

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
	# 防重复死亡守卫：多个信号可能在同一帧触发（如接触+血量归零）
	# is_killed 确保死亡流程只执行一次，防止重复发射信号和特效
	if is_killed:
		return
	
	is_killed = true
	# 在敌人位置生成死亡粒子特效（纹理由 dead_texture 配置）
	Global.create_dead_particle(dead_texture, global_position)
	# 通知 EnemySpawner 有一个敌人已死亡
	EventBus.on_enemy_die.emit()
	queue_free()

## 玩家进入检测区域时的信号回调：造成伤害 + 执行死亡流程
func _on_player_detector_body_entered(body: Node2D) -> void:
	body.health_component.take_damage(collision_damage)
	enemy_dead()


## 生命组件受伤信号回调：更新血条 + 播放受击闪白特效 + 切换受伤动画
##
## [b]难点说明[/b]：受击闪白实现方式
## 通过临时替换 anim_sprite.material 为 Global.HIT_MATERIAL（白色闪屏 Shader）
## 延时 0.15 秒后恢复为 null（原始材质），实现短暂闪白效果
## 若不使用 await 而直接用 Timer，需要额外回调函数，代码更冗长
##
## [b]难点说明[/b]：动画切换时序
## 受伤时立即播放 "hurt" 动画（叠加闪白材质），延时结束后切回 "move" 动画
## 必须在延时后切换回 "move"，否则敌人会永久停留在 "hurt" 动画帧
func _on_health_component_on_unit_damaged(_amount: float) -> void:
	# 更新血条比例：当前生命值 / 最大生命值
	health_bar.value = health_component.current_health / max_health
	# 施加闪白材质（受击视觉反馈）
	anim_sprite.material = Global.HIT_MATERIAL
	# 播放受伤动画（需确保 AnimatedSprite2D 中存在 "hurt" 动画帧）
	anim_sprite.play("hurt")
	# 延时 0.15 秒后恢复原始材质并切回移动动画
	await get_tree().create_timer(0.15).timeout
	anim_sprite.material = null
	anim_sprite.play("move")



## 生命组件死亡信号回调：生命值归零时执行死亡流程
func _on_health_component_on_unit_dead() -> void:
	enemy_dead()
