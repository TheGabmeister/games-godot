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
- **Spell SFX**: `@export var sfx: AudioStream` on SpellData. Generated via ffmpeg synthesis in `sfx/spells/`. 5 distinct SFX: fire, thunder, ice, heal, holy. Plus 3 shared: buff_cast, debuff_cast, status_inflict. Mapped per spell in `.tres` files
- **VFX**: Per-spell animated effects as lightweight scene snippets (particles or tween-driven sprites). 5 spell VFX: fire burst, lightning bolt, ice shards, healing glow, holy light. 1 generic buff shimmer (tinted per element). 3 status indicators on battler sprites: sleep bubbles, darkness cloud, silence X icon
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
- `@export var sfx: AudioStream` — per-spell cast sound effect
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
- `var magic_defense: int` — per-class, level-based. Add a `MAGIC_DEF_GROWTH: Dictionary[Job, Array]` table (same pattern as `GROWTH`). Apply in `_apply_level_stats()`. Starting values at Lv 1: Warrior 15, Monk 20, White Mage 25, Black Mage 20. Casters scale faster (White Wizard reaches ~120 by Lv 50, Warrior ~60)

### Step 3 — BattleTypes Extensions

In `scripts/battle/battle_types.gd`:
- Add `MAGIC` to `CommandType` enum
- Add `var spell: SpellData` to BattleCommand
- Add to Battler:
  - `var statuses: Dictionary` — `{ &"sleep": int, &"darkness": int, &"silence": int }`. Value = turns remaining (-1 = permanent/until cured, 0 = inactive). Sleep is set to -1 (cleared on physical hit), Darkness/Silence are -1 (cleared by cure spells). Status checks use `statuses.get(name, 0) != 0`. Turn-decrement hook in resolver's end-of-round for future timed statuses (Poison, etc.)
  - `var buff_atk: int = 0`
  - `var buff_def: int = 0`
  - `var buff_evade: int = 0`
  - `var debuff_hits: int = 0`
  - `var resistances: Array[SpellData.Element] = []`
  - `var magic_defense: int = 0` — for enemies, sourced from EnemyData. For party members, sourced from CharacterData (see Step 2 addition)

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
    - STATUS_INFLICT: check spell hit, set `entry.status_name` to -1 (permanent until cured), show text ("Sleep!")
    - STATUS_CURE: set `entry.status_name` to 0, show text
  - For NulShock-type entries: append `entry.resist_element` to target's `resistances` array (handled inside BUFF branch when `resist_element != NONE`)
  - Play `spell.sfx` via SfxManager when spell executes
  - Play spell VFX scene on target(s) — instantiate from element-keyed VFX map, queue_free on completion
  - Show "Weak!" popup text when elemental weakness triggers, "Resist!" when resistance reduces damage
- Status hooks in existing flow:
  - In `_execute_actions`: after dead check, skip actors where `statuses.get(&"sleep", 0) != 0`
  - In `_execute_attack`: subtract 40 from accuracy if `statuses.get(&"darkness", 0) != 0`
  - In `_execute_attack`: on physical hit against sleeping target, set `statuses[&"sleep"] = 0`
  - End-of-round: iterate all battlers' statuses, decrement any value > 0 (future timed statuses auto-expire)
  - In `_execute_attack`: apply `buff_atk` to attack power, `buff_def` to defense, `buff_evade` to evade, `debuff_hits` to max_hits

### Step 6 — BattleScene: Magic Command UI

In `scripts/battle/battle_scene.gd`:
- Add `MAGIC_LEVEL_SELECT` and `MAGIC_SPELL_SELECT` to `BattlePhase` enum
- Add cursor vars: `_magic_level_cursor`, `_magic_spell_cursor`
- Add `_handle_magic_level_input(event)` and `_handle_magic_spell_input(event)` to `_input` dispatch
- Silence gate: in `_select_command`, if `statuses.get(&"silence", 0) != 0`, play buzzer and don't enter magic flow
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
- White Mage: learn 3 of 4 per level (3-slot limit). Lv 1: Cure, Protect, Dia (skip Blink). Lv 2: Blindna, Silence, NulShock (skip Invis). Set Lv 1 charges to 3, Lv 2 charges to 2
- Black Mage: learn 3 of 4 per level (3-slot limit). Lv 1: Fire, Sleep, Thunder (skip Focus). Lv 2: Blizzard, Dark, Temper (skip Slow). Set Lv 1 charges to 3, Lv 2 charges to 2
- Warrior / Monk: no spells, all charges 0
- Add 2 Ethers to starting inventory for testing

### Step 11 — Spell SFX

Generate 8 OGG files in `sfx/spells/` via ffmpeg synthesis:
- `fire.ogg` — crackling whoosh (noise burst + sine sweep)
- `thunder.ogg` — sharp electric zap (high-freq sine + noise)
- `ice.ogg` — crystalline shatter (high sine + filtered noise)
- `heal.ogg` — warm ascending chime (multi-sine arpeggio)
- `holy.ogg` — bright bell tone (high sine chord)
- `buff_cast.ogg` — soft rising shimmer (sine sweep up)
- `debuff_cast.ogg` — low descending tone (sine sweep down)
- `status_inflict.ogg` — dull thud/impact (low sine + noise)

