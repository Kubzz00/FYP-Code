extends Control

# Cache references to the UI nodes so we don't keep calling $... every time
@onready var name_input: LineEdit = $VBoxContainer/NameInput
@onready var start_button: Button = $VBoxContainer/StartButton

func _ready():
	# This runs when the scene is loaded.
	# Here we connect the button's "pressed" signal to our own function.
	start_button.pressed.connect(_on_start_pressed)


func _on_start_pressed():
	# This function runs when the Start / Calibrate button is clicked.

	# Get the text from the LineEdit and remove spaces at the start/end.
	var input_name = name_input.text.strip_edges()
	
	# If the user didn't type anything, we just warn in the console and stop.
	if input_name == "":
		print("Please enter a name!")
		return   # exit the function, do not continue

	# Save this name into the global singleton so other scenes can read it.
	# You created Global.gd and added it as an autoload, so it's always available.
	Global.current_username = input_name
	
	# Prepare a small dictionary that represents the user's account.
	# This is what we will save into the JSON file.
	var account_data = {
		"name": input_name,                               # the username
		"created_at": Time.get_datetime_string_from_system()  # timestamp string
	}
	
	# Build a file name like "Karl_account.json".
	# We also remove spaces from the name so the filename is safe.
	var filename = input_name.replace(" ", "") + "_account.json"
	var path = "user://" + filename   # "user://" points to Godot's user data folder
	
	# Open the file for writing (this creates it if it doesn't exist).
	var file = FileAccess.open(path, FileAccess.WRITE)
	
	# Convert the dictionary to JSON text and write it to the file.
	# "\t" makes it pretty‑printed with tabs.
	file.store_string(JSON.stringify(account_data, "\t"))
	
	# Always close the file when you're done.
	file.close()
	
	# Print to the Output panel so you can confirm it worked.
	print("Account saved at: ", path)
	
	# Finally, change to your VR scene.
	# Make sure this path matches your actual scene file name.
	# Example: if your VR scene is "main.tscn" in res://, this is correct.
	get_tree().change_scene_to_file("res://main.tscn")
