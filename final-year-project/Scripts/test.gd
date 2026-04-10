extends Node

# ---------------- HAND DETECTOR ----------------
@onready var left_detector = $"../XROrigin3D/LeftTrackedHand/HandPoseDetector"

# ---------------- PANELS ----------------
@onready var learn_panel = $"../UIAnchor/Panels/LearnPanel"
@onready var info_panel = $"../UIAnchor/Panels/InfoPanel"
@onready var test_panel = $"../UIAnchor/Panels/TestPanel"
@onready var exit_panel = $"../UIAnchor/Panels/ExitPanel"

# ---------------- UI ----------------
@onready var title_label: Label3D = $"../UIAnchor/TitleLabel3D"
@onready var note_label: Label3D = $"../UIAnchor/NoteLabel3D"
@onready var progress_label: Label3D = $"../UIAnchor/ProgressLabel3D"

# ---------------- FADE ----------------
@onready var fade_rect: ColorRect = $"../CanvasLayer/ColorRect"

# ---------------- STATE ----------------
var left_pose := ""
var hold_time := 0.0
var required_hold := 1.2
var current_action := ""
var locked := false

# ---------------- GESTURES ----------------
var gestures := {
	"LEARN": "ThumbsUp",
	"INFO": "Point",
	"TEST": "Metal",
	"EXIT": "Fist"
}

# ---------------- SETUP ----------------
func _ready():
	print("Start Screen Ready")

	title_label.text = "Sign & Spell VR"
	note_label.text = "Use LEFT hand to select"
	progress_label.text = ""

	# Fade in
	fade_rect.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0)

	await get_tree().process_frame

	left_detector.pose_started.connect(_on_pose_started)
	left_detector.pose_ended.connect(_on_pose_ended)

	print("Left detector: ", left_detector)


# ---------------- POSE EVENTS ----------------
func _on_pose_started(pose_name: String):
	if locked:
		return

	print("POSE:", pose_name)

	left_pose = pose_name
	hold_time = 0.0


func _on_pose_ended(pose_name: String):
	if left_pose == pose_name:
		left_pose = ""
		hold_time = 0.0


# ---------------- MAIN LOOP ----------------
func _process(delta):
	if locked:
		return

	detect_action(delta)


# ---------------- DETECTION ----------------
func detect_action(delta):
	var action := ""

	if left_pose == gestures["LEARN"]:
		action = "LEARN"
	elif left_pose == gestures["INFO"]:
		action = "INFO"
	elif left_pose == gestures["TEST"]:
		action = "TEST"
	elif left_pose == gestures["EXIT"]:
		action = "EXIT"

	update_highlight(action)

	if action == "":
		reset_hold()
		return

	if action != current_action:
		current_action = action
		hold_time = 0.0

	hold_time += delta

	progress_label.text = "%s %.1f / %.1f" % [action, hold_time, required_hold]

	if hold_time >= required_hold:
		trigger_action(action)


# ---------------- HIGHLIGHT ----------------
func update_highlight(action):
	reset_panel(learn_panel)
	reset_panel(info_panel)
	reset_panel(test_panel)
	reset_panel(exit_panel)

	match action:
		"LEARN":
			highlight_panel(learn_panel)
		"INFO":
			highlight_panel(info_panel)
		"TEST":
			highlight_panel(test_panel)
		"EXIT":
			highlight_panel(exit_panel)


func highlight_panel(panel):
	panel.scale = Vector3(1.2, 1.2, 1.2)


func reset_panel(panel):
	panel.scale = Vector3(1, 1, 1)


# ---------------- RESET ----------------
func reset_hold():
	current_action = ""
	hold_time = 0.0
	progress_label.text = ""


# ---------------- ACTION ----------------
func trigger_action(action):
	locked = true

	match action:
		"LEARN":
			note_label.text = "Starting Learning..."
			fade_to("res://Scenes/LearningScene/LearningScene.tscn")

		"INFO":
			note_label.text = "Opening Info..."
			fade_to("res://Scenes/MenuScenes/InfoScene.tscn")

		"TEST":
			note_label.text = "Starting Test..."
			fade_to("res://Scenes/TestScene/Test.tscn")

		"EXIT":
			note_label.text = "Exiting..."
			fade_exit()


# ---------------- TRANSITIONS ----------------
func fade_to(path):
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.5)
	await tween.finished
	get_tree().change_scene_to_file(path)


func fade_exit():
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.5)
	await tween.finished
	get_tree().quit()
