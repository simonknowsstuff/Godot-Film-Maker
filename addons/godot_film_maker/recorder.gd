extends CanvasLayer

# Buttons
onready var play_btn = $Controls/buttons/play_button
onready var rec_btn = $Controls/buttons/rec_button
onready var stop_btn = $Controls/buttons/stop_button
onready var pause_btn = $Controls/buttons/pause_button
onready var settings_btn = $Controls/buttons/settings_button

onready var export_popup = $SaveOutputDialog
onready var settings_popup = $SettingsPopup
onready var frames_timer = $FramesTimer

# Constants
const REC_DIR = "tmp" # Screenshots will be stored in this directory


# Video properties
var video = {
	"fps": 60.0,
	"crf": 60.0,
	"files": [],
	"output_path": ""
}

var current_frame = 0
var zeros = 0
var effect_idx = 0
var audio: AudioEffectRecord
var user_dir: String = OS.get_user_data_dir()

func start_recording(fps: float,  crf: float):
	settings_btn.disabled = true
	frames_timer.start(1/fps)
	AudioServer.add_bus_effect(0, AudioEffectRecord.new())
	effect_idx = AudioServer.get_bus_effect_count(0)-1
	audio = AudioServer.get_bus_effect(effect_idx, 0)
	audio.set_recording_active(true)
	create_directory(REC_DIR)

func stop_recording():
	frames_timer.stop()
	audio.set_recording_active(false)
	current_frame = 0
	audio.get_recording().save_to_wav("user://tmp/audio.wav")
	AudioServer.remove_bus_effect(0, effect_idx)
	export_popup.show()

func _render(output_path):
	print("Rendering video with ", str(video.fps), " as framerate and ", str(video.crf), " as the CRF.")
	OS.execute("ffmpeg", ["-y", "-framerate", video.fps, "-i", user_dir + "/tmp/img%d.png", "-i", user_dir + "/tmp/audio.wav", "-crf", video.crf, output_path], true)
	print("Render done!")
	settings_btn.disabled = false
	remove_directory(REC_DIR, video.files)

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

func _on_pause_button_pressed():
	pass # Replace with function body.

func init():
	stop_btn.hide()
	rec_btn.show()
	print("Godot Film Maker initialised!")

func _on_settings_button_pressed():
	settings_popup.popup()

func _on_Exit_Btn_pressed():
	video.crf = settings_popup.get_node("SettingsRow/ValueColumn/CRF_Count").value
	video.fps = settings_popup.get_node("SettingsRow/ValueColumn/FPS_Count").value
	print("Framerate is ", str(video.fps), " and CRF is ", str(video.crf))
	settings_popup.hide()

func _frame():
	# Called every frame
	var frame = get_tree().get_root().get_texture().get_data()
	frame.flip_y()
	frame.save_png("user://" + REC_DIR + "/img"+str(current_frame)+".png")
	video.files.append("img"+str(current_frame)+".png")
	current_frame += 1
	frames_timer.start()

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
		dir.remove(dir_name+"/audio.wav")
	dir.remove(dir_name)

func rename_file(from: String, to: String):
	var output
	match OS.get_name():
		"X11":
			output = OS.execute("mv", [user_dir+from, user_dir+to], true)
		"OSX":
			output = OS.execute("mv", [user_dir+from, user_dir+to], true)
		"windows":
			output = OS.execute("rename", [user_dir+from, user_dir+to], true)

func _on_SaveOutputDialog_file_selected(path):
	_render(path)

