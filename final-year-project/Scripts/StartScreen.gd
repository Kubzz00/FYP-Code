'''extends Node

# Get References to Hand Pose Detectors
@onready var left_detector = $XROrigin3D/LeftTrackedHand/HandPoseDetector
@onready var right_detector = $XROrigin3D/RightTrackedHand/HandPoseDetector

func _ready() -> void:
	# Connect signals from both detectors
	left_detector.pose_started.connect(_on_left_pose_detected)
	right_detector.pose_started.connect(_on_right_pose_detected)
	
# Signal Handlers
func _on_left_pose_detected(pose_name: String) -> void:
	# Debug Message:
	print("Left Pose: ", pose_name)
	if pose_name == "ThumbsUp":
		load_main_scene()
	
func _on_right_pose_detected(pose_name: String) -> void:
	# Debug Message:
	print("Right Pose: ", pose_name)
	if pose_name == "ThumbsUp":
		load_main_scene()
	
func load_main_scene():
	print("Moving to main scene")
	var main_scene = preload("res://Scenes/SignFeedback.tscn")  # check the filename/path
	var main_instance = main_scene.instantiate()

	var tree = get_tree()
	var root = tree.root

	root.remove_child(self)
	root.add_child(main_instance)
	tree.current_scene = main_instance'''
	
extends Node

# Get References to Hand Pose Detectors
@onready var left_detector = $XROrigin3D/LeftTrackedHand/HandPoseDetector
@onready var right_detector = $XROrigin3D/RightTrackedHand/HandPoseDetector

func _ready() -> void:
	# Connect signals from both detectors (with null checks)
	if left_detector:
		left_detector.pose_started.connect(_on_left_pose_detected)
	if right_detector:
		right_detector.pose_started.connect(_on_right_pose_detected)

# Signal Handlers
func _on_left_pose_detected(pose_name: String) -> void:
	print("Left Pose: ", pose_name)
	if pose_name == "ThumbsUp":
		print("🚀 ThumbsUp detected - loading MAIN scene")
		get_tree().change_scene_to_file("res://Scenes/main.tscn")  # ← YOUR MAIN SCENE

func _on_right_pose_detected(pose_name: String) -> void:
	print("Right Pose: ", pose_name)
	if pose_name == "ThumbsUp":
		print("🚀 ThumbsUp detected - loading MAIN scene")
		get_tree().change_scene_to_file("res://Scenes/main.tscn")  # ← YOUR MAIN SCENE
