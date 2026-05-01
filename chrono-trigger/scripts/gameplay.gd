extends Node

func _ready() -> void:
	var party_manager := $PartyManager
	var level := $Level

	var party_nodes: Array = []
	var player := level.get_node_or_null("Player")
	if player:
		party_nodes.append(player)
	var marle := level.get_node_or_null("Marle")
	if marle:
		party_nodes.append(marle)
	var lucca := level.get_node_or_null("Lucca")
	if lucca:
		party_nodes.append(lucca)

	party_manager.initialize(party_nodes)
