extends Node

const LetterData = preload("res://Scripts/LearningSceneScripts/LetterData.gd")

# ---------------- HAND DETECTORS ----------------
@onready var left_detector = $"../XROrigin3D/LeftTrackedHand/HandPoseDetector"
@onready var right_detector = $"../XROrigin3D/RightTrackedHand/HandPoseDetector"

# ---------------- UI ----------------
@onready var feedback_label: Label3D = $"../XROrigin3D/UIFollowAnchor/FeedbackLabel3D"
@onready var progress_label: Label3D = $"../XROrigin3D/UIFollowAnchor/ProgressLabel3D"
@onready var message_label: Label3D = $"../XROrigin3D/UIFollowAnchor/PopupPanel3D/MessageLabel3D"

# ---------------- MODEL ROOT ----------------
@onready var lesson_hand_root: Node3D = $"../XROrigin3D/ModelFollowAnchor/LessonHandRoot"

# ---------------- STATE ----------------
var left_pose := ""
var right_pose := ""
var current_model: Node3D = null

enum LessonState {
	INTRO,
	SIGNING,
	SUCCESS,
	WAIT_FOR_THUMBS_UP,
	FINISHED,
	RETURN_TO_MENU
}

var lesson_state: int = LessonState.INTRO

# ---------------- LESSON ORDER ----------------
var letters := ["A", "V", "D"]
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
var control_gestures := {
	"NEXT": "ThumbsUp"
}

# ---------------- SETUP ----------------
func _ready() -> void:
	left_detector.pose_started.connect(_on_left_pose_started)
	left_detector.pose_ended.connect(_on_left_pose_ended)

	right_detector.pose_started.connect(_on_right_pose_started)
	right_detector.pose_ended.connect(_on_right_pose_ended)

	load_current_letter()

# ---------------- POSE EVENTS ----------------
func _on_left_pose_started(pose_name: String) -> void:
	left_pose = pose_name

func _on_left_pose_ended(pose_name: String) -> void:
	if left_pose == pose_name:
		left_pose = ""

func _on_right_pose_started(pose_name: String) -> void:
	right_pose = pose_name

func _on_right_pose_ended(pose_name: String) -> void:
	if right_pose == pose_name:
		right_pose = ""

# ---------------- MAIN LOOP ----------------
func _process(delta: float) -> void:
	if current_index >= letters.size() and lesson_state != LessonState.RETURN_TO_MENU:
		return

	var target_letter: String = ""
	var expected_left_pose: String = ""
	var expected_right_pose: String = control_gestures["NEXT"]

	if current_index < letters.size():
		target_letter = letters[current_index]
		expected_left_pose = LetterData.LETTER_DATA[target_letter]["pose"]

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

		LessonState.RETURN_TO_MENU:
			handle_return_to_menu(delta, expected_right_pose)

		LessonState.FINISHED:
			feedback_label.text = ""
			progress_label.text = ""

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

# ---------------- RETURN TO MENU ----------------
func handle_return_to_menu(delta: float, expected_right_pose: String) -> void:
	if right_pose == "":
		feedback_label.text = "👍 Show thumbs up to return"
		thumbs_up_hold = 0.0

	elif right_pose == expected_right_pose:
		feedback_label.text = "✅ Returning..."
		thumbs_up_hold += delta

	else:
		feedback_label.text = "❌ Use right-hand thumbs up"
		thumbs_up_hold = 0.0

	progress_label.text = "Return: %.1f / %.1f" % [thumbs_up_hold, thumbs_up_hold_time]

	if thumbs_up_hold >= thumbs_up_hold_time:
		await get_tree().create_timer(0.3).timeout
		get_tree().change_scene_to_file("res://Scenes/main.tscn")

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
	type_text("Well done, you signed %s.\nGive a thumbs up to continue." % letter)

# ---------------- NEXT LETTER ----------------
func move_to_next_letter() -> void:
	current_index += 1

	if current_index >= letters.size():
		finish_lesson()
	else:
		load_current_letter()

# ---------------- FINISH ----------------
func finish_lesson() -> void:
	lesson_state = LessonState.RETURN_TO_MENU
	thumbs_up_hold = 0.0

	type_text("Excellent work.\nGive a thumbs up to return to the menu.")

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
		push_error("Model node not found")
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

# ---------------- POSE → LETTER ----------------
func pose_to_letter(pose_name: String) -> String:
	match pose_name:
		"A Pose": return "A"
		"B Pose": return "B"
		"C Pose": return "C"
		"D Pose": return "D"
		"V Pose": return "V"
		_:
			return ""
