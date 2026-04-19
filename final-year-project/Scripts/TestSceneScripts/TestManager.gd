extends Node

# ---------------- HAND DETECTORS ----------------
@onready var left_detector = $"../XROrigin3D/LeftTrackedHand/HandPoseDetector"

# ---------------- UI ----------------
@onready var instruction_label: Label3D = $"../UIAnchor/InstructionLabel3D"
@onready var progress_label: Label3D = $"../UIAnchor/ProgressLabel3D"
@onready var timer_label: Label3D = $"../UIAnchor/TimerLabel3D"
@onready var score_label: Label3D = $"../UIAnchor/ScoreLabel3D"

# ---------------- MODEL ----------------
@onready var model_root: Node3D = $"../ModelAnchor/HandModelRoot"

# ---------------- DATA ----------------
const LETTER_DATA = preload("res://Scripts/LearningSceneScripts/LetterData.gd").LETTER_DATA

var selected_keys: Array = []
var current_index := 0
var score := 0

# ---------------- STATE ----------------
var current_target_pose := ""
var current_detected_pose := ""

var hold_time := 0.0
var required_hold_time := 2.0

var locked := false

# ---------------- MODEL INSTANCE ----------------
var current_model = null

# ---------------- READY ----------------
func _ready():
	score_label.visible = false
	left_detector.pose_started.connect(_on_pose_detected)
	start_test()

# ---------------- START  ----------------
func start_test():
	var keys = LETTER_DATA.keys()
	keys.shuffle()

	selected_keys = keys

	current_index = 0
	score = 0

	show_next_letter()
	
# ---------------- SHOW NEXT LETTER ----------------
func show_next_letter():
	if current_index >= selected_keys.size():
		end_test()
		return

	var key = selected_keys[current_index]
	var letter_data = LETTER_DATA[key]

	# UI
	instruction_label.text = letter_data["test_prompt"] + " " + key
	progress_label.text = str(current_index + 1) + " / 3"
	timer_label.text = "Hold: 0.0s"

	# LOGIC
	current_target_pose = letter_data["pose"]
	hold_time = 0
	locked = false

	# USE YOUR SPAWN SYSTEM
	spawn_model(key)

# ---------------- SPAWN MODEL ----------------
func spawn_model(letter: String) -> void:
	if current_model != null:
		current_model.queue_free()
		current_model = null

	var scene: PackedScene = load("res://Scenes/LearningScene/HandModel.tscn")
	if scene == null:
		push_error("HandModel.tscn not found")
		return

	current_model = scene.instantiate()
	model_root.add_child(current_model)

	var mesh_instance: MeshInstance3D = current_model.get_node_or_null("Model")
	if mesh_instance == null:
		push_error("Model node not found inside HandModel.tscn")
		return

	var mesh_path: String = LETTER_DATA[letter]["model"]
	var mesh: Resource = load(mesh_path)

	if mesh == null:
		push_error("Mesh failed to load: " + mesh_path)
		return

	mesh_instance.mesh = mesh as Mesh

	# positioning
	current_model.position = Vector3.ZERO
	current_model.rotation_degrees = Vector3(0, 180, 0)
	current_model.scale = Vector3(0.2, 0.2, 0.2)

		
# ---------------- DETECTOR ----------------
func _on_pose_detected(pose_name: String):
	current_detected_pose = pose_name
	
# ---------------- HOLD SYSTEM ----------------
func _process(delta):
	if locked:
		return

	if current_detected_pose == current_target_pose:
		hold_time += delta
		timer_label.text = "Hold: %.1f s" % hold_time

		if hold_time >= required_hold_time:
			handle_success()
	else:
		hold_time = 0
		timer_label.text = "Hold: 0.0s"
		

# ---------------- SUCCESS ----------------
func handle_success():
	locked = true
	score += 1

	await get_tree().create_timer(0.6).timeout
	next_question()

# ---------------- NEXT QUESTION ----------------
func next_question():
	current_index += 1
	show_next_letter()

# ---------------- END ----------------
func end_test():
	# CLEAR UI
	instruction_label.text = "Test Complete"
	progress_label.text = ""
	timer_label.text = ""

	# CLEAR MODEL
	for child in model_root.get_children():
		child.queue_free()

	# SHOW SCORE (THIS IS THE IMPORTANT PART)
	score_label.visible = true
	score_label.text = "Score: " + str(score) + " / 3"
