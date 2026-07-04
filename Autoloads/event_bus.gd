extends Node

## 全局事件总线，用于跨场景通信（解耦组件间的直接引用）
## 当玩家生命值变化时触发，HUD 等 UI 监听此信号更新显示
signal on_player_health_updated(current: float, max: float)
## 玩家进入房间时触发，Arena 监听后执行锁门 + 小地图更新 + 敌人生成
signal on_player_room_entered(room: LevelRoom)

## 敌人死亡时触发，EnemySpawner 监听后累加击杀计数
signal on_enemy_die
## 房间所有敌人被消灭时触发，Arena 监听后执行 unlock_room()
signal on_room_cleared
