extends CanvasLayer

# Buttons
onready var play_btn = $Controls/Buttons/Play
onready var rec_btn = $Controls/Buttons/Record
onready var stop_btn = $Controls/Buttons/Stop
onready var pause_btn = $Controls/Buttons/Pause
onready var settings_btn = $Controls/Buttons/Settings

onready var export_popup = $SaveOutputDialog
onready var settings_popup = $SettingsPopup

# Constants
const REC_DIR = "tmp" # Screenshots will be stored in this directory within user://

# Video properties
var video = {
	"fps": 60.0,
	"crf": 60.0,
	"files": [],
	"output_path": "",
	"resolution": Vector2(1920, 1080)
}

var current_frame = 0
var effect_idx = 0
var audio: AudioEffectRecord
var user_dir: String = OS.get_user_data_dir()
var should_stop = false

onready var current_scene = get_tree().current_scene

func _ready():
	stop_btn.hide()
	rec_btn.show()

	get_tree().paused = true

	# Pause the scene's tree to prevent any animations from playing
	current_scene.pause_mode = Node.PAUSE_MODE_STOP

	print("Godot Film Maker initialised!")

func start_recording(fps: float, crf: float):
	settings_btn.disabled = true
	AudioServer.add_bus_effect(0, AudioEffectRecord.new())
	effect_idx = AudioServer.get_bus_effect_count(0) - 1
	audio = AudioServer.get_bus_effect(effect_idx, 0)
	audio.set_recording_active(true)

	# Move the animation scene to the renderer viewport
	reparent(current_scene, $RenderViewport)
	$PreviewWindow.visible = true

	# Prepare the viewport resolution
	$RenderViewport.size = video.resolution

	# Create the folder where we save our frames
	create_directory(REC_DIR)

	# Lock the engine FPS to the video FPS
	Engine.target_fps = video.fps

	# Start saving frames
	snap_frame()

func snap_frame():
	while !should_stop:
		# Play the tree for a frame
		current_scene.pause_mode = Node.PAUSE_MODE_PROCESS
		yield(get_tree(), "idle_frame")
		current_scene.pause_mode = Node.PAUSE_MODE_STOP

		# Grab the viewport
		var frame = $RenderViewport.get_texture().get_data()
		# Wait two frames
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")

		# Save it
		frame.save_png("user://" + REC_DIR + "/img"+str(current_frame)+".png")
		video.files.append("img"+str(current_frame)+".png")
		current_frame += 1

func stop_recording():
	# Stop the frame saving loop
	should_stop = true
	audio.set_recording_active(false)

	# Reset frame number
	current_frame = 0
	audio.get_recording().save_to_wav("user://tmp/audio.wav")
	AudioServer.remove_bus_effect(0, effect_idx)

	Engine.target_fps = 60

	# Show the export popup
	export_popup.show()

func render_video(output_path):
	print("Rendering video with ", str(video.fps), " as framerate and ", str(video.crf), " as the CRF.")
	var output = []

	OS.execute(
		"ffmpeg",
		[
			"-y",
			"-f", "image2",
			"-framerate", video.fps,
			"-i", user_dir + "/tmp/img%d.png",
#			"-i", user_dir + "/tmp/audio.wav",
#			"-crf", video.crf,
			output_path
		],
		true, output
	)
	print("Render done!")
	print(output)
	settings_btn.disabled = false
	remove_directory(REC_DIR, video.files)

# Event handlers
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

func _on_settings_button_pressed():
	settings_popup.popup()

func _on_Exit_Btn_pressed():
	video.crf = $SettingsPopup/Settings/CRF/Value.value
	video.fps = $SettingsPopup/Settings/FPS/Value.value
	video.resolution.x = $SettingsPopup/Settings/Resolution/Value/X.value
	video.resolution.y = $SettingsPopup/Settings/Resolution/Value/Y.value
	print("Framerate: ", video.fps, " FPS")
	print("CRF: ", video.crf)
	print("Resolution: ", video.resolution)

	settings_popup.hide()

func _on_SaveOutputDialog_file_selected(path):
	render_video(path)

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

func reparent(child: Node, new_parent: Node):
	var old_parent = child.get_parent()
	old_parent.remove_child(child)
	new_parent.add_child(child)
