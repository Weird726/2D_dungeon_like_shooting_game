extends Control
## 主菜单界面，管理主菜单相关的按钮与动画
class_name MainMenu

## 主按钮组（开始/设置/退出）
@onready var main_buttons: Control = $MainButtons
## 设置按钮组（音乐/音效/窗口/返回）
@onready var settings_buttons: Control = $SettingsButtons
@onready var ui_sound: AudioStreamPlayer = $UISound
@onready var music_label: Label = %MusicLabel
@onready var sfx_label: Label = %SFXLabel
@onready var window_label: Label = %WindowLabel


## 音频标签的热更新
func _ready() -> void:
	update_audio_bus("Music", music_label, Global.settings.music)
	update_audio_bus("SFX", sfx_label, Global.settings.sfx)
	update_fullscreen(Global.settings.fullscreen)

## 切换音频总线的静音状态，并更新按钮标签
func update_audio_bus(bus_name: String, label: Label, is_on: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(bus_name), not is_on)
	label.text = "%s: %s" % [bus_name, "ON" if is_on else "OFF"]

## 判断布尔值切换窗口大小的状态
func update_fullscreen(is_on: bool) -> void:
	var mode = DisplayServer.WINDOW_MODE_FULLSCREEN if is_on else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
	window_label.text = "FULLSCREEN" if is_on else "WINDOWE"


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


func _on_quit_button_pressed() -> void:
	ui_sound.play()
	get_tree().quit()

func _on_music_button_pressed() -> void:
	ui_sound.play()
	# 获取音乐按钮全局信息，并传给音频总线
	update_audio_bus("Music", music_label, Global.settings.music)


func _on_sfx_button_pressed() -> void:
	ui_sound.play()
	# 获取音效按钮全局信息，并传给音频总线
	update_audio_bus("SFX", sfx_label, Global.settings.sfx)


func _on_window_button_pressed() -> void:
	ui_sound.play()
	update_fullscreen(Global.settings.fullscreen)


func _on_back_button_pressed() -> void:
	ui_sound.play()
	var tween := create_tween()
	# 设置按钮组右移收回，主按钮组上移复位
	tween.tween_property(settings_buttons, "global_position:x", 558, 0.3)
	tween.tween_interval(0.1)
	tween.tween_property(main_buttons, "global_position:y", 115, 0.2)
