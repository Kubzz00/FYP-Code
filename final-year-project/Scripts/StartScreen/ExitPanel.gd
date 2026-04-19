extends Node3D

@onready var holder = $ModelHolder

var model_scene = preload("res://Scenes/StartScreenScene/FistModel.tscn")

var model = null

# ---------------- ANIMATION ----------------
var time_passed := 0.0
var max_angle := 25.0   

func _ready():
	spawn_model()

func spawn_model():
	model = model_scene.instantiate()
	holder.add_child(model)

	# Normalize transform
	model.position = Vector3(0, 0, 0)
	model.scale = Vector3(0.2, 0.2, 0.2)
	model.rotation_degrees = Vector3(0, 0, 0)

func _process(delta):
	if model:
		time_passed += delta

		# LEFT ↔ RIGHT SWAY 
		var sway = sin(time_passed * 1.5) * max_angle
		model.rotation_degrees.y = 180 + sway
