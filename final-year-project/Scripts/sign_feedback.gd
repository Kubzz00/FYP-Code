extends Node

# Get References to Hand Pose Detectors
@onready var left_detector = $XROrigin3D/LeftTrackedHand/HandPoseDetector
@onready var right_detector = $XROrigin3D/RightTrackedHand/HandPoseDetector

# Reference to Label3D (SignText)
@onready var sign_text = $XROrigin3D/ISLWall/SignText

var left_letter := ""
var right_letter := ""

func _ready() -> void:
	# Connect signals from both detectors
	left_detector.pose_started.connect(_on_left_pose_detected)
	right_detector.pose_started.connect(_on_right_pose_detected)
	
# Signal Handlers
func _on_left_pose_detected(pose_name: String) -> void:
	# Debug Message:
	print("Left Pose: ", pose_name)
	left_letter = pose_to_letter(pose_name)
	update_display()
	
func _on_right_pose_detected(pose_name: String) -> void:
	# Debug Message:
	print("Right Pose: ", pose_name)
	right_letter = pose_to_letter(pose_name)
	update_display()
	
# Pose -> Letter Mapping
func pose_to_letter(pose_name: String) -> String:
	# Debug message
	print("pose_to_letter() called with: ", pose_name)
	match pose_name:
		"Fist":
			return "A"
		"Peace Sign":
			return "V"
		"Point":
			return "D"
		_:
			return ""
			
# Update Text on Label
func update_display() -> void:
	sign_text.text = "Left hand = %s\nRight hand = %s" % [
		left_letter,
		right_letter
	]
