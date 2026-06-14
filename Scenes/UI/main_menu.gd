extends Control
## 主菜单界面，管理主菜单相关的按钮与动画
class_name MainMenu

## 主按钮组（开始/设置/退出）
@onready var main_buttons: Control = $MainButtons
## 设置按钮组（音乐/音效/窗口/返回）
@onready var settings_buttons: Control = $SettingsButtons
## UI 点击音效播放器
@onready var ui_sound: AudioStreamPlayer = $UISound
## 音乐开关状态标签
@onready var music_label: Label = %MusicLabel
## 音效开关状态标签
@onready var sfx_label: Label = %SFXLabel
## 窗口模式状态标签
@onready var window_label: Label = %WindowLabel


## 初始化：加载存档数据并同步 UI 状态
func _ready() -> void:
	Global.load_data()
	update_audio_bus("Music", music_label, Global.settings.music)
	update_audio_bus("SFX", sfx_label, Global.settings.sfx)
	update_fullscreen(Global.settings.fullscreen)

## 切换音频总线的静音状态，并更新按钮标签
func update_audio_bus(bus_name: String, label: Label, is_on: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(bus_name), not is_on)
	label.text = "%s: %s" % [bus_name, "ON" if is_on else "OFF"]

## 切换窗口模式（全屏/窗口），并更新标签
func update_fullscreen(is_on: bool) -> void:
	var mode = DisplayServer.WINDOW_MODE_FULLSCREEN if is_on else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
	window_label.text = "FULLSCREEN" if is_on else "WINDOWED"


func _on_play_button_pressed() -> void:
	ui_sound.play()
	Transition.transition_to("res://Scenes/UI/CharacterSelection/character_selection.tscn")

func _on_settings_button_pressed() -> void:
	ui_sound.play()
	var tween := create_tween()
	# 主按钮组下移，露出设置按钮组
	tween.tween_property(main_buttons, "global_position:y", 350, 0.2)
	tween.tween_interval(0.1)
	tween.tween_property(settings_buttons, "global_position:x", 145, 0.3)


## 退出游戏：先保存设置再退出，防止用户设置丢失
func _on_quit_button_pressed() -> void:
	ui_sound.play()
	Global.save_data()
	get_tree().quit()

func _on_music_button_pressed() -> void:
	ui_sound.play()
	Global.settings.music = not Global.settings.music
	update_audio_bus("Music", music_label, Global.settings.music)
 

func _on_sfx_button_pressed() -> void:
	ui_sound.play()
	Global.settings.sfx = not Global.settings.sfx 
	update_audio_bus("SFX", sfx_label, Global.settings.sfx)


func _on_window_button_pressed() -> void:
	ui_sound.play()
	Global.settings.fullscreen = not Global.settings.fullscreen
	update_fullscreen(Global.settings.fullscreen)


func _on_back_button_pressed() -> void:
	ui_sound.play()
	var tween := create_tween()
	# 设置按钮组右移收回，主按钮组上移复位
	tween.tween_property(settings_buttons, "global_position:x", 558, 0.3)
	tween.tween_interval(0.1)
	tween.tween_property(main_buttons, "global_position:y", 115, 0.2)

## 系统通知回调，用于监听窗口关闭事件
##
## [b]难点说明[/b]：Godot 关闭窗口时不会自动调用 _on_quit_button_pressed()，
## 必须监听 NOTIFICATION_WM_CLOSE_REQUEST 才能捕获窗口 X 按钮的点击，
## 否则用户直接关闭窗口会导致设置未保存。
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Global.save_data()
