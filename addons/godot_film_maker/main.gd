tool
extends EditorPlugin

# Load plugin
func _enter_tree():
	add_autoload_singleton("gfm", "res://addons/godot_film_maker/recorder.tscn")

func _exit_tree():
	remove_autoload_singleton("gfm")
	
