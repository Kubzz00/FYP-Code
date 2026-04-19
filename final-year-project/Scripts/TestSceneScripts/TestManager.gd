extends Node

# ---------------- HAND DETECTORS (GLOBAL) ----------------
@onready var left_detector = get_node("/root/MainXrScene/XROrigin3D/LeftTrackedHand/HandPoseDetector")
@onready var right_detector = get_node("/root/MainXrScene/XROrigin3D/RightTrackedHand/HandPoseDetector")

# ---------------- UI ----------------
@onready var instruction_label: Label3D = $UIAnchor/InstructionLabel3D
@onready var progress_label: Label3D = $UIAnchor/ProgressLabel3D
@onready var timer_label: Label3D = $UIAnchor/TimerLabel3D
@onready var score_label: Label3D = $UIAnchor/ScoreLabel3D
@onready var exit_label: Label3D = $UIAnchor/ExitLabel3D

# ---------------- DATA ----------------
const LETTER_DATA = preload("res://Scripts/LearningSceneScripts/LetterData.gd").LETTER_DATA

var selected_keys: Array = []
var current_index := 0
var score := 0

# ---------------- TEST STATE ----------------
var current_target_pose := ""
var current_detected_pose := ""
var active_pose := ""

var hold_time := 0.0
var required_hold_time := 3.0

var locked := false
var waiting_for_input := true

# ---------------- END STATE ----------------
var test_finished := false

# ---------------- RIGHT HAND ----------------
var right_pose := ""

# ---------------- EXIT SYSTEM ----------------
var exit_active := false
var exit_hold_time := 0.0
var exit_required_hold := 3.0

# ---------------- RESTART SYSTEM ----------------
var restart_active := false
var restart_hold_time := 0.0
var restart_required_hold := 3.0

# =========================================================
# READY
# =========================================================
func _ready():
	score_label.visible = false
	exit_label.visible = true

	# Safe connect (no duplicates)
	if not left_detector.pose_started.is_connected(_on_left_pose_detected):
		left_detector.pose_started.connect(_on_left_pose_detected)

	if not right_detector.pose_started.is_connected(_on_right_pose_detected):
		right_detector.pose_started.connect(_on_right_pose_detected)

	start_test()

# =========================================================
# RESET WHEN ENTERING SCREEN
# =========================================================
func on_enter():
	current_detected_pose = ""
	active_pose = ""
	waiting_for_input = true
	right_pose = ""
	hold_time = 0
	locked = false
	test_finished = false
	score_label.visible = false

	start_test()

# =========================================================
# START TEST
# =========================================================
func start_test():
	var keys = LETTER_DATA.keys()
	keys.shuffle()

	selected_keys = keys
	current_index = 0
	score = 0
	test_finished = false

	show_next_letter()

# =========================================================
# SHOW NEXT LETTER
# =========================================================
func show_next_letter():
	if current_index >= selected_keys.size():
		end_test()
		return

	var key = selected_keys[current_index]
	var letter_data = LETTER_DATA[key]

	instruction_label.text = "Can you show " + key
	progress_label.text = str(current_index + 1) + " / " + str(selected_keys.size())
	timer_label.text = "Hold: 0.0s"

	current_target_pose = letter_data["pose"]

	current_detected_pose = ""
	active_pose = ""
	hold_time = 0
	locked = false
	waiting_for_input = true

# =========================================================
# LEFT HAND DETECTION
# =========================================================
func _on_left_pose_detected(pose_name: String):
	# prevent stale pose carryover
	if current_detected_pose != "":
		return

	current_detected_pose = pose_name

# =========================================================
# RIGHT HAND DETECTION
# =========================================================
func _on_right_pose_detected(pose_name: String):
	right_pose = pose_name

# =========================================================
# MAIN LOOP
# =========================================================
func _process(delta):

	# GLOBAL EXIT
	if right_pose == "Fist":
		handle_exit(delta)
		return
	else:
		exit_active = false
		exit_hold_time = 0

	# END STATE
	if test_finished:
		handle_restart(delta)
		return

	# TEST STATE
	if locked:
		return

	# no pose
	if current_detected_pose == "":
		active_pose = ""
		waiting_for_input = true
		hold_time = 0
		timer_label.text = "Hold: 0.0s"
		return

	# new input
	if waiting_for_input:
		active_pose = current_detected_pose
		waiting_for_input = false
		hold_time = 0
		return

	# hold same pose
	if current_detected_pose == active_pose:
		hold_time += delta
		timer_label.text = "Hold: %.1f s" % hold_time

		if hold_time >= required_hold_time:
			evaluate_answer()
	else:
		active_pose = ""
		waiting_for_input = true
		hold_time = 0
		timer_label.text = "Hold: 0.0s"

# =========================================================
# EVALUATE
# =========================================================
func evaluate_answer():
	locked = true

	if active_pose == current_target_pose:
		score += 1
	else:
		print("Wrong")

	await get_tree().create_timer(0.6).timeout
	next_question()

# =========================================================
# NEXT
# =========================================================
func next_question():
	current_index += 1
	show_next_letter()

# =========================================================
# END TEST
# =========================================================
func end_test():
	instruction_label.text = "Test Complete\n\n👉 Point to Restart\n✊ Fist to Exit"
	progress_label.text = ""
	timer_label.text = ""

	score_label.visible = true
	score_label.text = "Score: " + str(score) + " / " + str(selected_keys.size())

	test_finished = true

# =========================================================
# EXIT
# =========================================================
func handle_exit(delta):
	if not exit_active:
		exit_active = true
		exit_hold_time = 0
		return

	exit_hold_time += delta
	timer_label.text = "Exit Hold: %.1f s" % exit_hold_time

	if exit_hold_time >= exit_required_hold:
		go_to_menu()

# =========================================================
# RESTART
# =========================================================
func handle_restart(delta):

	if right_pose != "Point":
		restart_active = false
		restart_hold_time = 0
		return

	if not restart_active:
		restart_active = true
		restart_hold_time = 0
		return

	restart_hold_time += delta

	if restart_hold_time >= restart_required_hold:
		restart_test()

# =========================================================
# ACTIONS
# =========================================================
func restart_test():
	score_label.visible = false
	start_test()

func go_to_menu():
	var manager = get_parent()
	manager.show_start()
