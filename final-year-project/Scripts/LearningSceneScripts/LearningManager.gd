extends Node

var current_model: Node3D = null
var timer: float = 0.0
var max_time: float = 3.0
var gesture_completed: bool = false

@onready var message_label: Label3D = $"../UIFollowAnchor/PopupPanel3D/MessageLabel3D"
@onready var feedback_label: Label3D = $"../UIFollowAnchor/FeedbackLabel3D"
@onready var progress_label: Label3D = $"../UIFollowAnchor/ProgressLabel3D"

# Feedback and Timer scripts
@onready var feedback_script: Node = $"sign_feedback"  # Reference to SignFeedback script
@onready var timer_script: Node = $"timer_handler"    # Reference to Timer script

# The anchor where models will be placed
@onready var lesson_hand_root: Node3D = $"../XROrigin3D/ModelFollowAnchor/LessonHandRoot"  # The model anchor

# The gesture/letter model path (e.g., "A", "B", etc.)
var target_gesture = "A"  # Default to letter "A"

func _ready():
	spawn_hand_model(target_gesture)  # Spawn the model for the current gesture (in this case "A")
	feedback_script.update_feedback(feedback_script.FeedbackState.WAITING)  # Set initial feedback state
	timer_script.start_timer()  # Start the timer for the gesture hold

# Spawn the 3D model for the hand gesture (e.g., "A")
func spawn_hand_model(letter: String) -> void:
	if current_model != null:
		current_model.queue_free()  # Remove the previous model if any
	
	var model_scene: PackedScene = load("res://Scenes/LearningScene/HandModel.tscn")  # The base model scene
	
	if model_scene == null:
		push_error("Hand model scene not found")
		return
	
	current_model = model_scene.instantiate()  # Create the model instance
	lesson_hand_root.add_child(current_model)  # Attach it to the root node
	
	update_hand_for_letter(letter)  # Dynamically update the model for the letter (A, B, C, etc.)

# Update the hand model to match the letter (A, B, C, etc.)
func update_hand_for_letter(letter: String) -> void:
	var mesh_instance = current_model.get_node("MeshInstance3D")  # Assuming this node exists
	
	if mesh_instance:
		var mesh_path = "res://OBJ Files/Hand_" + letter + ".obj"  # Load the correct mesh
		var mesh = load(mesh_path)  # Load the mesh
		mesh_instance.mesh = mesh  # Set the new mesh

	# Position, rotate, and scale the model
	current_model.position = Vector3.ZERO
	current_model.rotation_degrees = Vector3(0, 180, 0)  # Rotate the model to face the user properly
	current_model.scale = Vector3(0.2, 0.2, 0.2)  # Adjust size (you can scale it as needed)

# Called every frame to update the timer
func _process(delta: float) -> void:
	if gesture_completed:
		return  # Skip if the gesture is already completed
	
	timer += delta  # Increment the timer
	progress_label.text = "Hold: %.1f / %.1f" % [timer, max_time]  # Update the progress label with the timer

	# Check if the user has held the gesture long enough
	if timer >= max_time:
		on_gesture_completed()  # Trigger completion

# Trigger when the gesture is successfully completed
func on_gesture_completed() -> void:
	gesture_completed = true
	feedback_script.update_feedback(feedback_script.FeedbackState.CORRECT)  # Show correct feedback
	timer = 0.0  # Reset timer for the next gesture
	await get_tree().create_timer(2.0).timeout  # Wait for 2 seconds
	feedback_script.update_feedback(feedback_script.FeedbackState.WAITING)  # Reset feedback to "Waiting"
