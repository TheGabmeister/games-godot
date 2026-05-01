# Phase 4 — Techs and elements

## Goal

Add Single Techs for Crono, Marle, and Lucca with MP costs. Implement elemental damage with per-enemy resistance multipliers. Add a minimum set of status effects (Haste, Slow, Poison, Sleep). TP accumulates from battles and unlocks techs at thresholds.

## What we're building on

From Phase 3 we have: 3-member party with ATB, multi-enemy encounters, Attack/Item commands, target selection (enemy and ally), escape mechanic, signal-driven battle_manager/battle_ui, PartyManager persisting HP/KO across battles, Inventory system, gameplay scene wrapper.

## MP system

### CharacterData additions

```gdscript
# Add to character_data.gd:
@export var max_mp: int
@export var magic: int       # magic attack power (used in tech damage formula)
@export var magic_def: int   # magic defense (reduces incoming magic damage)
```

### Party member stats (updated)

| Stat | Crono | Marle | Lucca |
|------|------:|------:|------:|
| HP | 70 | 65 | 62 |
| MP | 10 | 12 | 12 |
| Power | 5 | 2 | 3 |
| Magic | 4 | 8 | 8 |
| Speed | 9 | 12 | 6 |
| Stamina | 5 | 3 | 4 |
| Magic Def | 4 | 8 | 6 |
| Strike % | 10 | 8 | 8 |
| Weapon AP | 3 | 2 | 3 |

### PartyManager additions

Track `current_mp` and `total_tp` alongside `current_hp` in the per-member runtime state. Both persist across battles.

```gdscript
# In PartyManager member dict:
{ "data": CharacterData, "current_hp": int, "current_mp": int, "total_tp": int, "is_ko": bool, "node": Node2D }
```

Initialize `current_mp` to `data.max_mp` and `total_tp` to `0` at startup.

### BattleManager party dict expansion

The per-member dict in BattleManager gains MP and status tracking:

```gdscript
_party.append({
    "data": m["data"],
    "current_hp": m["current_hp"],
    "max_hp": m["data"].max_hp,
    "current_mp": m["current_mp"],
    "max_mp": m["data"].max_mp,
    "is_ko": m["is_ko"],
    "atb": 0.0,
    "node": m["node"],
    "statuses": {},  # { "haste": turns_remaining, ... }
})
```

### Write-back updates

`_write_back_state` must now return both HP and MP. On victory, also add TP:

```gdscript
func _write_back_state() -> void:
    var party_manager := get_tree().get_first_node_in_group(Groups.PARTY_MANAGER)
    if party_manager == null:
        return
    var state: Array = []
    for p in _party:
        state.append({ "current_hp": p["current_hp"], "current_mp": p["current_mp"] })
    party_manager.update_from_battle(state)
```

TP is awarded separately in `_victory`:

```gdscript
var total_tp := 0
for e in _enemies:
    total_tp += int(e["data"].get("tp_reward"))
party_manager.award_tp(total_tp)  # awards to living members only
```

PartyManager adds:

```gdscript
func award_tp(amount: int) -> void:
    for m in members:
        if not m["is_ko"]:
            m["total_tp"] += amount
```

## Tech data

### TechData resource

```gdscript
# tech_data.gd
class_name TechData
extends Resource

@export var tech_name: String
@export var mp_cost: int
@export var power: int = 0         # damage techs: magic attack power; heal techs: heal multiplier (heal = caster.magic * power)
@export var element: String = ""   # "", "lightning", "fire", "water", "shadow"
@export var target_type: String    # "single_enemy", "all_enemies", "line", "circle", "self_circle", "single_ally", "all_allies"
@export var effect: String = ""    # "", "heal", "status"
@export var status_effect: String = ""  # "haste", "slow", "poison", "sleep"
@export var status_chance: float = 1.0  # 0.0–1.0 probability of inflicting status (1.0 = guaranteed)
@export var tp_required: int = 0   # 0 = granted by Spekkio (available from start for now)
```

