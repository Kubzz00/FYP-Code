extends Node

const LetterData = preload("res://Scripts/LearningSceneScripts/LetterData.gd")

# ---------------- HAND DETECTORS ----------------
@onready var left_detector = get_node("/root/MainXrScene/XROrigin3D/LeftTrackedHand/HandPoseDetector")
@onready var right_detector = get_node("/root/MainXrScene/XROrigin3D/RightTrackedHand/HandPoseDetector")

# ---------------- UI ----------------
@onready var feedback_label: Label3D = $UIFollowAnchor/FeedbackLabel3D
@onready var progress_label: Label3D = $UIFollowAnchor/ProgressLabel3D
@onready var message_label: Label3D = $UIFollowAnchor/PopupPanel3D/MessageLabel3D
@onready var exit_label: Label3D = $UIFollowAnchor/ExitLabel3D

# ---------------- MODEL ROOT ----------------
@onready var lesson_hand_root: Node3D = $ModelFollowAnchor/LessonHandRoot

# ---------------- STATE ----------------
var left_pose := ""
var right_pose := ""
var current_model: Node3D = null

# ---------------- EXIT SYSTEM ---------------- 
var exit_active := false
var exit_hold_time := 0.0
var exit_required_hold := 2.0


enum LessonState {
	INTRO,
	SIGNING,
	SUCCESS,
	WAIT_FOR_THUMBS_UP,
	FINISHED
}

var lesson_state: int = LessonState.INTRO

# ---------------- LESSON ORDER ----------------
var letters := ["A", "B", "D", "V", "H"]
var current_index := 0

# ---------------- TIMERS ----------------
var hold_time := 3.0
var current_hold := 0.0

var thumbs_up_hold_time := 1.0
var thumbs_up_hold := 0.0

# ---------------- TYPEWRITER ----------------
var is_typing := false
var typing_speed := 0.03
var typing_request_id := 0

# ---------------- CONTROL GESTURES ----------------
# Change this if your detector prints a different exact pose name.
var control_gestures := {
	"NEXT": "ThumbsUp"
}

# ---------------- SETUP ----------------
func _ready() -> void:
	left_detector.pose_started.connect(_on_left_pose_started)
	left_detector.pose_ended.connect(_on_left_pose_ended)

	right_detector.pose_started.connect(_on_right_pose_started)
	right_detector.pose_ended.connect(_on_right_pose_ended)
	
	exit_label.text = "Hold Fist on right hand to Exit"

	print("Left detector ref: ", left_detector)
	print("Right detector ref: ", right_detector)
	print("Message label ref: ", message_label)
	print("Feedback label ref: ", feedback_label)
	print("Progress label ref: ", progress_label)
	print("Lesson hand root ref: ", lesson_hand_root)

	load_current_letter()

# ---------------- POSE EVENTS ----------------
func _on_left_pose_started(pose_name: String) -> void:
	print("LEFT DETECTED: ", pose_name)
	left_pose = pose_name

func _on_left_pose_ended(pose_name: String) -> void:
	if left_pose == pose_name:
		left_pose = ""

func _on_right_pose_started(pose_name: String) -> void:
	print("RIGHT DETECTED: ", pose_name)
	right_pose = pose_name

func _on_right_pose_ended(pose_name: String) -> void:
	if right_pose == pose_name:
		right_pose = ""

# ---------------- MAIN LOOP ----------------
func _process(delta: float) -> void:
	
	# EXIT SYSTEM (ADDED)
	if right_pose == "Fist":
		handle_exit(delta)
		return
	else:
		exit_active = false
		exit_hold_time = 0

	if current_index >= letters.size():
		return

	var target_letter: String = letters[current_index]
	var expected_left_pose: String = LetterData.LETTER_DATA[target_letter]["pose"]
	var expected_right_pose: String = control_gestures["NEXT"]

	match lesson_state:
		LessonState.INTRO:
			feedback_label.text = "Read and copy the sign"
			progress_label.text = ""
			if not is_typing:
				lesson_state = LessonState.SIGNING

		LessonState.SIGNING:
			handle_signing_state(delta, expected_left_pose)

		LessonState.SUCCESS:
			feedback_label.text = "✅ Correct"
			progress_label.text = ""
			if not is_typing:
				lesson_state = LessonState.WAIT_FOR_THUMBS_UP
				thumbs_up_hold = 0.0

		LessonState.WAIT_FOR_THUMBS_UP:
			handle_thumbs_up_state(delta, expected_right_pose)

		LessonState.FINISHED:
			feedback_label.text = ""
			progress_label.text = ""
			
