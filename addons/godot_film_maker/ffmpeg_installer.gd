extends HTTPRequest

const ffmpeg_download: Array = [
	"https://github.com/BtbN/FFmpeg-Builds/releases/download/autobuild-2021-09-16-12-21/ffmpeg-N-103646-g8f92a1862a-win64-gpl.zip",
	"https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz",
	"https://evermeet.cx/ffmpeg/ffmpeg-4.4.zip"
] # 0 - Windows, 1 - Linux, 2 - Mac OS

onready var recorder_main = get_parent()
onready var ffmpeg_download_panel = get_parent().get_node("NotificationPanel")

var user_dir: String = OS.get_user_data_dir()

func auto_download_ffmpeg():
	recorder_main.lock_ui()
	var OS_name = OS.get_name()
	ffmpeg_download_panel.show()
	var download_info = ffmpeg_download_panel.get_node("info")
	var dir = Directory.new()
	download_info.text = "Downloading FFMpeg..."
	match OS_name:
		"X11":
			dir.open(user_dir)
			if !dir.file_exists("ffmpeg.tar.xz"):
				print("Downloading static build of FFMpeg for Linux.")
				download_file = str(user_dir + "/ffmpeg.tar.xz")
				if request(ffmpeg_download[1]) != OK: 
					download_info.text = "Could not connect to server. Terminating in 5 seconds..."
					yield(get_tree().create_timer(5), "timeout")
					recorder_main.unlock_ui()
					ffmpeg_download_panel.hide()
					return ERR_CANT_CONNECT
				yield(self, "request_completed")
				print("Download completed!")
			else:
				print("Found ffmpeg.zip")
			var check_tar_output: Array = []
			OS.execute('which', ['tar'], true, check_tar_output)
			if dir.dir_exists("ffmpeg_linux"): OS.execute('rm', ['-r', 'ffmpeg_linux'], true)
			if check_tar_output[0] == "":
				download_info.text = "Tar command not found. Please install tar using your package manager."
			else:
				download_info.text = "Tar found! Uncompressing ffmpeg..."
			OS.execute('tar', ['-xf', user_dir + "/ffmpeg.tar.xz", "--directory", user_dir], true)
			print("Extracted!")
			OS.execute('mv', [user_dir + "/ffmpeg-4.4-amd64-static", user_dir + "/ffmpeg_linux"])
			recorder_main.video.ffmpeg_path = user_dir + "/ffmpeg_linux/ffmpeg"
			print("FFMpeg install path has been set to ", recorder_main.video.ffmpeg_path)
	recorder_main.unlock_ui()
	ffmpeg_download_panel.hide()
	recorder_main.save_video_preferences()
	return OK