The `power` field serves double duty:
- **Damage techs** (`effect = ""`): used as `tech_power` in the magic damage formula.
- **Healing techs** (`effect = "heal"`): used as a multiplier — `heal = caster_magic * power`.

Authored as `.tres` files in `techs/crono/`, `techs/marle/`, `techs/lucca/`.

### CharacterData tech list

```gdscript
# Add to character_data.gd:
@export var techs: Array[TechData] = []  # ordered by unlock order
```

Each character's `.tres` file lists all their techs. At runtime, only techs where the character's accumulated TP meets `tp_required` are available. Spekkio techs (`tp_required = 0`) are available immediately (Spekkio encounter is Phase 8; for now, treat as pre-learned).

## Single Techs

### Crono (Lightning)

| # | Tech | TP Req | MP | Power | Element | Target | Effect |
|---|------|-------:|---:|------:|---------|--------|--------|
| 1 | Cyclone | 5 | 2 | 20 | — | self_circle | Spin-slash nearby enemies |
| 2 | Slash | 90 | 2 | 22 | — | line | Dash-slash enemies in line |
| 3 | Lightning | 0 | 2 | 25 | Lightning | single_enemy | Bolt of lightning |
| 4 | Spincut | 160 | 4 | 30 | — | single_enemy | Leap-slash |
| 5 | Lightning 2 | 500 | 8 | 45 | Lightning | all_enemies | Lightning on all |
| 6 | Luminaire | 1000 | 20 | 80 | Lightning | all_enemies | Massive lightning sphere |

Life (revive) deferred to Phase 5 (revive mechanic). Confuse deferred to Phase 7 (Chaos status).

### Marle (Water/Ice)

| # | Tech | TP Req | MP | Power | Element | Target | Effect |
|---|------|-------:|---:|------:|---------|--------|--------|
| 1 | Aura | 10 | 1 | 3 | — | single_ally | Heal: magic × 3 |
| 2 | Ice | 0 | 2 | 25 | Water | single_enemy | Ice shard |
| 3 | Cure | 150 | 2 | 5 | — | single_ally | Heal: magic × 5 |
| 4 | Haste | 250 | 6 | — | — | single_ally | Applies Haste status |
| 5 | Ice 2 | 400 | 8 | 45 | Water | all_enemies | Ice shards on all |
| 6 | Cure 2 | 600 | 5 | 4 | — | all_allies | Heal all: magic × 4 |

Provoke (Chaos status) deferred to Phase 7. Life 2 (revive) deferred to Phase 5.

### Lucca (Fire)

| # | Tech | TP Req | MP | Power | Element | Target | Effect |
|---|------|-------:|---:|------:|---------|--------|--------|
| 1 | Flame Toss | 10 | 1 | 18 | Fire | line | Burn enemies in line |
| 2 | Hypno Wave | 60 | 1 | — | — | all_enemies | Attempt Sleep (80% per target) |
| 3 | Fire | 0 | 2 | 25 | Fire | circle | Fire on enemies in circle |
| 4 | Napalm | 160 | 3 | 30 | Fire | circle | Fire bomb on area |
| 5 | Fire 2 | 400 | 8 | 45 | Fire | all_enemies | Flames on all |
| 6 | Mega Bomb | 600 | 15 | 60 | Fire | circle | Large fire explosion |
| 7 | Flare | 1000 | 20 | 80 | Fire | single_enemy | Massive fire blast |

Protect (status) deferred to Phase 5 (equipment defense system).

## TP accumulation and tech learning

### TP from battles

After victory, each living party member earns the encounter's total TP (sum of all enemies' `tp_reward`). KO'd members earn zero. TP is tracked cumulatively in PartyManager.

### Tech unlock check

When a member's `total_tp` meets or exceeds a tech's `tp_required`, that tech becomes available. The check happens each time the Tech submenu opens — no unlock notification for now.

### Starting TP for testing

Initialize all party members with 0 TP. Spekkio techs (tp_required = 0) are available from the start. To test higher-tier techs during development, temporarily increase starting TP or decrease enemy TP thresholds.

## Element system

### Elements

