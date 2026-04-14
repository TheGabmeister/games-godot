extends Resource
class_name DialogueLine

@export var line_id: StringName
@export var speaker_id: StringName = &"narrator"
@export_multiline var body_text := ""
