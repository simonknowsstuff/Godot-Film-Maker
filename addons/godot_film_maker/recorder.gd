extends CanvasLayer

# Buttons
onready var play_btn = $Controls/buttons/play_button
onready var rec_btn = $Controls/buttons/rec_button
onready var stop_btn = $Controls/buttons/stop_button
onready var pause_btn = $Controls/buttons/pause_button

onready var settings_popup = $SettingsPopup

# Constants
const REC_DIR = "tmp" # Screenshots will be stored in this directory

# Video properties
var video = {
	"fps": 30.0,
	"crf": 60.0,
	"frames": [],
}

func start_recording():
	pass

func _ready():
	init()

func _on_rec_button_pressed():
	rec_btn.hide()
	stop_btn.show()
	pass # Replace with function body.

func _on_play_button_pressed():
	pass # Replace with function body.

func _on_stop_button_pressed():
	rec_btn.show()
	stop_btn.hide()
	pass # Replace with function body.

func _on_pause_button_pressed():
	pass # Replace with function body.

func init():
	stop_btn.hide()
	rec_btn.show()
	print("Godot Film Maker initialised!")

func _on_settings_button_pressed():
	settings_popup.popup()

func _on_Exit_Btn_pressed():
	video.crf = settings_popup.get_node(
		"SettingsRow/ValueColumn/CRF_Count").text
	video.fps = settings_popup.get_node(
		"SettingsRow/ValueColumn/FPS_Count").text
	settings_popup.hide()


# Basic tools
func create_directory(dir_name: String):
	var dir = Directory.new()
	dir.open("user://")
	dir.make_dir(dir_name)

