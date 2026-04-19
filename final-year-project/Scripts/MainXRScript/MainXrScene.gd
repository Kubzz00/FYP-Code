extends Node

# ---------------- UI SCREENS ----------------
@onready var start_ui = $StartScreen
@onready var test_ui = $TestScene
@onready var learning_ui = $LearningScene

# =========================================================
# READY
# =========================================================
func _ready():
	show_start()

# =========================================================
# SCREEN SWITCHING
# =========================================================
func show_start():
	start_ui.visible = true
	test_ui.visible = false
	learning_ui.visible = false
	
	start_ui.on_enter()

func show_test():
	start_ui.visible = false
	test_ui.visible = true
	learning_ui.visible = false

func show_learning():
	start_ui.visible = false
	test_ui.visible = false
	learning_ui.visible = true
