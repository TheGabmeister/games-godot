# Phase 4a — Spell Charge System & Elemental Damage

Implementation plan for the Vancian spell charge engine, Magic battle command, elemental weakness/resistance, buffs/debuffs, status effects, and the first 16 spells.

## Key Design Decisions

- **SpellData**: Resource class (`scripts_consts/spell_data.gd`, `.tres` files in `data/spells/`), matching EnemyData/EquipmentData pattern
- **Element enum**: Defined on SpellData — `enum Element { FIRE, ICE, LIGHTNING, EARTH, POISON, TIME, DEATH, STATUS }`; `-1` for non-elemental
- **Target types**: `enum TargetType { SINGLE_ENEMY, ALL_ENEMIES, SINGLE_ALLY, ALL_ALLIES, SELF }` — full enum now, Lv 1-2 only uses SINGLE_ENEMY and SINGLE_ALLY
- **Effect types**: `enum SpellEffect { DAMAGE, HEAL, BUFF, DEBUFF, STATUS_INFLICT, STATUS_CURE }`. Spells carry an `Array[SpellEffect]` (effects list) so compound spells (e.g., Curaja = HEAL + STATUS_CURE, Saber = BUFF + BUFF) work without special-case code. Most spells have a single effect; the resolver iterates the array
- **Learned spells**: Flat `Array[SpellData]` of size 24 on CharacterData (indices `level * 3 + slot`), null for empty slots. Helper methods `get_spells_for_level(level)` and `learn_spell(spell)`
- **Spell charges**: `Array[int]` of size 8 on CharacterData, one per spell level. Battler reads at battle start, syncs back on spend
- **Status effects**: `Dictionary[StringName, bool]` on Battler, keyed by `&"sleep"`, `&"darkness"`, `&"silence"`. Inline checks at relevant points in combat loop
- **Buff/debuff accumulators**: Dedicated vars on Battler — `buff_atk`, `buff_def`, `buff_evade`, `debuff_hits`. Added to base stats during calculation
- **Elemental resistances on party**: `Array[SpellData.Element]` on Battler for NulShock and future resist spells. Mirrors EnemyData pattern
- **Magic UI flow**: COMMAND_SELECT → MAGIC_LEVEL_SELECT (new phase) → MAGIC_SPELL_SELECT (new phase) → reuse TARGETING or ITEM_TARGET depending on spell target type. Silence blocks entering Magic
- **Spell execution**: New `_execute_spell` in BattleResolver. Deducts charge, branches on effect type, uses BattleFormulas for damage/hit
- **VFX**: Minimal — color-tinted flash + floating text ("Fire!", "Sleep!", "+8 DEF"). Upgrade to real VFX later
- **Enemy AI**: No enemy spellcasting. New enemies are melee-only with elemental weaknesses
- **Ether**: New `ItemData.EffectType.RESTORE_CHARGES`. Full recharge (all levels to max)
- **Starter spells**: White Mage gets all Lv 1-2 White spells, Black Mage gets all Lv 1-2 Black spells, assigned in PartyData init with starting charges. 3-per-level limit enforced in Phase 4b when shops arrive
- **Magic menu**: Two-screen in PartyMenu — MAGIC (select character) → MAGIC_DETAIL (view spells and charges per level). View-only

## Build Order

### Step 1 — SpellData Resource + Element Enum

Create `scripts_consts/spell_data.gd` with `class_name SpellData`:
- `enum Element { FIRE, ICE, LIGHTNING, EARTH, POISON, TIME, DEATH, STATUS }`
- `enum TargetType { SINGLE_ENEMY, ALL_ENEMIES, SINGLE_ALLY, ALL_ALLIES, SELF }`
- `enum SpellEffect { DAMAGE, HEAL, BUFF, DEBUFF, STATUS_INFLICT, STATUS_CURE }`
- `@export var spell_name: String`
- `@export var level: int` (1-8)
- `@export var spell_accuracy: int`
- `@export var element: Element` (use `NONE` for non-elemental)
- `@export var target_type: TargetType`
- `@export var effects: Array[SpellEffectEntry]` — one or more effects per spell (see SpellEffectEntry below)
- `@export var is_white_magic: bool`

Add `NONE` as the first Element value: `enum Element { NONE = -1, FIRE, ICE, LIGHTNING, EARTH, POISON, TIME, DEATH, STATUS }`

**SpellEffectEntry** — inner Resource class (or separate `spell_effect_entry.gd`):
- `@export var type: SpellData.SpellEffect`
- `@export var power: int` (damage/heal base, 0 if N/A)
- `@export var status_name: StringName` (for STATUS_INFLICT/STATUS_CURE — e.g., `&"sleep"`)
- `@export var buff_stat: StringName` (for BUFF/DEBUFF — e.g., `&"atk"`, `&"def"`, `&"evade"`, `&"hits"`)
- `@export var buff_amount: int` (e.g., +14 for Temper, -20 for Focus)
- `@export var resist_element: SpellData.Element` (for NulShock-type spells; NONE if N/A)

