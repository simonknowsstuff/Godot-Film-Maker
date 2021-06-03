extends CanvasLayer

# Buttons
onready var play_btn = $Controls/buttons/play_button
onready var rec_btn = $Controls/buttons/rec_button
onready var stop_btn = $Controls/buttons/stop_button
onready var pause_btn = $Controls/buttons/pause_button

onready var settings_popup = $SettingsPopup
onready var frames_timer = $FramesTimer

# Constants
const REC_DIR = "tmp" # Screenshots will be stored in this directory

# Video properties
var video = {
	"fps": 24.0,
	"crf": 60.0,
	"frames": [],
}

var current_frame = 0
var audio: AudioEffectRecord

func start_recording(fps: float,  crf: float):
	frames_timer.set_wait_time(1/fps)
	frames_timer.start()
	audio.set_recording_active(true)
	create_directory(REC_DIR)

func stop_recording():
	frames_timer.stop()
	audio.set_recording_active(false)
	current_frame = 0
	audio.get_recording().save_to_wav("user://tmp/audio.waw")
	_render()

func _render():
	pass # Repace with rendering code

func _ready():
	init()

func _on_rec_button_pressed():
	rec_btn.hide()
	stop_btn.show()
	start_recording(video.fps, video.crf)

func _on_play_button_pressed():
	pass # Replace with function body.

func _on_stop_button_pressed():
	rec_btn.show()
	stop_btn.hide()
	stop_recording()
	remove_directory(REC_DIR, video.frames)

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

func _frame():
	# Called every frame
	var frame = get_tree().get_root().get_texture().get_data()
	frame.flip_y()
	frame.save_png("user://"+REC_DIR+"/img"+str(current_frame)+".png")
	video.frames.append("img"+str(current_frame)+".png")
	current_frame += 1


# Basic tools
func create_directory(dir_name: String):
	var dir = Directory.new()
	dir.open("user://")
	dir.make_dir(dir_name)

func remove_directory(dir_name: String, contents:Array):
	var dir = Directory.new()
	dir.open("user://")
	for i in contents:
		dir.remove(dir_name+"/"+i)
	dir.remove(dir_name)
