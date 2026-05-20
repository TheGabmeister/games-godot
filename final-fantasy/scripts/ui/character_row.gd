class_name CharacterRow
extends HBoxContainer

const SPRITE_SHEETS: Dictionary[PartyData.Job, Texture2D] = {
	PartyData.Job.WARRIOR:    preload("res://characters/warrior/warrior_sheet.png"),
	PartyData.Job.MONK:       preload("res://characters/monk/monk_sheet.png"),
	PartyData.Job.WHITE_MAGE: preload("res://characters/white_mage/white_mage_sheet.png"),
	PartyData.Job.BLACK_MAGE: preload("res://characters/black_mage/black_mage_sheet.png"),
}

@onready var _portrait: TextureRect = %Portrait
@onready var _name_label: Label = %CharName
@onready var _hp_value: Label = %HPValue
@onready var _mp_value: Label = %MPValue
@onready var _lv_label: Label = %LvLabel
@onready var _next_label: Label = %NextLabel

func populate(character: PartyData.CharacterData) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = SPRITE_SHEETS[character.job]
	atlas.region = Rect2(0, 0, 64, 96)
	_portrait.texture = atlas
	_name_label.text = character.char_name
	_hp_value.text = "  %3d / %3d" % [character.current_hp, character.max_hp]
	_mp_value.text = "MP  0 /  0 /  0 /  0"
	_lv_label.text = "Lv. %d" % character.level
	_next_label.text = "Next Level in   0"
