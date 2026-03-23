extends Node3D

@export var follow_speed: float = 3.0
@export var follow_distance: float = 1.0
@export var vertical_offset: float = 0.00

@onready var xr_camera: XRCamera3D = $"../XRCamera3D"

func _process(delta: float) -> void:
	# Check if camera not found, do nothing
	if xr_camera == null:
		return
	
	# Get camera transform
	var cam_transform := xr_camera.global_transform
	
	# Calculate Position
	var target_position: Vector3 = cam_transform.origin 
	+ (-cam_transform.basis.z * follow_distance) 
	+ (Vector3.UP * vertical_offset)

	# Smooth movement
	global_position = global_position.lerp(target_position, delta * follow_speed)
	
	# Always face the user
	look_at(cam_transform.origin, Vector3.UP)
