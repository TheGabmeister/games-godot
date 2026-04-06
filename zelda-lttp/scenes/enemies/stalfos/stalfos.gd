extends BaseEnemy

@export var detection_radius: float = 80.0
@export var lose_interest_radius: float = 120.0
@export var fire_cadence: float = 2.0
@export var wander_speed: float = 25.0

var player_detected: bool = false
var player_ref: CharacterBody2D = null

const PROJECTILE_SCENE := preload("res://scenes/projectiles/projectile_base.tscn")


func _ready() -> void:
	super._ready()

	var detection: Area2D = get_node_or_null("DetectionZone")
	if detection:
		var shape_node: CollisionShape2D = detection.get_node_or_null("DetectionShape")
		if shape_node:
			var circle := CircleShape2D.new()
			circle.radius = detection_radius
			shape_node.shape = circle
		detection.body_entered.connect(_on_detection_entered)
		detection.body_exited.connect(_on_detection_exited)


func _on_detection_entered(body: Node) -> void:
	if body is CharacterBody2D:
		player_detected = true
		player_ref = body as CharacterBody2D


func _on_detection_exited(body: Node) -> void:
	if body == player_ref:
		player_detected = false


func spawn_bone() -> void:
	if not player_ref:
		return
	var dir: Vector2 = (player_ref.global_position - global_position).normalized()
	var proj: Projectile = PROJECTILE_SCENE.instantiate()
	proj.direction = dir
	proj.speed = 60.0
	proj.damage = 2
	proj.damage_type = DamageType.Type.CONTACT
	proj.source_team = &"enemy"
	proj.projectile_color = Color(0.9, 0.85, 0.75)
	proj.projectile_radius = 2.0
	proj.global_position = global_position + dir * 8.0
	get_parent().add_child(proj)
	update_facing(dir)
