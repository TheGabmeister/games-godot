extends Enemy

@export var crawl_speed: float = 40.0

var _direction: float = 1.0


func _ready() -> void:
	super._ready()
	hp = 30
	contact_damage = 10


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = _direction * crawl_speed
	var _moved := move_and_slide()
	if is_on_wall():
		_direction *= -1.0