Four elements: `lightning`, `fire`, `water`, `shadow`. Non-elemental attacks and techs use an empty string.

### EnemyData additions

```gdscript
# Add to enemy_data.gd:
@export var magic_def: int = 0
@export var element_resist: Dictionary = {}
# Keys: "lightning", "fire", "water", "shadow"
# Values: float multiplier — 0.0 (immune), 0.5 (resist), 1.0 (normal), 2.0 (weak)
# Special value: -1.0 (absorb — heals instead of damaging)
# Missing keys default to 1.0 (normal damage)
```

### Imp element resistance (debug room)

The existing Imp gets `magic_def = 2` (no elemental resistances — all normal). Add a second enemy type — **Blue Imp** — weak to Fire, resists Water:

```
enemies/blue_imp.tres:
  enemy_name = "Blue Imp"
  max_hp = 13
  power = 3
  speed = 6
  stamina = 3
  magic_def = 2
  exp_reward = 2
  gold_reward = 6
  tp_reward = 1
  element_resist = { "fire": 2.0, "water": 0.5 }
```

Replace one Imp in `debug_room.tscn` with a Blue Imp. Create a blue imp sprite (recolor imp SVG).

### Element damage calculation

After calculating raw magic damage, multiply by the target's resistance:

```gdscript
var resist: float = enemy["data"].element_resist.get(element, 1.0)
if resist == -1.0:
    # Absorb: heal the target instead
    enemy["current_hp"] = mini(enemy["current_hp"] + damage, enemy["max_hp"])
    heal_applied.emit(enemy["node"].global_position, damage)
else:
    damage = int(damage * resist)
    enemy["current_hp"] = max(0, enemy["current_hp"] - damage)
```

Non-elemental techs (`element = ""`) skip resistance lookup entirely.

## Damage formulas

### Physical damage (unchanged)

`raw = max(1, power + weapon_ap - target_stamina)`, randomized ×0.9–1.1, doubled on crit.

### Magic damage (new)

```
raw = max(1, tech_power + caster_magic - target_magic_def)
damage = max(1, round(raw * randf_range(0.9, 1.1)))
damage = int(damage * element_multiplier)   # skip if non-elemental
```

No critical hits on magic. `tech_power` comes from `TechData.power`, `caster_magic` from `CharacterData.magic`, `target_magic_def` from `EnemyData.magic_def`.

### Healing formula

For techs with `effect = "heal"`:

```
heal = caster_magic * tech_power
```

Where `tech_power` is the `TechData.power` field repurposed as a heal multiplier. Examples with Marle (magic = 8):

| Tech | power | Heal amount |
|------|------:|------------:|
| Aura | 3 | 24 HP |
| Cure | 5 | 40 HP |
| Cure 2 | 4 | 32 HP per ally |

Healing is capped at the target's `max_hp`.

## Status effects

### Framework

Status effects are tracked per-combatant in the BattleManager dict:

```gdscript
"statuses": {}  # { "haste": turns_remaining, "poison": -1, ... }
# turns_remaining = -1 means permanent (until cured or battle ends)
```

Each time a combatant's ATB fills (reaches 1.0), tick down positive durations and apply per-tick effects (Poison). Remove statuses that reach 0. Statuses with duration -1 persist until explicitly removed (e.g., Sleep removed on damage).

### Phase 4 statuses

| Status | Type | Duration | Behavior | Hit chance |
|--------|------|----------|----------|------------|
| Haste | Buff | 6 ATB fills | ATB fill rate ×2 | Guaranteed (ally buff) |
| Slow | Debuff | 6 ATB fills | ATB fill rate ×0.5 | 80% |
| Poison | DoT | Permanent (-1) | Lose `max(1, max_hp * 0.05)` per ATB fill; floors at 1 HP | 80% |
| Sleep | Incapacitate | Permanent (-1) | ATB frozen; removed when damaged | 80% |

Haste and Slow are mutually exclusive — applying one removes the other.

### ATB speed modifier

In the ATB fill loop, apply status modifiers before filling:

