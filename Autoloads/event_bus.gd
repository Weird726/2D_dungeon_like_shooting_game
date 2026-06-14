extends Node

## 全局事件总线，用于跨场景通信（解耦组件间的直接引用）
## 当玩家生命值变化时触发，HUD 等 UI 监听此信号更新显示
signal on_player_health_updated(current: float, max: float)
