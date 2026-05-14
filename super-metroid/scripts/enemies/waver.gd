extends Enemy

@export var move_speed: float = 80.0
@export var swoop_amplitude: float = 60.0
@export var swoop_frequency: float = 2.0

var _time: float = 0.0
var _direction: float = -1.0
var _base_y: float = 0.0


func _ready() -> void:
	super._ready()
	hp = 30
	contact_damage = 10
	_base_y = global_position.y


func _physics_process(delta: float) -> void:
	_time += delta
	velocity.x = _direction * move_speed
	global_position.y = _base_y + sin(_time * swoop_frequency * TAU) * swoop_amplitude
	var _moved := move_and_slide()
	if is_on_wall():
		_direction *= -1.0