```gdscript
if "sleep" in combatant["statuses"]:
    continue  # ATB frozen

var speed_mult := 1.0
if "haste" in combatant["statuses"]:
    speed_mult = 2.0
elif "slow" in combatant["statuses"]:
    speed_mult = 0.5
combatant["atb"] += combatant["data"].speed * delta * ATB_SCALE * speed_mult
```

### Sleep behavior

A sleeping combatant's ATB is frozen (skip ATB fill entirely). When the combatant takes any damage, Sleep is removed. A sleeping party member is skipped when popping the ready queue. A sleeping enemy skips its action when ATB fills (ATB resets but no attack).

### Poison behavior

Each time a poisoned combatant's ATB fills (reaches 1.0), they take `max(1, max_hp * 0.05)` damage. For party members, emit `party_hp_changed`. For enemies, emit `enemy_hp_changed`. Poison does **not** KO — HP floors at 1.

### Status sources in Phase 4

| Status | Source |
|--------|--------|
| Haste | Marle's Haste tech (guaranteed on ally) |
| Sleep | Lucca's Hypno Wave (80% per enemy) |
| Slow | No Phase 4 tech inflicts this — framework only, used by enemy AI in Phase 7 |
| Poison | No Phase 4 tech inflicts this — framework only, used by enemy AI in Phase 7 |

### Visual indicators

Add status text next to combatant names in the battle panel:

```
★Crono    HP: 70/70  MP: 8/10  ATB [████████]
 Marle    HP: 30/65  MP:12/12  ATB [██████░░]  HST
 Lucca    HP: 62/62  MP: 9/12  ATB [███░░░░░]
```

Short labels appended after the ATB bar: HST (Haste), SLW (Slow), PSN (Poison), SLP (Sleep). Only shown when active.

## Battle UI changes

### Updated battle panel layout

```
┌────────────────────────────────────────────────────────────────┐
│ ★Crono    HP: 70/70  MP: 8/10  ATB [████████]                 │
│  Marle    HP: 65/65  MP:12/12  ATB [██████░░]  HST            │
│  Lucca    HP: 62/62  MP: 9/12  ATB [███░░░░░]                 │
│                                                                │
│  Imp [████████]  Blue Imp [██████░░]  Imp [████████████]       │
└────────────────────────────────────────────────────────────────┘
```

### Tech command

The command menu expands from 2 to 3 options. Add a third label in `_build_ui`:

```
┌─────────┐
│> Attack  │
│  Tech    │
│  Item    │
└─────────┘
```

Update `_command_cursor` range: `min(2, ...)` and `_update_command_cursor` to handle 3 entries.

### Tech submenu

Selecting Tech opens a submenu listing the acting member's learned techs. The submenu dynamically creates labels based on tech count (not reusing the 3 command labels). Create a separate `_tech_labels: Array` in `_build_ui`, with enough capacity for 8 entries (max techs per character). Show a scrolling window of visible entries.

```
┌──────────────┐
│> Cyclone   2 │
│  Lightning 2 │
│  Spincut   4 │
└──────────────┘
```

Format: `tech_name  mp_cost`. Techs the caster can't afford (insufficient MP) are dimmed (modulate alpha 0.5) and cannot be confirmed when pressing interact. Unlearned techs are not shown.

Navigate with move_up/move_down, confirm with interact, cancel to return to command menu.

### Menu state approach

Track the pending action type instead of duplicating TARGET states:

```gdscript
enum MenuState { HIDDEN, COMMAND, TECH_LIST, ITEM_LIST, TARGET_ENEMY, TARGET_ALLY }

var _pending_action: String = ""  # "attack", "tech", "item"
var _selected_tech: TechData = null
```

When confirming a target:
- `_pending_action == "attack"` → call `_bm._on_attack_selected(target)`
- `_pending_action == "tech"` → call `_bm._on_tech_selected(_selected_tech, target)`
- `_pending_action == "item"` → call `_bm._on_item_used(_selected_item, target)`

This avoids duplicating TARGET_ENEMY_TECH/TARGET_ALLY_TECH states.

