extends BaseItemEffect

const LOCK_DURATION := 0.2
const LIGHT_RANGE := 24.0
const LIGHT_DURATION := 4.0


func can_use(_player: CharacterBody2D) -> bool:
	var cost: int = 4
	if PlayerState.has_upgrade(&"magic_halver"):
		cost = ceili(cost / 2.0)
	return PlayerState.current_magic >= cost


func activate(player: CharacterBody2D) -> float:
	var light := PointLight2D.new()
	light.color = Color(1.0, 0.85, 0.4)
	light.energy = 1.2
	light.texture = _create_light_texture()
	light.texture_scale = 1.5
	light.global_position = player.global_position + player.facing_direction * LIGHT_RANGE

	player.get_parent().add_child(light)

	# Tween fade out
	var tween: Tween = light.create_tween()
	tween.tween_property(light, "energy", 0.0, LIGHT_DURATION)
	tween.tween_callback(light.queue_free)

	return LOCK_DURATION


func _create_light_texture() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 64
	tex.height = 64
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	return tex
