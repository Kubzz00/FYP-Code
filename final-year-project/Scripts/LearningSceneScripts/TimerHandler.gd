extends Node

var timer: float = 0.0
var max_time: float = 3.0
var gesture_completed: bool = false

@onready var progress_label: Label3D = $"../XROrigin3D/UIFollowAnchor/ProgressLabel3D"

func _ready():
	start_timer()  # Start the timer

# Call this function to start the timer
func start_timer() -> void:
	timer = 0.0  # Reset timer
	gesture_completed = false  # Reset completion state
	progress_label.text = "Hold: %.1f / %.1f" % [timer, max_time]

# Called every frame to update the timer
func _process(delta: float) -> void:
	if gesture_completed:
		return  # Skip if the gesture is already completed
	
	timer += delta  # Increment the timer
	progress_label.text = "Hold: %.1f / %.1f" % [timer, max_time]  # Update the progress label

	# Check if the user has held the gesture long enough
	if timer >= max_time:
		on_gesture_completed()  # Trigger completion

# Trigger when the gesture is successfully completed
func on_gesture_completed() -> void:
	gesture_completed = true
	feedback_script.update_feedback(feedback_script.FeedbackState.CORRECT)  # Show correct feedback
	# Other actions like next letter or reset can be handled here
