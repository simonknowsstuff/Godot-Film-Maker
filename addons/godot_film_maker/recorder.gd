extends CanvasLayer

# Buttons
onready var play_btn = $Controls/Buttons/Play
onready var rec_btn = $Controls/Buttons/Record
onready var stop_btn = $Controls/Buttons/Stop
onready var pause_btn = $Controls/Buttons/Pause
onready var settings_btn = $Controls/Buttons/Settings
onready var notification_panel = $NotificationPanel
onready var ffmpeg_installer = $HTTPRequest

onready var export_popup = $SaveOutputDialog
onready var settings_popup = $SettingsPopup

# Constants
const REC_DIR = "tmp" # Screenshots will be stored in this directory within user://

# Video config
const VIDEO_DEFAULT = {
	"fps": 60.0,
	"ffmpeg_path": "ffmpeg",
	"crf": 24.0,
	"output_path": "",
	"viewport_scale": 1.0,
	"video_scale": 1.0,
	"for_web": false
}
const VIDEO_CONFIG_SAVE_PATH = "user://video.json"

# Video properties
var video = {
	"fps": 60.0,
	"ffmpeg_path": "ffmpeg",
	"crf": 24.0,
	"output_path": "",
	"viewport_scale": 1.0,
	"video_scale": 1.0,
	"for_web": false
}

var current_frame = 0
var effect_idx = 0
var audio: AudioEffectRecord
var user_dir: String = OS.get_user_data_dir()

# Multithreaded resources, handle with care
var capture_semaphore: Semaphore
var save_semaphore: Semaphore
var threads = []
var frames = []

var stop_mutex: Mutex
var should_stop = false
# End of multithread resources

onready var current_scene = get_tree().current_scene

func _ready():
	load_video_preferences()
	stop_btn.hide()
	rec_btn.show()

	get_tree().paused = true

	# Pause the scene's tree to prevent any animations from playing
	current_scene.pause_mode = Node.PAUSE_MODE_STOP

	capture_semaphore = Semaphore.new()
	save_semaphore = Semaphore.new()

	stop_mutex = Mutex.new()

	for i in 12:
		var thread = Thread.new()
		thread.start(self, "_frame_saver_thread", i)
		threads.append(thread)

	print("Godot Film Maker initialised!")
	
func load_video_preferences():
	var load_cfg = File.new()
	if not load_cfg.file_exists(VIDEO_CONFIG_SAVE_PATH):
		video = VIDEO_DEFAULT.duplicate(true)
		save_video_preferences()
	load_cfg.open(VIDEO_CONFIG_SAVE_PATH, File.READ)
	video = parse_json(load_cfg.get_as_text())
	update_settings_menu(video.crf, video.fps, video.video_scale, video.viewport_scale, video.for_web)
	load_cfg.close()

func save_video_preferences():
	var save_cfg = File.new()
	save_cfg.open(VIDEO_CONFIG_SAVE_PATH, File.WRITE)
	save_cfg.store_line(to_json(video))
	save_cfg.close()

func start_recording():
	rec_btn.hide()
	stop_btn.show()
	settings_btn.disabled = true
	AudioServer.add_bus_effect(0, AudioEffectRecord.new())
	effect_idx = AudioServer.get_bus_effect_count(0) - 1
	audio = AudioServer.get_bus_effect(effect_idx, 0)
	audio.set_recording_active(true)

	# Move the animation scene to the renderer viewport
	reparent(current_scene, $RenderViewport)
	$PreviewWindow.visible = true

	# Prepare the viewport resolution
	$RenderViewport.size = get_tree().get_root().size * video.viewport_scale

	# Create the folder where we save our frames
	create_directory(REC_DIR)

	# Lock the engine FPS to the video FPS
	Engine.iterations_per_second = video.fps
	frames.resize(int(video.fps))

	# Start saving frames
	for i in threads:
		capture_semaphore.post()
	snap_frame()

func snap_frame():
	while true:
		print("Waiting for save to complete...")
		for i in threads:
			capture_semaphore.wait()

		if should_stop:
			break

		for i in int(video.fps):
			print("Preparing frame ", current_frame)
			# Play the tree for a frame
			current_scene.pause_mode = Node.PAUSE_MODE_PROCESS
			yield(get_tree(), "physics_frame")
			yield(get_tree(), "physics_frame")
			current_scene.pause_mode = Node.PAUSE_MODE_STOP

			# Grab the viewport
			var frame = $RenderViewport.get_texture().get_data()
			# Wait a frame
			yield(get_tree(), "idle_frame")

			frames[i] = [frame, current_frame]
			current_frame += 1

		for i in threads:
			save_semaphore.post()

func _frame_saver_thread(thread_start_index):
	while true:
#		Debug line.
#		print("Waiting for capture to complete...")
		save_semaphore.wait() # Wait until posted.
		print("Saving frames...")

		stop_mutex.lock()
		if should_stop:
			stop_mutex.unlock()
			break
		stop_mutex.unlock()

		for i in range(thread_start_index, frames.size(), threads.size()):
			if frames[i] == null:
				break
			print(frames[i][1])
			var img = frames[i][0]
			var scaled_size = img.get_size() * video.video_scale
			img.resize(scaled_size.x, scaled_size.y, Image.INTERPOLATE_NEAREST)
			img.save_exr("user://" + REC_DIR + "/img"+str(frames[i][1])+".exr")

		print("Frames saved, signalling capture")
		capture_semaphore.post();

	print("Stopping thread")

