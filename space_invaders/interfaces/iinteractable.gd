extends Node
class_name IIteractable

const INTERACTABLE: StringName = &"Interactable"

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			## Insert itself into parent as a metadata
			get_parent().set_meta(INTERACTABLE, self)
		NOTIFICATION_UNPARENTED:
			## Remove itself from parent as a metadata
			get_parent().set_meta(INTERACTABLE, self)
	pass
	
func _ready() -> void:
  ## setting parent as owner
	owner = get_parent()
  
  ## enforcing contract onto parent
	assert(owner.has_method("can_interact"))
	assert(owner.has_method("interact"))
	pass

func can_interact(interactor: Node) -> bool:
	@warning_ignore("unsafe_method_access")
	return owner.can_interact(interactor) ## proxying the call to parent

func interact(interactor: Node) -> void:
	@warning_ignore("unsafe_method_access")
	owner.interact(interactor) ## proxying the call to parent
	pass
