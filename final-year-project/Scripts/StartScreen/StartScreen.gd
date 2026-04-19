extends Node

# ---------------- HAND DETECTORS (GLOBAL) ----------------
@onready var left_detector = get_node("/root/MainXrScene/XROrigin3D/LeftTrackedHand/HandPoseDetector")
@onready var right_detector = get_node("/root/MainXrScene/XROrigin3D/RightTrackedHand/HandPoseDetector")

# ---------------- UI ----------------
@onready var title_label: Label3D = $UIAnchor/TitleLabel3D
@onready var note_label: Label3D = $UIAnchor/NoteLabel3D
@onready var progress_label: Label3D = $UIAnchor/ProgressLabel3D

# ---------------- FADE ----------------
@onready var fade_rect: ColorRect = $CanvasLayer/ColorRect

# ---------------- STATE ----------------
var current_pose := ""
var hold_time := 0.0
var required_hold_time := 1.5
var locked := false
var waiting_for_release := true

# ---------------- CONTROL GESTURES ----------------
var control_gestures := {
	"LEARN": "D Pose",
	"INFO": "Y Pose",
	"TEST": "V Pose",
	"EXIT": "A Pose"
}

# =========================================================
# READY
# =========================================================
func _ready() -> void:
	print("Start Screen Ready")

	title_label.text = "Sign & Spell VR"
	note_label.text = "Pose with your Left Hand an Option you would like to do"
	progress_label.text = ""

	# Fade in
	fade_rect.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0)

	# Connect signals (safe connect)
	if not left_detector.pose_started.is_connected(_on_pose_started):
		left_detector.pose_started.connect(_on_pose_started)
	if not left_detector.pose_ended.is_connected(_on_pose_ended):
		left_detector.pose_ended.connect(_on_pose_ended)

	if not right_detector.pose_started.is_connected(_on_pose_started):
		right_detector.pose_started.connect(_on_pose_started)
	if not right_detector.pose_ended.is_connected(_on_pose_ended):
		right_detector.pose_ended.connect(_on_pose_ended)

# =========================================================
# RESET WHEN ENTERING SCREEN
# =========================================================
func on_enter():
	current_pose = ""
	hold_time = 0.0
	locked = false
	progress_label.text = ""
	waiting_for_release = true

# =========================================================
# POSE EVENTS
# =========================================================
func _on_pose_started(pose_name: String) -> void:
	if locked:
		return
		
	if waiting_for_release:
		return

	# prevent stale pose from previous screen
	if current_pose != "":
		return

	for key in control_gestures:
		if pose_name == control_gestures[key]:
			current_pose = pose_name
			hold_time = 0.0
			return


func _on_pose_ended(pose_name: String) -> void:
	if pose_name == current_pose:
		current_pose = ""
		hold_time = 0.0

# =========================================================
# MAIN LOOP
# =========================================================
func _process(delta: float) -> void:
	if locked:
		return

	if waiting_for_release:
		if current_pose == "":
			waiting_for_release = false
		return

	if current_pose != "":
		handle_hold(delta)
	else:
		progress_label.text = ""

# =========================================================
# HOLD LOGIC
# =========================================================
func handle_hold(delta: float) -> void:
	hold_time += delta

	progress_label.text = "Hold: %.1f / %.1f" % [hold_time, required_hold_time]

	if current_pose == control_gestures["LEARN"]:
		progress_label.modulate = Color(0, 1, 0)
	elif current_pose == control_gestures["INFO"]:
		progress_label.modulate = Color(0, 0.6, 1)
	elif current_pose == control_gestures["TEST"]:
		progress_label.modulate = Color(0.7, 0, 1)
	elif current_pose == control_gestures["EXIT"]:
		progress_label.modulate = Color(1, 0, 0)

	if hold_time >= required_hold_time:
		trigger_action(current_pose)

# =========================================================
# ACTIONS 
# =========================================================
func trigger_action(pose_name: String) -> void:
	locked = true
	progress_label.text = ""

	var manager = get_parent()

	if pose_name == control_gestures["LEARN"]:
		note_label.text = "Opening Learning..."
		await fade_out()
		manager.show_learning()

	elif pose_name == control_gestures["INFO"]:
		note_label.text = "Opening Info..."
		await fade_out()

	elif pose_name == control_gestures["TEST"]:
		note_label.text = "Starting Test..."
		await fade_out()
		manager.show_test()

	elif pose_name == control_gestures["EXIT"]:
		note_label.text = "Exiting..."
		await fade_out()
		get_tree().quit()

# =========================================================
# FADE
# =========================================================
func fade_out() -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.4)
	await tween.finished
