extends Node

# Variable will hold the name typed in the Menu
var current_username: String = "DefaultUser"

# Helper function gives us a clean file path
func get_save_path() -> String:
	var clean_name = current_username.replace(" ", "")
	return "user://" + clean_name + "_calibration.json"
	
