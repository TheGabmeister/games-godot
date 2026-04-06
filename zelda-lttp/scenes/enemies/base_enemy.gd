class_name BaseEnemy extends CharacterBody2D

@export var enemy_data: EnemyData
@export var initial_facing: Vector2 = Vector2.DOWN

var facing_direction: Vector2 = Vector2.DOWN

@onready var state_machine: StateMachine = $StateMachine
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var knockback_component: KnockbackComponent = $KnockbackComponent
@onready var flash_component: FlashComponent = $FlashComponent
@onready var loot_drop: LootDropComponent = $LootDropComponent


func _ready() -> void:
	facing_direction = initial_facing

	if enemy_data:
		health_component.max_health = enemy_data.max_health
		health_component.current_health = enemy_data.max_health
		var contact: HitboxComponent = get_node_or_null("ContactHitbox") as HitboxComponent
		if contact:
			contact.damage = enemy_data.contact_damage

	hurtbox.hurt.connect(_on_hurt)
	health_component.died.connect(_on_died)

	for state in state_machine.states.values():
		if state is BaseEnemyState:
			state.actor = self


func update_facing(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		if absf(direction.x) > absf(direction.y):
			facing_direction = Vector2(signf(direction.x), 0)
		else:
			facing_direction = Vector2(0, signf(direction.y))
		var body: Node2D = get_node_or_null("EnemyBody") as Node2D
		if body:
			body.queue_redraw()


func _on_hurt(hitbox_data: Dictionary) -> void:
	var raw_damage: int = hitbox_data.get("damage", 0)
	var dmg_type: int = hitbox_data.get("damage_type", DamageType.Type.CONTACT)
	var source_pos: Vector2 = hitbox_data.get("source_position", global_position)
	var kb_force: float = hitbox_data.get("knockback_force", 120.0)
	var effect: int = hitbox_data.get("effect", DamageType.HitEffect.NONE)

	var immunities: Array = enemy_data.damage_immunities if enemy_data else []
	var result: Dictionary = DamageFormula.calculate_damage(raw_damage, dmg_type, 0, immunities)

	if result.immune:
		AudioManager.play_sfx(&"clink")
		return

	health_component.take_damage(result.final_damage)
	flash_component.flash()

	# Knockback with resistance
	var resistance: float = enemy_data.knockback_resistance if enemy_data else 0.0
	var actual_force: float = kb_force * (1.0 - resistance)
	if actual_force > 0.0:
		var direction: Vector2 = (global_position - source_pos).normalized()
		knockback_component.apply(direction, actual_force)

	# Stun effect
	if effect == DamageType.HitEffect.STUN and health_component.is_alive():
		if not state_machine.current_state or state_machine.current_state.name != &"Stunned":
			var prev: StringName = state_machine.current_state.name if state_machine.current_state else &""
			state_machine.transition_to(&"Stunned", {"previous_state": prev})


func _on_died() -> void:
	_spawn_death_particles()
	loot_drop.drop(global_position)
	EventBus.enemy_defeated.emit(enemy_data.id if enemy_data else &"", global_position)
	queue_free()


func _spawn_death_particles() -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 8
	particles.lifetime = 0.4
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 60.0
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = enemy_data.color if enemy_data else Color.WHITE
	particles.global_position = global_position
	get_parent().add_child(particles)
	particles.finished.connect(particles.queue_free)
