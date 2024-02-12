extends Node

var server := WebSocketServer.new()

func _ready():
	var port := 8081
	var error := server.listen(port)
	if error != OK:
		push_error("Failed to start server: %s" % [error])
	else:
		print("Server listening on port ", port)
	server.connect("client_connected", self, "_on_client_connected")
	server.connect("client_disconnected", self, "_on_client_disconnected")
	server.connect("data_received", self, "_on_data_received")

func _process(_delta: float) -> void:
	server.poll()

func _on_client_connected(client_id: int, _protocol: String) -> void:
	print("Client connected with ID: ", client_id)
	send_messages(client_id)

func _on_client_disconnected(client_id: int, _was_clean_close: bool) -> void:
	print("Client disconnected with ID: ", client_id)

func _on_data_received(client_id: int, data: PackedByteArray) -> void:
	var message := data.get_string_from_utf8()
	print("Received message from client ", client_id, ": ", message)

func send_messages(client_id: int) -> void:
	var messages := [
		# Your messages go here. Example:
		{"racestatus": {"raceAction": "start"}},
		# Add more messages as needed
	]
	for message in messages:
		var message_text := JSON.print(message)
		server.send_message(client_id, message_text.to_utf8(), WebSocketPeer.OPCODE_TEXT)
		# Implement delay
		get_tree().create_timer(0.1).await

