extends Node2D

signal defeated

@onready var health_component: Node = $HealthComponent
@onready var hurtbox: Area2D = $Hurtbox
@onready var visual_root: Node2D = $VisualRoot
@onready var status_label: Label = $VisualRoot/StatusLabel


func _ready() -> void:
	add_to_group(&"stage_resettable")
	health_component.connect("died", _on_health_component_died)
	health_component.connect("health_changed", _on_health_changed)
	_on_health_changed(health_component.get("current_health"), health_component.get("max_health"))


func reset_for_stage_retry() -> void:
	health_component.call("reset")
	visible = true
	hurtbox.monitorable = true


func _on_health_component_died() -> void:
	visible = false
	hurtbox.set_deferred("monitorable", false)
	defeated.emit()


func _on_health_changed(current_health: int, max_health: int) -> void:
	status_label.text = "Dummy %d/%d" % [current_health, max_health]
