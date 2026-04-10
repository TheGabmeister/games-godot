class_name TorchFlicker extends PointLight2D

## Orange PointLight2D with random energy flicker for dungeon torches.

@export var min_energy: float = 0.6
@export var max_energy: float = 1.0
@export var flicker_speed: float = 8.0

var _time: float = 0.0


func _ready() -> void:
	color = Color(1.0, 0.7, 0.3)
	energy = max_energy


func _process(delta: float) -> void:
	_time += delta * flicker_speed
	# Combine two sine waves + noise for organic flicker
	var flicker := sin(_time * 2.3) * 0.3 + sin(_time * 5.7) * 0.2 + randf_range(-0.1, 0.1)
	energy = clampf(lerpf(min_energy, max_energy, 0.5 + flicker), min_energy, max_energy)