Add `@export var sfx: AudioStream` to `spell_data.gd`. Wire each spell `.tres` to the appropriate SFX:
- Fire → fire.ogg, Thunder → thunder.ogg, Blizzard → ice.ogg
- Cure → heal.ogg, Dia → holy.ogg
- Protect, Blink, Invis, Temper, NulShock → buff_cast.ogg
- Focus, Slow → debuff_cast.ogg
- Sleep, Silence, Dark, Blindna → status_inflict.ogg

In BattleResolver `_execute_spell`: play `spell.sfx` via SfxManager before effects iterate.

### Step 12 — Spell VFX

Create per-element VFX as `GPUParticles2D` scenes in `_scenes/vfx/`. Each is a standalone scene instantiated at the target position, auto-freed via `one_shot = true` + a timer or `finished` signal.

**Per-element particle scenes** (`_scenes/vfx/`):
- `vfx_fire.tscn` — orange-red embers rising and fading, warm glow
- `vfx_thunder.tscn` — yellow-white sparks in a burst pattern, bright flash
- `vfx_ice.tscn` — cyan shards expanding outward, crystalline
- `vfx_heal.tscn` — green sparkles drifting upward, soft glow
- `vfx_holy.tscn` — white-gold radial burst, bright

**Buff/debuff shimmer** — brief color tint pulse on target sprite via tween (gold for buff, purple for debuff). No separate scene needed.

**Element → VFX map** in BattleResolver: `const ELEMENT_VFX: Dictionary` keyed by `SpellData.Element`, values are preloaded PackedScenes. HEAL/BUFF/STATUS effects use a lookup by spell effect type instead. Instantiate at target sprite position, add to `_battler_container`, auto-frees after particle lifetime.

Replace `_flash_spell_color` with `_play_spell_vfx(element, target_position)` that spawns the particle scene.

### Step 13 — Elemental Popup Text

In BattleResolver `_apply_spell_effect`, after `apply_elemental_modifiers`:
- If `result["weak"]` is true: show "Weak!" text in orange above target (same pattern as `_show_status_text`)
- If `result["resist"]` is true: show "Resist!" text in blue above target

### Step 14 — Status Effect Icons

Add persistent status indicators on battler sprites during battle:
- Sleep: small "Zzz" Label above sprite, bobbing animation (tween loop)
- Darkness: dark translucent overlay on sprite (modulate toward dark purple)
- Silence: small "X" Label near sprite in red

In BattleResolver:
- `_update_status_indicators(battler)` — called after any status change. Creates/removes indicator nodes as children of `battler.sprite`
- On status set to non-zero: create indicator if not present
- On status cleared to 0: remove indicator
- Indicators are cleaned up in battle cleanup

## Testing Checklist

### Magic Command UI
- [ ] Magic option in battle command menu is selectable and navigable (cursor moves through all 4 options)
- [ ] Silence gate: silenced character cannot enter Magic menu (plays cancel SFX)
- [ ] Spell level select shows 8 levels, grayed-out levels with 0 charges or no spells are blocked on confirm
- [ ] Spell select shows learned spells for the chosen level, navigable with up/down
- [ ] Cancel from spell select returns to level select; cancel from level select returns to command menu
- [ ] SINGLE_ENEMY spells enter enemy targeting; SINGLE_ALLY spells enter ally targeting; ALL/SELF auto-resolve
- [ ] After selecting a spell target, command advances to next character

### Spell Charges
- [ ] White Mage starts with 3 Lv1 charges and 2 Lv2 charges
- [ ] Black Mage starts with 3 Lv1 charges and 2 Lv2 charges
- [ ] Warrior and Monk have no spells and 0 charges on all levels
- [ ] Casting a spell deducts 1 charge from the correct level
- [ ] Cannot select a spell level with 0 charges remaining
- [ ] Ether restores all charges to max (use in battle via Item command)

### Damage Spells
- [ ] Fire deals 10-20 damage to a single enemy; fire VFX plays, fire SFX plays
- [ ] Thunder deals 10-20 damage; lightning VFX, thunder SFX
- [ ] Blizzard deals 20-40 damage; ice VFX, ice SFX
- [ ] Dia deals 20-40 damage to ALL enemies; holy VFX, holy SFX
- [ ] Damage spells that miss deal half damage (no "Miss" text — reduced number shown)
- [ ] Fire on Skeleton (weak Fire): "Weak!" popup, +50% damage, higher hit rate
- [ ] Fire on Green Slime (weak Fire): same weak bonus
- [ ] Blizzard on Green Slime (weak Ice): "Weak!" popup, +50% damage
- [ ] NulShock on party → cast Thunder on party member → "Resist!" popup, damage halved