Most spells have a single entry. Compound spells (Curaja, Saber) have multiple entries sharing the parent spell's target_type and accuracy

Create 16 `.tres` files in `data/spells/`:
- White Lv 1: Cure, Protect, Dia, Blink
- White Lv 2: Blindna, Silence, NulShock, Invis
- Black Lv 1: Fire, Sleep, Focus, Thunder
- Black Lv 2: Blizzard, Dark, Temper, Slow

### Step 2 — CharacterData Extensions

In `scripts/autoloads/party_data.gd`, add to CharacterData:
- `var learned_spells: Array[SpellData]` — size 24, initialized to nulls
- `var spell_charges: Array[int]` — size 8, initialized to 0
- `var max_spell_charges: Array[int]` — size 8, determined by class + level
- `func get_spells_for_level(level: int) -> Array[SpellData]` — returns slots `[(level-1)*3 .. (level-1)*3+2]`, filtering nulls
- `func learn_spell(spell: SpellData) -> bool` — places spell in first empty slot for its level, returns false if full
- `func spend_charge(level: int) -> bool` — decrements charge, returns false if empty
- `func restore_all_charges() -> void` — fills all levels to max

### Step 3 — BattleTypes Extensions

In `scripts/battle/battle_types.gd`:
- Add `MAGIC` to `CommandType` enum
- Add `var spell: SpellData` to BattleCommand
- Add to Battler:
  - `var statuses: Dictionary` — `{ &"sleep": bool, &"darkness": bool, &"silence": bool }`
  - `var buff_atk: int = 0`
  - `var buff_def: int = 0`
  - `var buff_evade: int = 0`
  - `var debuff_hits: int = 0`
  - `var resistances: Array[SpellData.Element] = []`
  - `var magic_defense: int = 0` (sourced from EnemyData or a base value for party)

### Step 4 — BattleFormulas

In `scripts/battle/battle_formulas.gd`, add static functions:
- `magic_damage(spell_power: int) -> int` — returns `randi_range(spell_power, spell_power * 2)`
- `spell_hit_check(spell_accuracy: int, magic_defense: int) -> bool` — returns `randf() * 100 < (spell_accuracy - magic_defense)`
- `apply_elemental_modifiers(damage: int, element, weaknesses, resistances) -> Dictionary` — returns `{ "damage": int, "weak": bool, "resist": bool }` with +50%/-50% applied
- `spell_hit_with_element(spell_accuracy: int, magic_defense: int, element, weaknesses) -> bool` — adds +20% for weakness

### Step 5 — BattleResolver: Spell Execution + Status Hooks

In `scripts/battle/battle_resolver.gd`:
- Add `CommandType.MAGIC` case in `_execute_actions` match, following the same pattern as `_execute_attack` and `_execute_item`
- Spell execution logic:
  - Deduct charge from `actor.character_data.spend_charge(spell.level)`
  - Iterate `spell.effects` array — for each `SpellEffectEntry`, branch on `entry.type`:
    - DAMAGE: calculate damage from `entry.power`, check hit, apply elemental mods, deal damage, show number
    - HEAL: calculate heal amount from `entry.power`, apply to target, show green number
    - BUFF: add `entry.buff_amount` to target's buff accumulator for `entry.buff_stat`, show text ("+8 DEF")
    - DEBUFF: apply `entry.buff_amount` to target's debuff field for `entry.buff_stat`, show text
    - STATUS_INFLICT: check spell hit, set `entry.status_name` flag, show text ("Sleep!")
    - STATUS_CURE: clear `entry.status_name` flag, show text
  - For NulShock-type entries: append `entry.resist_element` to target's `resistances` array (handled inside BUFF branch when `resist_element != NONE`)
  - Color-tinted flash for VFX (element → color mapping)
- Status hooks in existing flow:
  - In `_execute_actions`: after dead check, skip actors with Sleep status
  - In `_execute_attack`: subtract 40 from accuracy if attacker has Darkness
  - In `_execute_attack`: on physical hit against sleeping target, clear sleep
  - In `_execute_attack`: apply `buff_atk` to attack power, `buff_def` to defense, `buff_evade` to evade, `debuff_hits` to max_hits

### Step 6 — BattleScene: Magic Command UI

