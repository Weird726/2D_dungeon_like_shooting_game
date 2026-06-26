@tool
extends EditorPlugin

## 插件入口：注册 DampedOscillator 为全局 autoload 单例
func _enter_tree() -> void:
	add_autoload_singleton("DampedOscillator", "res://addons/DampedOscillator/scripts/damped_oscillator.tscn")

## 插件退出：移除 autoload 单例
func _exit_tree() -> void:
	remove_autoload_singleton("DampedOscillator")