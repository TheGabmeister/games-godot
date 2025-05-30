extends Node
class_name IHittable

const IHITTABLE: StringName = &"Hittable"

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			## Insert itself into parent as a metadata
			get_parent().set_meta(IHITTABLE, self)
		NOTIFICATION_UNPARENTED:
			## Remove itself from parent as a metadata
			get_parent().set_meta(IHITTABLE, null)
	pass
	
func _ready() -> void:
  	## setting parent as owner
	owner = get_parent()
  
  	## enforcing contract onto parent
	assert(owner.has_method("on_hit"))
	pass

func on_hit(instigator: Node) -> void:
	@warning_ignore("unsafe_method_access")
	owner.on_hit(instigator) ## proxying the call to parent
	pass
