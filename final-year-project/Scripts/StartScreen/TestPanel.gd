extends Node3D

@onready var holder = $ModelHolder

var model_scene = preload("res://Scenes/StartScreenScene/PeaceModel.tscn")

var model = null

func _ready():
	spawn_model()

func spawn_model():
	model = model_scene.instantiate()
	holder.add_child(model)

	# Normalize transform
	model.position = Vector3(0, 0, 0)
	model.scale = Vector3(0.2, 0.2, 0.2)
	model.rotation_degrees = Vector3(0, 180, 0)

func _process(delta):
	# subtle rotation so it looks alive
	if model:
		model.rotation.y += delta * 0.5