### Auto-confirm targets

For techs with `all_enemies`, `all_allies`, or `self_circle` target types, skip target selection entirely — confirm immediately after selecting the tech. In `_enter_tech_target`:

```gdscript
match tech.target_type:
    "all_enemies", "self_circle":
        _confirm_tech(tech, -1)  # -1 = no specific target needed
    "all_allies":
        _confirm_tech(tech, -1)
    "single_enemy", "line", "circle":
        # Enter enemy target selection
    "single_ally":
        # Enter ally target selection
```

## Battle manager changes

### New signals

```gdscript
signal party_mp_changed(combatant_index: int, current_mp: int, max_mp: int)
signal status_changed(combatant_index: int, is_player: bool, statuses: Dictionary)
signal tech_used(caster_index: int, tech_name: String)
```

`status_changed` replaces separate applied/removed signals — the UI just re-renders the full status dict.

### Tech execution flow

```gdscript
func _on_tech_selected(tech: TechData, target_index: int) -> void:
    if _active_member_index == -1 or _animating or _battle_finished:
        return

    var member_idx := _consume_active_turn()
    var p := _party[member_idx]

    # Deduct MP
    p["current_mp"] -= tech.mp_cost
    party_mp_changed.emit(member_idx, p["current_mp"], p["max_mp"])
    tech_used.emit(member_idx, tech.tech_name)

    # Resolve targets based on target_type
    var targets := _resolve_tech_targets(tech, member_idx, target_index)

    # Play tech animation
    await _play_tech_sequence(p["node"], targets, tech)

    # Apply effects per target
    for t in targets:
        match tech.effect:
            "heal":
                _apply_tech_heal(tech, p, t)
            "status":
                _apply_status(tech, t)
            _:
                _apply_tech_damage(tech, p, t)

    _check_battle_end()
```

### Tech animation sequence

`_play_tech_sequence` differs from `_play_attack_sequence`:
- **Single-target offensive**: lunge toward target (same as physical attack).
- **AoE / healing / status**: caster plays attack animation in-place (no lunge). Each target plays hit animation and shows a damage/heal number. Pause 0.3s per batch.

```gdscript
func _play_tech_sequence(caster: Node2D, targets: Array, tech: TechData) -> void:
    _animating = true
    caster.play_attack()

    if targets.size() == 1 and tech.effect == "" and targets[0]["is_enemy"]:
        # Single-target offensive: lunge like physical attack
        var target_node := _get_target_node(targets[0])
        var start_pos := caster.global_position
        var direction := (target_node.global_position - start_pos).normalized()
        if direction == Vector2.ZERO:
            direction = Vector2.RIGHT
        var lunge := create_tween()
        lunge.tween_property(caster, "global_position", start_pos + direction * 16.0, 0.15)
        await lunge.finished
        await get_tree().create_timer(0.3).timeout
        var retreat := create_tween()
        retreat.tween_property(caster, "global_position", start_pos, 0.15)
        await retreat.finished
    else:
        # Multi-target / heal / status: cast in place
        await get_tree().create_timer(0.4).timeout

    if not _battle_finished:
        caster.play_idle()
    _animating = false

func _get_target_node(target: Dictionary) -> Node2D:
    if target["is_enemy"]:
        return _enemies[target["index"]]["node"]
    else:
        return _party[target["index"]]["node"]
```

### Target resolution

```gdscript
func _resolve_tech_targets(tech: TechData, caster_idx: int, selected_target: int) -> Array:
    match tech.target_type:
        "single_enemy":
            return [{ "index": selected_target, "is_enemy": true }]
        "all_enemies":
            return get_living_enemies().map(func(i): return { "index": i, "is_enemy": true })
        "single_ally":
            return [{ "index": selected_target, "is_enemy": false }]
        "all_allies":
            return get_living_party().map(func(i): return { "index": i, "is_enemy": false })
        "line":
            return _get_line_targets(caster_idx, selected_target)
        "circle":
            return _get_circle_targets(selected_target)
        "self_circle":
            return _get_circle_targets_around(caster_idx)
    return []
```

