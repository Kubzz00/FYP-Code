extends Node

# To store the current model instance
var current_model: Node3D = null

# UI Elements
@onready var message_label: Label3D = $"../XROrigin3D/UIFollowAnchor/PopupPanel3D/MessageLabel3D"
@onready var feedback_label: Label3D = $"../XROrigin3D/UIFollowAnchor/FeedbackLabel3D"
@onready var progress_label: Label3D = $"../XROrigin3D/UIFollowAnchor/ProgressLabel3D"

# The anchor where models will be placed
@onready var lesson_hand_root: Node3D = $"../XROrigin3D/ModelFollowAnchor/LessonHandRoot"  # The model anchor

# **Explicitly set the letter here**
var target_gesture = "A"  # Default to letter "A"

# Called when the scene is ready
func _ready():
	# Spawn the model for the current gesture (in this case "A")
	spawn_hand_model(target_gesture)

# Spawn the 3D model for the hand gesture (e.g., "A")
func spawn_hand_model(letter: String) -> void:
	if current_model != null:
		current_model.queue_free()  # Remove the previous model if any
	
	# Load the shared hand model scene
	var model_scene: PackedScene = load("res://Scenes/LearningScene/HandModel.tscn")  # The base model scene
	
	if model_scene == null:
		push_error("Hand model scene not found")
		return
	
	# Instantiate and attach the model
	current_model = model_scene.instantiate()
	lesson_hand_root.add_child(current_model)
	
	# Dynamically modify the model based on the letter
	update_hand_for_letter(letter)

# Update the hand model to match the letter (A, B, C, etc.)
func update_hand_for_letter(letter: String) -> void:
	# Example: Change the model's mesh or material based on the letter
	var mesh_instance = current_model.get_node("Model")  # Assuming this node exists
	
	if mesh_instance:
		var mesh_path = "res://OBJ Files/Hand_" + letter + ".obj"  # Assuming the models are named like "Hand_A.obj"
		var mesh = load(mesh_path)  # Load the correct mesh
		mesh_instance.mesh = mesh  # Set the new mesh

	current_model.position = Vector3.ZERO
	current_model.rotation_degrees = Vector3(0, 180, 0)  # Rotate the model to face the user properly
	current_model.scale = Vector3(0.2, 0.2, 0.2)  # Adjust size (you can scale it as needed)
