extends Node

@onready var feedback_label: Label3D = $"../XROrigin3D/UIFollowAnchor/FeedbackLabel3D"  # Feedback label

enum FeedbackState { WAITING, CLOSE, CORRECT, INCORRECT }
var feedback_state: FeedbackState = FeedbackState.WAITING

# Call this to update feedback
func update_feedback(state: FeedbackState) -> void:
	feedback_state = state

	match feedback_state:
		FeedbackState.WAITING:
			feedback_label.text = "Waiting..."
			feedback_label.modulate = Color(1, 1, 1)  # White (Neutral)
		FeedbackState.CLOSE:
			feedback_label.text = "Close Enough!"
			feedback_label.modulate = Color(1, 1, 0)  # Yellow
		FeedbackState.CORRECT:
			feedback_label.text = "Good Job!"
			feedback_label.modulate = Color(0, 1, 0)  # Green
		FeedbackState.INCORRECT:
			feedback_label.text = "Try Again!"
			feedback_label.modulate = Color(1, 0, 0)  # Red