### AoE helpers

```gdscript
const AOE_RADIUS := 80.0

func _get_line_targets(caster_idx: int, target_idx: int) -> Array:
    var caster_pos: Vector2 = _party[caster_idx]["node"].global_position
    var target_pos: Vector2 = _enemies[target_idx]["node"].global_position
    var direction := (target_pos - caster_pos).normalized()
    var results: Array = []
    for i in _enemies.size():
        if _enemies[i]["is_dead"]:
            continue
        var enemy_pos: Vector2 = _enemies[i]["node"].global_position
        var to_enemy := enemy_pos - caster_pos
        var proj := to_enemy.dot(direction)
        if proj > 0:
            var perp_dist := abs(to_enemy.cross(direction))
            if perp_dist < AOE_RADIUS:
                results.append({ "index": i, "is_enemy": true })
    return results

func _get_circle_targets(center_enemy_idx: int) -> Array:
    var center: Vector2 = _enemies[center_enemy_idx]["node"].global_position
    var results: Array = []
    for i in _enemies.size():
        if _enemies[i]["is_dead"]:
            continue
        if _enemies[i]["node"].global_position.distance_to(center) <= AOE_RADIUS:
            results.append({ "index": i, "is_enemy": true })
    return results

func _get_circle_targets_around(caster_idx: int) -> Array:
    var center: Vector2 = _party[caster_idx]["node"].global_position
    var results: Array = []
    for i in _enemies.size():
        if _enemies[i]["is_dead"]:
            continue
        if _enemies[i]["node"].global_position.distance_to(center) <= AOE_RADIUS:
            results.append({ "index": i, "is_enemy": true })
    return results
```

### Damage application

```gdscript
func _apply_tech_damage(tech: TechData, caster: Dictionary, target: Dictionary) -> void:
    var target_data: Dictionary
    if target["is_enemy"]:
        target_data = _enemies[target["index"]]
    else:
        target_data = _party[target["index"]]

    var magic_def: int = int(target_data["data"].get("magic_def", 0))
    var raw: int = maxi(1, tech.power + caster["data"].magic - magic_def)
    var damage: int = maxi(1, int(round(raw * _rng.randf_range(0.9, 1.1))))

    # Element resistance (enemies only for Phase 4)
    if tech.element != "" and target["is_enemy"]:
        var resist: float = target_data["data"].element_resist.get(tech.element, 1.0)
        if resist == -1.0:
            target_data["current_hp"] = mini(target_data["current_hp"] + damage, target_data["max_hp"])
            heal_applied.emit(target_data["node"].global_position, damage)
            if target["is_enemy"]:
                enemy_hp_changed.emit(target["index"], str(target_data["data"].get("enemy_name")), target_data["current_hp"], target_data["max_hp"])
            return
        damage = int(damage * resist)

    var node: Node2D = target_data["node"]
    node.play_hit(Vector2.ZERO)
    var flash := node.get_node_or_null("FlashEffect")
    if flash:
        flash.flash()

    target_data["current_hp"] = max(0, target_data["current_hp"] - damage)
    damage_dealt.emit(node.global_position, damage, false)

    # Remove Sleep on damage
    if "sleep" in target_data.get("statuses", {}):
        target_data["statuses"].erase("sleep")
        status_changed.emit(target["index"], target["is_enemy"], target_data["statuses"])

    if target["is_enemy"]:
        enemy_hp_changed.emit(target["index"], str(target_data["data"].get("enemy_name")), target_data["current_hp"], target_data["max_hp"])
        if target_data["current_hp"] <= 0:
            target_data["is_dead"] = true
            enemy_died.emit(target["index"])
            await target_data["node"].play_death()
    else:
        party_hp_changed.emit(target["index"], target_data["current_hp"], target_data["max_hp"])
        if target_data["current_hp"] <= 0:
            target_data["is_ko"] = true
            combatant_ko.emit(target["index"])

func _apply_tech_heal(tech: TechData, caster: Dictionary, target: Dictionary) -> void:
    var t: Dictionary = _party[target["index"]]
    var heal: int = caster["data"].magic * tech.power
    var old_hp: int = t["current_hp"]
    t["current_hp"] = mini(t["current_hp"] + heal, t["max_hp"])
    var healed: int = t["current_hp"] - old_hp
    party_hp_changed.emit(target["index"], t["current_hp"], t["max_hp"])
    heal_applied.emit(t["node"].global_position, healed)

func _apply_status(tech: TechData, target: Dictionary) -> void:
    var t: Dictionary
    if target["is_enemy"]:
        t = _enemies[target["index"]]
    else:
        t = _party[target["index"]]

    if tech.status_chance < 1.0 and _rng.randf() > tech.status_chance:
        return  # resisted

    var status := tech.status_effect
    var duration: int = -1  # permanent by default
    if status == "haste" or status == "slow":
        duration = 6
        # Mutually exclusive
        if status == "haste":
            t["statuses"].erase("slow")
        else:
            t["statuses"].erase("haste")

    t["statuses"][status] = duration
    status_changed.emit(target["index"], target["is_enemy"], t["statuses"])
```

