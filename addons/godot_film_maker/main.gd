tool
extends EditorPlugin

# Load plugin
func _enter_tree():
	add_autoload_singleton("gfm", "res://addons/godot_film_maker/recorder.tscn")
	AudioServer.add_bus()
	AudioServer.add_bus_effect(AudioServer.bus_count -1,
					AudioEffectRecord.new(), 0)
	gfm.audio = AudioServer.get_bus_effect(gfm.bus_idx, 0)

func _exit_tree():
	remove_autoload_singleton("gfm")