In `scripts/battle/battle_scene.gd`:
- Add `MAGIC_LEVEL_SELECT` and `MAGIC_SPELL_SELECT` to `BattlePhase` enum
- Add cursor vars: `_magic_level_cursor`, `_magic_spell_cursor`
- Add `_handle_magic_level_input(event)` and `_handle_magic_spell_input(event)` to `_input` dispatch
- Silence gate: in `_select_command`, if current battler has Silence status, play buzzer and don't enter magic flow
- MAGIC_LEVEL_SELECT: show spell levels 1-8, gray out levels with 0 charges or no spells, up/down to navigate, confirm to enter spell list, cancel to return to command select
- MAGIC_SPELL_SELECT: show learned spells for selected level, up/down to navigate, confirm to enter targeting, cancel to go back to level select
- On spell confirm: set target phase based on `spell.target_type` — TARGETING for SINGLE_ENEMY, ITEM_TARGET (reused) for SINGLE_ALLY, auto-resolve for SELF/ALL
- Build BattleCommand with `CommandType.MAGIC` and the selected spell

### Step 7 — EnemyData Extensions + New Enemies

In `scripts_consts/enemy_data.gd`:
- Add `@export var weaknesses: Array[SpellData.Element] = []`
- Add `@export var resistances: Array[SpellData.Element] = []`
- Add `@export var magic_defense: int = 0`

Create enemy `.tres` files in `data/enemies/`:
- Skeleton: 10 HP, weak Fire + DEATH (undead/holy), low ATK
- Green Slime: 24 HP, DEF 255, weak Fire + Ice, low ATK

Add both to Cornelia Outskirts encounter table.

### Step 8 — Ether Item

In `scripts_consts/item_data.gd`:
- Add `RESTORE_CHARGES` to `EffectType` enum

In `scripts/autoloads/party_data.gd`:
- Extend `use_item` to handle `RESTORE_CHARGES` — calls `target.restore_all_charges()`

Create `data/items/ether.tres` with `RESTORE_CHARGES` effect type.

### Step 9 — PartyMenu Magic Screen

In `scripts/ui/party_menu.gd`:
- Add `MAGIC_DETAIL` to `Screen` enum
- MAGIC screen: character select list (same pattern as STATUS), confirm enters MAGIC_DETAIL
- MAGIC_DETAIL: for selected character, display 8 rows (one per spell level), each showing `"Lv N  charges/max  spell1  spell2  spell3"`. View-only, cancel returns to MAGIC

Build UI with GameButton for character select, Labels for spell display.

### Step 10 — Starter Spell Assignment

In `scripts/autoloads/party_data.gd`, in party initialization:
- White Mage: learn all 4 White Lv 1 + all 4 White Lv 2 spells, set Lv 1 charges to 3, Lv 2 charges to 2
- Black Mage: learn all 4 Black Lv 1 + all 4 Black Lv 2 spells, set Lv 1 charges to 3, Lv 2 charges to 2
- Warrior / Monk: no spells, all charges 0
- Add 2 Ethers to starting inventory for testing

## Spells Reference

| Spell | Level | Effects | Power | Acc | Element | Target | Effect |
|-------|-------|---------|-------|-----|---------|--------|--------|
| Cure | W1 | HEAL | 16 | — | NONE | SINGLE_ALLY | Heal 16-32 HP |
| Protect | W1 | BUFF | — | — | NONE | SINGLE_ALLY | +8 DEF |
| Dia | W1 | DAMAGE | 20 | 64 | DEATH | ALL_ENEMIES | 20-80, undead bonus |
| Blink | W1 | BUFF | — | — | NONE | SELF | +80 Evade |
| Blindna | W2 | STATUS_CURE | — | — | NONE | SINGLE_ALLY | Cure Darkness |
| Silence | W2 | STATUS_INFLICT | — | 64 | NONE | ALL_ENEMIES | Inflict Silence |
| NulShock | W2 | BUFF | — | — | LIGHTNING | ALL_ALLIES | Add Lightning resist |
| Invis | W2 | BUFF | — | — | NONE | SINGLE_ALLY | +40 Evade |
| Fire | B1 | DAMAGE | 10 | 24 | FIRE | SINGLE_ENEMY | 10-40 Fire |
| Sleep | B1 | STATUS_INFLICT | — | 24 | NONE | ALL_ENEMIES | Inflict Sleep |
| Focus | B1 | DEBUFF | — | 24 | NONE | SINGLE_ENEMY | -20 Evade |
| Thunder | B1 | DAMAGE | 10 | 24 | LIGHTNING | SINGLE_ENEMY | 10-40 Lightning |
| Blizzard | B2 | DAMAGE | 20 | 24 | ICE | SINGLE_ENEMY | 20-80 Ice |
| Dark | B2 | STATUS_INFLICT | — | 24 | NONE | ALL_ENEMIES | Inflict Darkness |
| Temper | B2 | BUFF | — | — | NONE | SINGLE_ALLY | +14 ATK |
| Slow | B2 | DEBUFF | — | 24 | NONE | ALL_ENEMIES | -1 Hits |
