class_name Projectile extends Area2D

@export var speed: float = 80.0
@export var damage: int = 2
@export var damage_type: DamageType.Type = DamageType.Type.CONTACT
@export var lifetime: float = 3.0
@export var pierce: bool = false
@export var deflectable: bool = false
@export var source_team: StringName = &"enemy"
@export var projectile_color: Color = Color(0.3, 0.25, 0.2)
@export var projectile_radius: float = 3.0

var direction: Vector2 = Vector2.RIGHT


func _ready() -> void:
	# Set collision layers based on team
	match source_team:
		&"enemy":
			collision_layer = 16  # EnemyAttacks
			collision_mask = 3    # World + Player
		&"player":
			collision_layer = 8   # PlayerAttacks
			collision_mask = 5    # World + Enemies

	# Set hitbox metadata for HurtboxComponent detection
	set_meta("damage", damage)
	set_meta("damage_type", damage_type)
	set_meta("knockback_force", 80.0)
	set_meta("source_team", source_team)

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, projectile_radius, projectile_color)


func _on_body_entered(_body: Node) -> void:
	# Wall collision — destroy
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent:
		var hurtbox: HurtboxComponent = area
		if hurtbox.team != source_team and not pierce:
			queue_free()