### Status tick in _process

Add status processing after ATB fill:

```gdscript
# After ATB reaches 1.0 for party members:
if _party[i]["atb"] >= 1.0:
    _tick_statuses(_party[i], i, true)
    # ... existing ready queue logic

# After ATB reaches 1.0 for enemies (before acting):
if _enemies[i]["atb"] >= 1.0:
    _tick_statuses(_enemies[i], i, false)
    # ... existing enemy act logic
```

```gdscript
func _tick_statuses(combatant: Dictionary, index: int, is_player: bool) -> void:
    var changed := false
    var to_remove: Array = []
    for status in combatant["statuses"]:
        # Tick duration
        if combatant["statuses"][status] > 0:
            combatant["statuses"][status] -= 1
            if combatant["statuses"][status] == 0:
                to_remove.append(status)
                changed = true
        # Poison tick
        if status == "poison":
            var poison_dmg: int = maxi(1, int(combatant["max_hp"] * 0.05))
            combatant["current_hp"] = maxi(1, combatant["current_hp"] - poison_dmg)
            if is_player:
                party_hp_changed.emit(index, combatant["current_hp"], combatant["max_hp"])
                damage_dealt.emit(combatant["node"].global_position, poison_dmg, false)
            else:
                enemy_hp_changed.emit(index, str(combatant["data"].get("enemy_name", "")), combatant["current_hp"], combatant["max_hp"])
            changed = true

    for s in to_remove:
        combatant["statuses"].erase(s)
    if changed:
        status_changed.emit(index, is_player, combatant["statuses"])
```

## Debug room changes

Add a Blue Imp enemy with Fire weakness to test element damage. Add `magic_def = 2` to the existing Imp.

Replace one of the three Imps in `debug_room.tscn` with a Blue Imp (different encounter group or same group "a").

Create `enemies/blue_imp_sheet.svg` by recoloring the imp sprite blue. Export to PNG.

## Folder structure additions

```
res://
├── techs/
│   ├── crono/     — TechData .tres files (cyclone.tres, slash.tres, ...)
│   ├── marle/     — TechData .tres files (aura.tres, ice.tres, ...)
│   └── lucca/     — TechData .tres files (flame_toss.tres, fire.tres, ...)
```

## What we skip

- Dual Techs, Triple Techs — Phase 9.
- Revive techs (Life, Life 2) — Phase 5 adds revive mechanic.
- Chaos status (Confuse, Provoke) — Phase 7 with advanced enemy AI.
- Protect/Barrier/Shield statuses — Phase 5 with equipment defense system.
- Tech-specific animations — all techs reuse the attack/lunge or in-place cast animation. Visual polish deferred.
- Spekkio encounter for granting element techs — Phase 8 (End of Time). For now, Spekkio techs (tp_required = 0) are available from the start.
- Enemy magic attacks — Phase 7 (enemy AI). Slow and Poison are implemented but not inflicted by any Phase 4 tech.
- MP recovery items/inns — Phase 5/6.

