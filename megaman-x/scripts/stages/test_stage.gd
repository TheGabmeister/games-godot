extends Node2D

const STAGE_NOTE := "Standalone stage testing is ready.\nThis scene can run directly or through Main.tscn."

@onready var body_label: Label = $CanvasLayer/Overlay/Body


func _ready() -> void:
	body_label.text = STAGE_NOTE
