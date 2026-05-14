extends Enemy

@export var jump_force: float = -350.0
@export var hop_speed: float = 120.0
@export var idle_time: float = 1.0

var _timer: float = 0.0
var _facing: float = -1.0


func _ready() -> void:
	super._ready()
	hp = 100
	contact_damage = 20


func _get_hitbox_shape() -> Shape2D:
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 40)
	return rect


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.x = 0.0
		_timer += delta
		if _timer >= idle_time:
			_timer = 0.0
			_jump()
	var _moved := move_and_slide()
	if is_on_wall():
		_facing *= -1.0


func _jump() -> void:
	velocity.y = jump_force
	velocity.x = _facing * hop_speed
