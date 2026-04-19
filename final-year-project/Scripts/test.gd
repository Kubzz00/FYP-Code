extends Node

# ---------------- HAND DETECTORS ----------------
@onready var left_detector = $"../XROrigin3D/LeftTrackedHand/HandPoseDetector"
@onready var right_detector = $"../XROrigin3D/RightTrackedHand/HandPoseDetector"

# ---------------- UI ----------------
@onready var title_label: Label3D = $"../UIAnchor/TitleLabel3D"
@onready var note_label: Label3D = $"../UIAnchor/NoteLabel3D"
@onready var progress_label: Label3D = $"../UIAnchor/ProgressLabel3D"

# ---------------- FADE ----------------
@onready var fade_rect: ColorRect = $"../CanvasLayer/ColorRect"

# ---------------- STATE ----------------
var current_pose := ""
var hold_time := 0.0
var required_hold_time := 1.5
var locked := false

# ---------------- CONTROL GESTURES ----------------
# Match .tres pose name
var control_gestures := {
	"LEARN": "Point",
	"INFO": "V Pose",
	"TEST": "B Pose",
	"EXIT": "Fist"
}

# ---------------- SETUP ----------------
func _ready() -> void:
	print("Start Screen Ready")

	# UI Setup
	title_label.text = "Sign & Spell VR"
	note_label.text = "Pose with your Left Hand an Option you would like to do"
	progress_label.text = ""

	# Fade in (black → visible)
	fade_rect.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0)

	# Connect detectors
	left_detector.pose_started.connect(_on_pose_started)
	left_detector.pose_ended.connect(_on_pose_ended)
	right_detector.pose_started.connect(_on_pose_started)
	right_detector.pose_ended.connect(_on_pose_ended)

	print("Left detector: ", left_detector)
	print("Right detector: ", right_detector)

# ---------------- POSE EVENTS ----------------
func _on_pose_started(pose_name: String) -> void:
	if locked:
		return

	print("POSE STARTED: ", pose_name)

	# UPDATED: check all gestures
	for key in control_gestures:
		if pose_name == control_gestures[key]:
			current_pose = pose_name
			hold_time = 0.0
			return


func _on_pose_ended(pose_name: String) -> void:
	if pose_name == current_pose:
		current_pose = ""
		hold_time = 0.0

# ---------------- MAIN LOOP ----------------
func _process(delta: float) -> void:
	if locked:
		return

	if current_pose != "":
		handle_hold(delta)
	else:
		progress_label.text = ""

# ---------------- HOLD LOGIC ----------------
func handle_hold(delta: float) -> void:
	hold_time += delta

	progress_label.text = "Hold: %.1f / %.1f" % [hold_time, required_hold_time]

	# UPDATED COLOR FEEDBACK
	if current_pose == control_gestures["LEARN"]:
		progress_label.modulate = Color(0, 1, 0)
	elif current_pose == control_gestures["INFO"]:
		progress_label.modulate = Color(0, 0.6, 1)
	elif current_pose == control_gestures["TEST"]:
		progress_label.modulate = Color(0.7, 0, 1)
	elif current_pose == control_gestures["EXIT"]:
		progress_label.modulate = Color(1, 0, 0)

	# Trigger
	if hold_time >= required_hold_time:
		trigger_action(current_pose)

# ---------------- ACTION HANDLING ----------------
func trigger_action(pose_name: String) -> void:
	locked = true
	progress_label.text = ""

	if pose_name == control_gestures["LEARN"]:
		note_label.text = "Opening Learning..."
		fade_and_change_scene("res://Scenes/LearningScene/LearningScene.tscn")

	elif pose_name == control_gestures["INFO"]:
		note_label.text = "Opening Info..."
		fade_and_change_scene("res://Scenes/InfoScene.tscn")

	elif pose_name == control_gestures["TEST"]:
		note_label.text = "Starting Test..."
		fade_and_change_scene("res://Scenes/Test.tscn")

	elif pose_name == control_gestures["EXIT"]:
		note_label.text = "Exiting..."
		fade_and_exit()
		
# ---------------- TRANSITIONS ----------------
func fade_and_change_scene(scene_path: String) -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.5)
	await tween.finished
	get_tree().change_scene_to_file(scene_path)


func fade_and_exit() -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.5)
	await tween.finished
	get_tree().quit()