# ---------------- EXIT LOGIC ----------------
func handle_exit(delta):
	if not exit_active:
		exit_active = true
		exit_hold_time = 0
		return

	exit_hold_time += delta
	progress_label.text = "Exit: %.1f / %.1f" % [exit_hold_time, exit_required_hold]

	if exit_hold_time >= exit_required_hold:
		go_to_menu()

func go_to_menu():
	get_parent().show_start()

# ---------------- SIGNING STATE ----------------
func handle_signing_state(delta: float, expected_left_pose: String) -> void:
	var detected_letter := pose_to_letter(left_pose)

	if left_pose == "":
		feedback_label.text = "🤚 Show the sign"
		current_hold = 0.0

	elif left_pose == expected_left_pose:
		feedback_label.text = "✅ Correct (%s)" % detected_letter
		current_hold += delta

	else:
		feedback_label.text = "❌ Wrong (%s)" % detected_letter
		current_hold = 0.0

	progress_label.text = "Hold: %.1f / %.1f" % [current_hold, hold_time]

	if current_hold >= hold_time:
		on_letter_completed()

# ---------------- THUMBS UP STATE ----------------
func handle_thumbs_up_state(delta: float, expected_right_pose: String) -> void:
	if right_pose == "":
		feedback_label.text = "👍 Show thumbs up\nwith right hand"
		thumbs_up_hold = 0.0

	elif right_pose == expected_right_pose:
		feedback_label.text = "✅ Thumbs up detected"
		thumbs_up_hold += delta

	else:
		feedback_label.text = "❌ Use right-hand thumbs up"
		thumbs_up_hold = 0.0

	progress_label.text = "Next: %.1f / %.1f" % [thumbs_up_hold, thumbs_up_hold_time]

	if thumbs_up_hold >= thumbs_up_hold_time:
		move_to_next_letter()

# ---------------- LOAD LETTER ----------------
func load_current_letter() -> void:
	if current_index >= letters.size():
		finish_lesson()
		return

	var letter: String = letters[current_index]

	current_hold = 0.0
	thumbs_up_hold = 0.0
	left_pose = ""
	right_pose = ""

	spawn_model(letter)

	var intro_text: String = LetterData.LETTER_DATA[letter]["instruction"]

	lesson_state = LessonState.INTRO
	type_text(intro_text)

# ---------------- LETTER COMPLETE ----------------
func on_letter_completed() -> void:
	current_hold = 0.0
	var letter: String = letters[current_index]

	lesson_state = LessonState.SUCCESS
	type_text("Well done, you signed %s.\nOn your right hand, give a thumbs up to move onto the next letter." % letter)

# ---------------- NEXT LETTER ----------------
func move_to_next_letter() -> void:
	current_index += 1

	if current_index >= letters.size():
		finish_lesson()
	else:
		load_current_letter()

# ---------------- FINISH ----------------
func finish_lesson() -> void:
	lesson_state = LessonState.FINISHED
	type_text("Excellent work. You finished the lesson.")
	feedback_label.text = ""
	progress_label.text = ""

# ---------------- TYPEWRITER EFFECT ----------------
func type_text(full_text: String) -> void:
	typing_request_id += 1
	var my_request := typing_request_id
	is_typing = true
	message_label.text = ""

	_run_type_text(full_text, my_request)

func _run_type_text(full_text: String, request_id: int) -> void:
	for i in range(full_text.length()):
		if request_id != typing_request_id:
			return

		message_label.text = full_text.substr(0, i + 1)
		await get_tree().create_timer(typing_speed).timeout

	if request_id == typing_request_id:
		is_typing = false

# ---------------- MODEL SPAWN ----------------
func spawn_model(letter: String) -> void:
	if current_model != null:
		current_model.queue_free()
		current_model = null

	var scene: PackedScene = load("res://Scenes/LearningScene/HandModel.tscn")
	if scene == null:
		push_error("HandModel.tscn not found")
		return

	current_model = scene.instantiate()
	lesson_hand_root.add_child(current_model)

	var mesh_instance: MeshInstance3D = current_model.get_node_or_null("Model")
	if mesh_instance == null:
		push_error("Model node not found inside HandModel.tscn")
		return

	var mesh_path: String = LetterData.LETTER_DATA[letter]["model"]
	var mesh: Resource = load(mesh_path)

	if mesh == null:
		push_error("Mesh failed to load: " + mesh_path)
		return

	mesh_instance.mesh = mesh as Mesh

	current_model.position = Vector3.ZERO
	current_model.rotation_degrees = Vector3(0, 180, 0)
	current_model.scale = Vector3(0.2, 0.2, 0.2)

	print("Spawned model for letter: ", letter)

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