### Healing & Buffs
- [ ] Cure heals 16-32 HP on a single ally; green heal number, heal VFX, heal SFX
- [ ] Cure does not exceed max HP
- [ ] Protect: "+8 DEF" text, gold shimmer on target, subsequent physical damage reduced
- [ ] Blink: "+80 EVADE" text on caster (SELF target), gold shimmer
- [ ] Invis: "+40 EVADE" text on target ally, gold shimmer
- [ ] Temper: "+14 ATK" text on target ally, gold shimmer, subsequent physical attacks hit harder
- [ ] NulShock: adds Lightning resistance to all allies, buff SFX

### Debuffs
- [ ] Focus: "-20 EVADE" text on single enemy, purple shimmer, debuff SFX
- [ ] Slow: "-1 HITS" text on all enemies, purple shimmer, debuff SFX
- [ ] Focus/Slow can miss — shows "Miss" text on failure

### Status Effects
- [ ] Sleep on all enemies: "Sleep" text on each hit target, "Zzz" bobbing indicator appears
- [ ] Sleeping enemy skips their turn (shows "Sleep" text during action phase)
- [ ] Physical hit on sleeping target clears sleep, "Zzz" indicator removed
- [ ] Dark on all enemies: "Darkness" text, dark purple overlay on affected sprites
- [ ] Darkness reduces hit accuracy by 40 (enemy misses more often)
- [ ] Silence on all enemies: "Silence" text, red "X" indicator (enemies don't cast spells yet, but indicator should display)
- [ ] Blindna on ally with Darkness: "Cured" text, dark overlay removed, heal SFX
- [ ] Status effects can miss — shows "Miss" text on failure

### PartyMenu Magic Screen
- [ ] Magic option in main menu opens character select (same layout as Status)
- [ ] Selecting a character shows spell levels with charge counts and spell names
- [ ] Levels with no spells or 0 max charges are hidden
- [ ] Cancel returns through character select → main menu
- [ ] Charge counts update after battle (charges spent in combat are reflected)

### New Enemies
- [ ] Skeleton appears in Cornelia Outskirts encounters (verify encounter runs)
- [ ] Green Slime appears in encounters; DEF 255 makes physical attacks deal minimal damage (magic is effective)
- [ ] Both enemies display their sprites correctly in battle

### Edge Cases
- [ ] Cast all charges → level grays out, cannot re-enter
- [ ] ALL_ENEMIES spell with some enemies dead: only hits alive enemies
- [ ] ALL_ALLIES spell: hits all 4 party members
- [ ] Retargeting: if selected enemy dies before spell resolves, spell retargets to next alive enemy
- [ ] Multiple buffs stack: casting Temper twice gives +28 ATK total
- [ ] Battle cleanup: status indicators, VFX particles, and buff accumulators reset between battles
- [ ] Game over still works: party wipe during magic battle returns to title screen

## Spells Reference

| Spell | Level | Effects | Power | Acc | Element | Target | SFX | Effect |
|-------|-------|---------|-------|-----|---------|--------|-----|--------|
| Cure | W1 | HEAL | 16 | — | NONE | SINGLE_ALLY | heal | Heal 16-32 HP |
| Protect | W1 | BUFF | — | — | NONE | SINGLE_ALLY | buff_cast | +8 DEF |
| Dia | W1 | DAMAGE | 20 | 64 | DEATH | ALL_ENEMIES | holy | 20-80, undead bonus |
| Blink | W1 | BUFF | — | — | NONE | SELF | buff_cast | +80 Evade |
| Blindna | W2 | STATUS_CURE | — | — | NONE | SINGLE_ALLY | heal | Cure Darkness |
| Silence | W2 | STATUS_INFLICT | — | 64 | NONE | ALL_ENEMIES | status_inflict | Inflict Silence |
| NulShock | W2 | BUFF | — | — | LIGHTNING | ALL_ALLIES | buff_cast | Add Lightning resist |
| Invis | W2 | BUFF | — | — | NONE | SINGLE_ALLY | buff_cast | +40 Evade |
| Fire | B1 | DAMAGE | 10 | 24 | FIRE | SINGLE_ENEMY | fire | 10-40 Fire |
| Sleep | B1 | STATUS_INFLICT | — | 24 | NONE | ALL_ENEMIES | status_inflict | Inflict Sleep |
| Focus | B1 | DEBUFF | — | 24 | NONE | SINGLE_ENEMY | debuff_cast | -20 Evade |
| Thunder | B1 | DAMAGE | 10 | 24 | LIGHTNING | SINGLE_ENEMY | thunder | 10-40 Lightning |
| Blizzard | B2 | DAMAGE | 20 | 24 | ICE | SINGLE_ENEMY | ice | 20-80 Ice |
| Dark | B2 | STATUS_INFLICT | — | 24 | NONE | ALL_ENEMIES | status_inflict | Inflict Darkness |
| Temper | B2 | BUFF | — | — | NONE | SINGLE_ALLY | buff_cast | +14 ATK |
| Slow | B2 | DEBUFF | — | 24 | NONE | ALL_ENEMIES | debuff_cast | -1 Hits |
