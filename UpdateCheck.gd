extends Node
const CURRENT_VERSION = "1.0.0"
const GOOGLE_SHEET_URL = "https://docs.google.com/spreadsheets/d/e/2PACX-1vTTXpWNXOV8-QthqmQDHFVh92v5BM4h3gOVtYgIUE6Hzl449LNGrdRzws8ncynZ7bSx0rt4bqirx2dV/pub?gid=0&single=true&output=csv"

@onready var version_notice = $"../Version_notice"

func _ready():
	var request_node = $VersionCheckRequest
	# Make a GET request to the published CSV
	request_node.request(GOOGLE_SHEET_URL)
	print("testing")

func _on_VersionCheckRequest_request_completed(
		result: int, 
		response_code: int, 
		headers: PackedStringArray, 
		body: PackedByteArray
	):
		# If 307, parse the "Location" header
	if response_code == 307:
		for header in headers:
			if header.begins_with("Location:"):
				var location = header.substr("Location:".length()).strip_edges()
				print("Redirecting to: ", location)
				# Then do a second request manually
				$VersionCheckRequest.request(location)
				return
	if response_code == 200 and result == OK:
		var response_text = body.get_string_from_utf8()
		# Since we only have one cell, response_text will probably just be "1.2.3"
		var remote_version = response_text.strip_edges()  # remove any extra whitespace/newline

		if remote_version != CURRENT_VERSION:
			# Compare versions in your own logic
			if is_newer(remote_version, CURRENT_VERSION):
				print("A new version is available: ", remote_version)
				version_notice.text = "A new version is available"
				version_notice.modulate = Color(1, 0, 0)
			else:
				print("You are on a dev or equal version: ", CURRENT_VERSION)
		else:
			print("You are on the latest version.")
			version_notice.text = "You are on the latest version."
	else:
		print("Error fetching version info. Response code:", response_code)
		version_notice.text = "Error fetching version info."

func is_newer(remote_version: String, local_version: String) -> bool:
	# Very naive comparison, e.g. split by "." 
	# This logic can be replaced or expanded
	print(remote_version)
	print(local_version)
	var remote_parts = remote_version.split(".")
	var local_parts = local_version.split(".")

	for i in range(min(remote_parts.size(), local_parts.size())):
		if int(remote_parts[i]) > int(local_parts[i]):
			return true
		elif int(remote_parts[i]) < int(local_parts[i]):
			return false
	return remote_parts.size() > local_parts.size()


