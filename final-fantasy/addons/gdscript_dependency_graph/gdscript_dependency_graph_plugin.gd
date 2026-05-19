@tool
extends EditorPlugin

const DependencyGraphDock := preload("res://addons/gdscript_dependency_graph/gdscript_dependency_graph_dock.gd")

var _dock: Control


func _enter_tree() -> void:
	_dock = DependencyGraphDock.new()
	_dock.name = "GDScript Graph"
	add_control_to_bottom_panel(_dock, "GDScript Graph")


func _exit_tree() -> void:
	if _dock == null:
		return

	remove_control_from_bottom_panel(_dock)
	_dock.queue_free()
	_dock = null
