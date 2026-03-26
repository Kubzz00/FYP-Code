extends Node

# ---------------- HAND DETECTOR ----------------
@onready var left_detector = $"../XROrigin3D/LeftTrackedHand/HandPoseDetector"
# @onready var right_detector = $XROrigin3D/RightTrackedHand/HandPoseDetector

# ---------------- UI ----------------
@onready var feedback_label = $"../XROrigin3D/UIFollowAnchor/FeedbackLabel3D"
@onready var progress_label = $"../XROrigin3D/UIFollowAnchor/ProgressLabel3D"
@onready var message_label = $"../XROrigin3D/UIFollowAnchor/PopupPanel3D/MessageLabel3D"

# ---------------- MODEL ROOT ----------------
@onready var lesson_hand_root = $"../XROrigin3D/ModelFollowAnchor/LessonHandRoot"

# ---------------- STATE ----------------
var current_pose := ""
var current_letter := ""
# var right_letter := ""

# Lesson System
var letters = ["A", "V", "D"]
var current_index := 0

# Timer
var hold_time := 3.0
var current_hold := 0.0

# ---------------- SETUP ----------------
func _ready() -> void:
	# Connect signals from both detectors
	left_detector.pose_started.connect(_on_pose_started)
	left_detector.pose_ended.connect(_on_pose_ended)
	# right_detector.pose_started.connect(_on_right_pose_detected)
	print("Feedback Label ref: ", feedback_label)
	
	load_current_letter()
	
# ---------------- POSE EVENTS ----------------
func _on_pose_started(pose_name: String) -> void:
	# Debug Message:
	print("Pose: ", pose_name)
	current_pose = pose_name

func _on_pose_ended(pose_name: String) -> void:
	if current_pose == pose_name:
		current_pose = ""
	
# ---------------- MAIN LOOP ----------------
func _process(delta):

	var target_letter = letters[current_index]
	var expected_pose = target_letter + " Pose"

	var detected_letter = pose_to_letter(current_pose)

	# -------- FEEDBACK --------
	if current_pose == "":
		feedback_label.text = "🤚 Show the sign"
		current_hold = 0

	elif current_pose == expected_pose:
		feedback_label.text = "✅ Correct (%s)" % detected_letter
		current_hold += delta

	else:
		feedback_label.text = "❌ Wrong (%s)" % detected_letter
		current_hold = 0

	# -------- TIMER --------
	progress_label.text = "Hold: %.1f / %.1f" % [current_hold, hold_time]

	# -------- COMPLETE --------
	if current_hold >= hold_time:
		complete_letter()
		
# ---------------- LOAD LETTER ----------------
func load_current_letter():
	var letter = letters[current_index]
	message_label.text = "Do letter: %s" % letter

# ---------------- COMPLETE ----------------
func complete_letter():
	print("Completed:", letters[current_index])

	current_hold = 0
	current_index += 1

	if current_index >= letters.size():
		message_label.text = "🎉 Finished!"
		feedback_label.text = ""
	else:
		load_current_letter()

# ---------------- POSE → LETTER ----------------
func pose_to_letter(pose_name: String) -> String:
	match pose_name:
		"A Pose": return "A"
		"B Pose": return "B"
		"C Pose": return "C"
		"D Pose": return "D"
		"E Pose": return "E"
		"F Pose": return "F"
		"G Pose": return "G"
		"H Pose": return "H"
		"I Pose": return "I"
		"K Pose": return "K"
		"L Pose": return "L"
		"M Pose": return "M"
		"N Pose": return "N"
		"O Pose": return "O"
		"P Pose": return "P"
		"Q Pose": return "Q"
		"R Pose": return "R"
		"S Pose": return "S"
		"T Pose": return "T"
		"U Pose": return "U"
		"V Pose": return "V"
		"W Pose": return "W"
		"X Pose": return "X"
		"Y Pose": return "Y"
		_:
			return ""