## Test checklist

### MP system
- [ ] MP displayed in battle panel for each party member
- [ ] Using a tech reduces caster's MP
- [ ] Techs with insufficient MP are visible but not selectable (dimmed)
- [ ] MP persists across battles (via PartyManager)
- [ ] MP is correct on battle start (matches PartyManager state)
- [ ] MP written back after victory and escape

### Tech command
- [ ] Command menu shows Attack / Tech / Item (3 options)
- [ ] Selecting Tech opens tech submenu
- [ ] Tech submenu lists learned techs with MP costs
- [ ] Unlearned techs are not shown
- [ ] Unaffordable techs are dimmed and can't be confirmed
- [ ] Cancel returns to command menu
- [ ] Tech submenu scrolls when more techs than visible labels

### Tech usage — damage
- [ ] Single-target tech (Lightning, Spincut, Flare) hits one enemy
- [ ] All-enemies tech (Lightning 2, Ice 2, Fire 2) hits every living enemy
- [ ] Line tech (Slash, Flame Toss) hits enemies along the direction
- [ ] Circle tech (Fire, Napalm, Mega Bomb) hits enemies near the target
- [ ] Self-circle tech (Cyclone) hits enemies near the caster
- [ ] Tech damage uses magic damage formula (tech_power + magic - magic_def)
- [ ] Damage numbers appear for each hit target
- [ ] AoE auto-confirms (no target selection for all_enemies, self_circle)
- [ ] Multi-target techs apply damage to each target independently

### Tech usage — healing
- [ ] Aura heals a single ally (magic × 3)
- [ ] Cure heals a single ally (magic × 5)
- [ ] Cure 2 heals all living allies (magic × 4 each)
- [ ] Healing numbers appear in green
- [ ] Healing is capped at max HP
- [ ] KO'd allies cannot be targeted for heals

### Element system
- [ ] Elemental tech deals normal damage to enemies with no resistance entry
- [ ] Elemental tech deals double damage to weak enemies (2.0)
- [ ] Elemental tech deals half damage to resistant enemies (0.5)
- [ ] Elemental tech deals zero damage to immune enemies (0.0)
- [ ] Absorb (-1.0) heals the enemy instead of damaging
- [ ] Non-elemental techs ignore element resistance
- [ ] Blue Imp takes double Fire damage and half Water damage

### Status effects
- [ ] Haste doubles ATB fill rate for 6 ATB cycles
- [ ] Haste expires after duration
- [ ] Slow halves ATB fill rate (framework test — apply via debug)
- [ ] Haste and Slow are mutually exclusive
- [ ] Poison deals 5% max HP per ATB fill, floors at 1 HP (framework test)
- [ ] Sleep freezes ATB completely
- [ ] Sleep removed when combatant takes damage
- [ ] Sleeping party members are skipped in ready queue
- [ ] Sleeping enemies don't act when ATB fills
- [ ] Hypno Wave attempts Sleep on all enemies (80% per target, some may resist)
- [ ] Status indicators (HST, SLW, PSN, SLP) appear in battle panel

### TP and tech learning
- [ ] Living party members earn TP on victory
- [ ] KO'd party members earn zero TP
- [ ] TP accumulates across battles (persists in PartyManager)
- [ ] Techs appear in submenu when TP threshold is met
- [ ] Spekkio techs (tp_required = 0) are available from the start
- [ ] Higher-tier techs remain locked until sufficient TP

### Battle flow integration
- [ ] Tech turn consumes ATB gauge like Attack/Item
- [ ] Tech animation plays (lunge for single offensive, in-place for AoE/heal)
- [ ] Multiple targets all show damage/heal numbers
- [ ] Battle ends correctly after tech kills last enemy
- [ ] Game over still works if all party members reach 0 HP
- [ ] Escape still works during tech-enabled battles
- [ ] Menu stays visible during enemy attacks (Phase 3 behavior preserved)
- [ ] Confirming tech during enemy animation is blocked (Phase 3 behavior preserved)
