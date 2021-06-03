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
	"files": [],
}

var current_frame = 0
var zeros = 0
var bus_idx = 0
var audio: AudioEffectRecord
var user_dir = OS.get_user_data_dir()

func start_recording(fps: float,  crf: float):
	frames_timer.set_wait_time(1/fps)
	frames_timer.start()
	AudioServer.add_bus()
	bus_idx = AudioServer.bus_count -1;
	AudioServer.add_bus_effect(bus_idx, AudioEffectRecord.new(), 0)
	audio = AudioServer.get_bus_effect(bus_idx, 0)
	audio.set_recording_active(true)
	create_directory(REC_DIR)

func stop_recording():
	frames_timer.stop()
	audio.set_recording_active(false)
	current_frame = 0
	audio.get_recording().save_to_wav("user://tmp/audio.wav")
	video.files.append("audio.wav")
	AudioServer.remove_bus(bus_idx)
	_render()

func _render():
	pass #Replace with render code

func _ready():
	print(user_dir)
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
	zeros = len(str(video.files.size()))
	for i in range(len(video.files)):
		var new_name = str(i)
		for j in zeros-len(str(i)):
			new_name = "0" + new_name
		new_name = "img" + new_name + ".png"
		if new_name != video.files[i]:
			rename_file("/"+REC_DIR+"/"+video.files[i], "/tmp/"+new_name)
		video.files[i] = new_name
	remove_directory(REC_DIR, video.files)

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
	video.files.append("img"+str(current_frame)+".png")
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

func rename_file(from: String, to: String):
	var output
	match OS.get_name():
		"X11":
			output = OS.execute("mv", [user_dir+from, user_dir+to], true)
		"OSX":
			output = OS.execute("mv", [user_dir+from, user_dir+to], true)
		"windows":
			output = OS.execute("rename", [user_dir+from, user_dir+to], true)
