extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# 1 = mouse left button
	if Input.is_mouse_button_pressed(1):
		get_tree().change_scene_to_file("res://Scenes/Rooms/Witch/witch.tscn")