func stop_recording():
	rec_btn.show()
	stop_btn.hide()
	# Stop the frame saving loop
	audio.set_recording_active(false)

	stop_mutex.lock()
	should_stop = true
	stop_mutex.unlock()

	# Unblock by posting.
	for i in threads:
		save_semaphore.post()
		capture_semaphore.post()

	# Wait for saving
	for thread in threads:
		thread.wait_to_finish()

	# Reset frame number
	current_frame = 0
	audio.get_recording().save_to_wav("user://tmp/audio.wav")
	AudioServer.remove_bus_effect(0, effect_idx)

	Engine.iterations_per_second = 60

	# Show the export popup
	export_popup.show()

func render_video(output_path):
	print("Rendering video with ", str(video.fps), " as framerate and ", str(video.crf), " as the CRF.")
	var output = []
	
	notification_panel.get_node("info").text = "Rendering Video..."
	notification_panel.show()
	
	# Add in your custom ffmpeg commands here.
	# The output path is added in the web_check
	var ffmpeg_execute: Array = [
			"-y",
			"-f", "image2",
			"-framerate", video.fps,
			"-i", user_dir + "/tmp/img%d.exr",
#			"-i", user_dir + "/tmp/audio.wav",
			"-crf", video.crf,
		]
	
	# Web check
	if video.for_web:
		ffmpeg_execute.append_array(["-vf", "format=yuv420p"])
	
	ffmpeg_execute.append(output_path)
	
	OS.execute(video.ffmpeg_path, ffmpeg_execute, true, output, true)
	
	print("Render done!")
	notification_panel.hide()
	print(output)
	settings_btn.disabled = false
	remove_directory(REC_DIR)

# Thread must be disposed (or "joined"), for portability.
func _exit_tree():
	stop_mutex.lock()
	should_stop = true
	stop_mutex.unlock()

	# Wait for saving
	for thread in threads:
		thread.wait_to_finish()

	# Unblock by posting.
	for i in threads:
		save_semaphore.post()
		capture_semaphore.post()

# Event handlers
func _on_rec_button_pressed():
	start_recording()

func _on_play_button_pressed():
	pass # Replace with function body.

func _on_stop_button_pressed():
	stop_recording()

func _on_pause_button_pressed():
	pass # Replace with function body.

func _on_settings_button_pressed():
	settings_popup.popup()

func _on_Exit_Btn_pressed():
	video.fps = $SettingsPopup/Settings/FPS/Value.value
	video.crf = $SettingsPopup/Settings/CRF/Value.value
	video.video_scale = $SettingsPopup/Settings/VideoScale/Value.value
	video.viewport_scale = $SettingsPopup/Settings/ViewportScale/Value.value
	video.for_web = $SettingsPopup/Settings/ForWeb/Value.pressed
	save_video_preferences()
	settings_popup.hide()

func _on_SaveOutputDialog_file_selected(path):
	render_video(path)

# Basic tools
func create_directory(dir_name: String):
	var dir = Directory.new()
	dir.open("user://")
	dir.make_dir(dir_name)

func remove_directory(dir_name: String):
	var dir = Directory.new()
	dir.open("user://"+ dir_name)
	dir.list_dir_begin(true, true)
	
	var file = dir.get_next()
	while file != "":
		dir.remove(file)
		file = dir.get_next()
	dir.open("user://")
	dir.remove(dir_name)

func reparent(child: Node, new_parent: Node):
	var old_parent = child.get_parent()
	old_parent.remove_child(child)
	new_parent.add_child(child)

func update_settings_menu(crf=24, fps=60, video_scale=1, viewport_scale=1, for_web=false):
	$SettingsPopup/Settings/CRF/Value.value = crf
	$SettingsPopup/Settings/FPS/Value.value = fps
	$SettingsPopup/Settings/VideoScale/Value.value = video_scale
	$SettingsPopup/Settings/ViewportScale/Value.value = viewport_scale
	$SettingsPopup/Settings/ForWeb/Value.pressed = video.for_web

func _on_forweb_toggled(button_pressed):
	video.for_web = button_pressed

func _on_ffmpeg_path_btn_pressed():
	lock_ui()
	settings_popup.hide()
	get_node("FFMpegLocator").show()

func _on_ffmpeg_auto_download_pressed():
	settings_popup.hide()
	ffmpeg_installer.auto_download_ffmpeg()

func _on_FFMpegLocator_file_selected(path):
	unlock_ui()
	settings_popup.show()
	get_node("FFMpegLocator").hide()
	video.ffmpeg_path = path

func _on_ffmpeg_global_setter_pressed():
	video.ffmpeg_path = "ffmpeg"

func lock_ui():
	var control_nodes = $Controls.get_node("Buttons").get_children()
	for control_node in control_nodes:
		control_node.disabled = true

func unlock_ui():
	var control_nodes = $Controls.get_node("Buttons").get_children()
	for control_node in control_nodes:
		control_node.disabled = false

func _on_FFMpegLocator_popup_hide():
	unlock_ui()
	settings_popup.show()
	get_node("FFMpegLocator").hide()
