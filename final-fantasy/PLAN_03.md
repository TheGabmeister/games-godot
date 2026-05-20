# Phase 3 — Turn-Based Combat: Implementation Plan

## Overview

Add the full battle engine: physical attacks, multi-hit, critical hits, turn order, formation targeting, battle rewards, leveling, item use (Potion), Run, enemy AI, victory sequence, and Game Over. This builds on the existing WorldSession/GameState/PartyData architecture from Phases 1-2.

### Scope boundaries

**In scope:** Physical attacks, damage formula, multi-hit, critical hits, auto-retarget, formation targeting, Run command, Item command (Potion only), basic enemy AI (physical attacks), battle rewards (EXP/Gil), deterministic level-up stat growth, victory fanfare + reward screens, Game Over → title, 5 starter enemies, pre-equipped starter gear (data model), encounter trigger system, small field area outside Cornelia, battle transition effect.

**Out of scope:** Magic command (Phase 4), status effects beyond KO (Phase 4-5), elemental damage (Phase 4), equipment equip/unequip UI (Phase 7), shops (Phase 4+), pre-emptive/ambush (Phase 6), boss encounters (Phase 6), save system (Phase 8), inn healing (Phase 7).

---

## Architecture Decisions

### Battle scene integration

BattleScene is a **CanvasLayer** (layer 20) child of WorldSession, same pattern as DialogueBox (layer 10) and PartyMenu (layer 10). WorldSession instantiates it, passes `party_data`. The field level stays loaded underneath but is hidden during combat.

```
WorldSession (Node)
├── PartyData
├── Warrior (frozen, hidden during battle)
├── DialogueBox (CanvasLayer 10)
├── PartyMenu (CanvasLayer 10)
├── BattleScene (CanvasLayer 20)
│   ├── Background (TextureRect)
│   ├── BattlerContainer (Node2D)
│   │   ├── Enemy Sprite2Ds
│   │   └── Party Sprite2Ds
│   ├── BattleHUD (Control)
│   │   ├── BottomBar (party status)
│   │   ├── CommandMenu (popup)
│   │   ├── ItemSelectPanel
│   │   └── TargetCursor
│   ├── DamageNumberContainer (Node2D)
│   ├── VictoryPanel (Control)
│   └── GameOverOverlay (ColorRect + Label)
└── [Current Level] (hidden during battle)
```

### Battle state machine

Single enum in BattleScene, same pattern as PartyMenu's `match _current_screen`:

```
enum BattlePhase {
  INACTIVE,        # battle scene hidden
  INTRO,           # transition effect playing
  COMMAND_SELECT,  # picking Attack/Magic(disabled)/Item/Run
  TARGETING,       # choosing enemy target
  ITEM_SELECT,     # choosing item from inventory
  ITEM_TARGET,     # choosing ally to use item on
  RESOLVING,       # building turn order queue
  ANIMATING,       # playing actions sequentially (await-driven)
  VICTORY,         # fanfare + reward screens
  GAME_OVER        # all KO'd, waiting for dismiss
}
```

Input dispatch uses `match _battle_phase` in `_input()`, gated by `GameState.is_state(GameState.State.BATTLE)`.

### Command input flow

Index-driven loop with `_command_index` (0-3):

1. `_command_index = 0`, show command menu for `party[0]`
2. Player picks Attack → go to TARGETING (enemy select)
3. Confirm target → store command, `_command_index++`
4. Cancel in TARGETING → back to COMMAND_SELECT for same character
5. Cancel in COMMAND_SELECT → `_command_index--` to re-pick previous character (clamp at 0)
6. Item → ITEM_SELECT → pick item → ITEM_TARGET → pick ally → store command
7. Run → immediate flee attempt (see Run section)
8. When `_command_index == 4` → transition to RESOLVING

Commands stored in `Array[BattleCommand]` where BattleCommand holds: type (ATTACK/ITEM/RUN), actor Battler, target Battler, item reference.

### Turn resolution

Await-based sequential processing:

1. **RESOLVING:** Build action queue — merge party commands + enemy AI commands, sort by Agility (ties broken by `randi()`). Transition to ANIMATING.
2. **ANIMATING:** Loop through sorted actions:
   - Skip dead actors
   - Auto-retarget if target is dead (next alive in formation order)
   - Calculate damage (multi-hit loop for attacks)
   - Play animation (sprite lunge tween + staggered damage popups)
   - `await` animation completion signal
   - Apply damage to Battler HP → sync to CharacterData/EnemyData
   - Update HUD
   - Check for battle end (all enemies dead → VICTORY, all party dead → GAME_OVER)
3. If round ends without battle end → loop back to COMMAND_SELECT with `_command_index = 0`

---

## Data Model

### EnemyData (Resource)

New file: `scripts_consts/enemy_data.gd`

```gdscript
class_name EnemyData
extends Resource

@export var enemy_name: String
@export var max_hp: int
@export var attack: int       # AttackPower
@export var accuracy: int     # Hit%
@export var num_hits: int     # number of attacks per turn
@export var defense: int      # Absorb
@export var agility: int
@export var evade: int        # Evade%
@export var magic_defense: int
@export var exp_reward: int
@export var gil_reward: int
@export var sprite: Texture2D
```

Resource files in `data/enemies/`: `goblin.tres`, `goblin_guard.tres`, `wolf.tres`, `black_widow.tres`, `gigas_worm.tres`.

### Starter enemies (from PHASES.md)

| Enemy | HP | ATK | DEF | AGI | EVA | EXP | Gil |
|-------|-----|-----|-----|-----|-----|-----|-----|
| Goblin | 8 | 4 | 2 | 6 | 6 | 6 | 6 |
| Goblin Guard | 16 | 8 | 4 | 6 | 6 | 18 | 18 |
| Wolf | 20 | 8 | 0 | 12 | 12 | 24 | 12 |
| Black Widow | 28 | 12 | 2 | 8 | 8 | 30 | 15 |
| Gigas Worm | 52 | 16 | 4 | 4 | 4 | 60 | 30 |

### EquipmentData (Resource)

New file: `scripts_consts/equipment_data.gd`

```gdscript
class_name EquipmentData
extends Resource

enum Slot { WEAPON, SHIELD, BODY, HEAD, ARMS }

@export var equip_name: String
@export var slot: Slot
@export var attack_power: int     # weapons only
@export var absorb: int           # armor
@export var evade_penalty: int    # armor (subtracted from Evade%)
@export var hit_percent: int      # weapons
@export var weapon_index: int     # crit rate for armed attacks
@export var price: int
```

Resource files in `data/equipment/` for starter gear.

### Starter equipment (from PHASES.md)

| Item | Slot | ATK | Absorb | Evade Pen | Hit% | Wpn Index | Equipped by |
|------|------|-----|--------|-----------|------|-----------|-------------|
| Rapier | Weapon | 9 | — | — | 10 | 5 | Warrior |
| Nunchaku | Weapon | 12 | — | — | 0 | 3 | Monk |
| Hammer | Weapon | 9 | — | — | 0 | 2 | White Mage |
| Knife | Weapon | 5 | — | — | 10 | 5 | Black Mage |
| Leather Shield | Shield | — | 2 | 2 | — | — | Warrior |
| Leather Armor | Body | — | 4 | 3 | — | — | Warrior |
| Leather Cap | Head | — | 1 | 1 | — | — | Warrior |
| Leather Gloves | Arms | — | 1 | 1 | — | — | All |
| Clothes | Body | — | 1 | 0 | — | — | Monk, W.Mage, B.Mage |

### CharacterData equipment slots

Add to existing CharacterData in `party_data.gd`:

```gdscript
var weapon: EquipmentData    # nullable
var shield: EquipmentData    # nullable
var body_armor: EquipmentData
var head_armor: EquipmentData
var arm_armor: EquipmentData
```

Computed properties for battle:

```gdscript
func get_attack_power() -> int:
    # Monk unarmed: Level × 2
    if weapon == null and job == Job.MONK:
        return level * 2
    return strength / 2 + (weapon.attack_power if weapon else 0)

func get_absorb() -> int:
    # Monk unarmored: Level
    if body_armor == null and shield == null and head_armor == null and arm_armor == null and job == Job.MONK:
        return level
    var total := 0
    for piece in [shield, body_armor, head_armor, arm_armor]:
        if piece:
            total += piece.absorb
    return total

func get_evade() -> int:
    var total := 48 + agility
    for piece in [shield, body_armor, head_armor, arm_armor]:
        if piece:
            total -= piece.evade_penalty
    return total

func get_hit_percent() -> int:
    var base := weapon.hit_percent if weapon else 80  # 80% base for unarmed Monk
    return base + _hit_percent_from_level()

func get_max_hits() -> int:
    return get_hit_percent() / 32 + 1

func get_crit_rate() -> int:
    if weapon:
        return weapon.weapon_index
    if job == Job.MONK:
        return level * 2
    return 0
```

Pre-equip starter gear in `PartyData._ready()` after creating characters.

### EncounterData (Resources)

New file: `scripts_consts/encounter_data.gd`

```gdscript
class_name EncounterFormation
extends Resource

@export var entries: Array[EnemyEntry]
@export var weight: int = 1

class EnemyEntry extends Resource:
    @export var enemy: EnemyData
    @export var count: int = 1
```

```gdscript
class_name EncounterTable
extends Resource

@export var battle_background: Texture2D
@export var formations: Array[EncounterFormation]
@export var can_flee: bool = true
@export var steps_min: int = 20
@export var steps_max: int = 30
```

Add to LevelData: `@export var encounter_table: EncounterTable` (null for towns = no encounters).

### Battler wrapper (inner class in battle_scene.gd)

```gdscript
class Battler:
    var display_name: String
    var max_hp: int
    var current_hp: int
    var agility: int
    var is_party: bool
    var party_index: int = -1
    var character_data: PartyData.CharacterData  # null for enemies
    var enemy_data: EnemyData                    # null for party
    var sprite: Sprite2D
    var home_position: Vector2

    func is_dead() -> bool:
        return current_hp <= 0
```

Party Battlers sync HP changes back to CharacterData. Enemy Battlers are ephemeral.

---

## Combat Formulas

All formulas from SPEC.md §1.3:

### Physical damage (per hit)

```
Damage = randi_range(AttackPower, AttackPower × 2) − target.Absorb
Minimum 1 per hit
```

### AttackPower

```
Player: Strength / 2 + WeaponDamage
Monk unarmed: Level × 2
Enemy: enemy_data.attack
```

### Number of hits

```
MaxHits = floor(Hit% / 32) + 1
```

Hit% grows per level: Warrior/Monk +3/level, White Mage/Black Mage +1/level.

### Hit probability (per individual hit)

```
BaseChance = 168  (out of 200)
HitChance = BaseChance + AttackerHit% − DefenderEvade%
Roll 1-200; hit if roll <= HitChance
```

### Critical hits

```
CritRate = WeaponIndex (armed) | Level × 2 (Monk unarmed) | 0 (other unarmed)
Roll 1-200; crit if roll <= CritRate
Crits ignore target Absorb — full random damage applies
```

Crit check shares the hit roll: a successful hit with a low roll is more likely to be a crit. Implementation: if the hit roll also falls within CritRate, it's a critical hit.

### Enemy damage

```
Damage per hit = randi_range(enemy.attack, enemy.attack × 2) − target.Absorb
Number of hits = enemy_data.num_hits (usually 1 for Phase 3 enemies)
Same hit/miss roll as player attacks
```

### Run success

```
Chance = party_avg_luck × 2 − enemy_avg_agility + 80
Roll 1-100; flee if roll <= Chance
Bosses: always fail (encounter.can_flee = false)
```

### Formation targeting (enemy AI)

Authentic FF1 weights per party position:

| Position | Weight | Probability |
|----------|--------|-------------|
| Slot 0 (front) | 8 | 50% |
| Slot 1 | 4 | 25% |
| Slot 2 | 2 | 12.5% |
| Slot 3 (rear) | 2 | 12.5% |

Dead targets cause re-roll.

### EXP distribution

```
Total EXP = sum of all enemy exp_reward
Per survivor = Total EXP / alive_party_count  (integer division)
Gil = sum of all enemy gil_reward  (full amount, not split)
```

---

## Leveling System

Deterministic stat growth stored as const tables in `party_data.gd`. Each job has an array of stat values per level. `CharacterData.level_up()` looks up the next level's stats and returns a diff dictionary for the level-up display.

```gdscript
func level_up() -> Dictionary:
    level += 1
    var old_stats := { "hp": max_hp, "str": strength, ... }
    _apply_level_stats()  # reads from GROWTH table
    current_hp = max_hp   # full heal on level up
    return { "hp": max_hp - old_stats["hp"], "str": strength - old_stats["str"], ... }
```

Hit% growth: Warriors/Monks +3/level, others +1/level. Tracked internally.

EXP thresholds per level: stored as a const array. Check `current_exp >= EXP_TABLE[level]` to trigger level-up. Multiple level-ups possible from a single battle.

---

## Encounter System

### Step counter (in player_movement.gd)

```gdscript
var _step_accumulator: float = 0.0
var _step_count: int = 0
var _steps_to_encounter: int = 0  # randomized from encounter table

func _physics_process(delta):
    # ... existing movement ...
    if velocity.length() > 0 and _encounter_table:
        _step_accumulator += velocity.length() * delta
        while _step_accumulator >= 64.0:  # one tile width
            _step_accumulator -= 64.0
            _step_count += 1
            if _step_count >= _steps_to_encounter:
                _trigger_encounter()
```

`_encounter_table` is set when the level loads (WorldSession reads LevelData.encounter_table and passes it to the player). Null for towns — no step counting.

`_trigger_encounter()` picks a weighted random formation, then signals WorldSession to start battle.

### Battle initiation flow

1. Player step counter hits threshold
2. Player emits `encounter_triggered(formation: EncounterFormation)` signal
3. WorldSession receives signal, calls `_start_battle(formation)`
4. WorldSession calls `GameState.transition(GameState.State.BATTLE)`
5. BattleScene reacts to `state_changed`, runs transition effect, starts combat

---

## Battle Transition

Flash + fade using a dedicated ColorRect on the BattleScene CanvasLayer:

1. White flash (ColorRect alpha 0→1 over 0.1s)
2. Hold white (0.05s)
3. Fade to black (0.3s)
4. Swap visibility: hide field, show battle scene contents
5. Fade from black to clear (0.3s)

Total: ~0.75s. Implemented with a single Tween chain.

---

## Visual Feedback

### Damage numbers

Spawn Label nodes at the target's position. Tween upward (y - 40) + fade out over 0.8s. Colors:
- **White:** normal damage
- **Yellow:** critical hit
- **Green:** healing
- **"Miss"** text for misses

### Multi-hit display

Calculate all hits at once, display with 0.15s stagger between each popup. Each hit gets its own damage number. Satisfying rapid-fire feel.

### Attack animation

**Party members:** Sprite tweens forward (lunge toward target over 0.15s), holds briefly, returns to home position. Target sprite flashes white on hit.

**Enemies:** Sprite flashes white in place (modulate to white for 2-3 frames, ~0.1s) — enemies do not move. Target (party member) sprite flashes white on hit. This matches the original FF1 behavior where enemies blink to indicate their attack.

### Enemy death

Fade-out tween (alpha 1→0 over 0.3s), then hide sprite.

### Critical hit

Damage number in yellow + screen flash (subtle white flash, 0.05s) on the hit frame.

---

## Battle HUD Layout

Reference: `docs/ff1/battle_menu.png`, `docs/ff1/battle_victory.png`

### Bottom status bar (persistent during battle)

Full-width bar at the bottom of the viewport. 4 columns, one per party member. Each column shows:
- Character name (top)
- HP / MaxHP (below)

Blue-tinted panel background, white text. Uses `menu_theme.tres` styling.

### Command menu (popup during COMMAND_SELECT)

Small box that appears above the bottom bar, aligned to the left side. Contains:
- `> Attack`
- `  Magic` (greyed out / disabled for Phase 3)
- `  Item`
- `  Run`

Uses GameButton instances with cursor prefix. Active character's name highlighted in the status bar.

### Enemy targeting cursor

Blinking arrow sprite (or `>` character) next to the selected enemy. Controlled by up/down input. Wraps around alive enemies.

### Item select panel

Centered panel listing inventory items. Shows item name and quantity. Uses GameButton for entries.

### Party target panel (for items)

Panel listing alive party members for item targeting. Same GameButton pattern.

### Victory panel

Centered blue panel (reference: `battle_victory.png`):
- "Enemies defeated!" header
- "EXP: {amount}  Gil: {amount}"
- [Confirm to advance]
- Per-character level-up screens if applicable

### Game Over overlay

Full-screen dark overlay. "Game Over" centered in large text. Game Over theme plays. Auto-advance after 3s or on confirm. Calls `get_tree().change_scene_to_file("res://title_screen.tscn")`.

---

## Battle Background

EncounterTable resource includes a `battle_background: Texture2D` export. For Phase 3, create one grass field background (1280×720 PNG, or generated SVG→PNG). BattleScene loads it into a TextureRect that fills the viewport above the bottom status bar.

---

## Cornelia Outskirts Level

New level scene: `cornelia_outskirts.tscn`

- Small tilemap (~30×20 tiles) of grass, paths, a few trees
- Connected to Cornelia town via door trigger at the south gate of Cornelia
- LevelData with:
  - `music`: field theme (new track or reuse town theme)
  - `encounter_table`: `cornelia_outskirts_encounters.tres`
  - `default_spawn`: north edge (entering from town)
- Door trigger back to Cornelia at the north edge

### Encounter formations

| Formation | Weight | Enemies |
|-----------|--------|---------|
| Goblin ×2 | 4 | Easy starter |
| Goblin ×3 | 3 | Slightly harder |
| Wolf ×1 | 3 | Fast single enemy |
| Wolf ×1 + Goblin ×1 | 3 | Mixed |
| Goblin Guard ×1 | 2 | Tanky single |
| Goblin Guard ×1 + Goblin ×2 | 2 | Mixed hard |
| Black Widow ×1 | 1 | High ATK |
| Gigas Worm ×1 | 1 | Boss-tier trash mob |

Steps between encounters: 20-30 (from EncounterTable).

---

## Battle Positions

1280×720 viewport. Bottom bar takes ~100px. Battle area is ~1280×620.

### Party positions (right side, staggered diagonal)

```
PARTY_POSITIONS := [
    Vector2(950, 180),   # slot 0 — front top
    Vector2(990, 280),   # slot 1 — front middle
    Vector2(1030, 380),  # slot 2 — back middle
    Vector2(1070, 480),  # slot 3 — back bottom
]
```

### Enemy positions (left side, centered based on count)

Dynamically calculated: center enemies vertically in the battle area with 80-100px spacing. X position around 200-350px, with slight variance for visual depth.

---

## Assets Required

### Sprites (already partially generated)

**Party battle stances** (already exist as `*_battle.png`):
- `characters/warrior/warrior_battle.png` (64×96)
- `characters/monk/monk_battle.png` (64×96)
- `characters/white_mage/white_mage_battle.png` (64×96)
- `characters/black_mage/black_mage_battle.png` (64×96)

**Enemy sprites** (need to generate):
- `enemies/goblin.png` (~64×64)
- `enemies/goblin_guard.png` (~64×64)
- `enemies/wolf.png` (~64×64)
- `enemies/black_widow.png` (~64×64)
- `enemies/gigas_worm.png` (~80×80, larger)

**Targeting cursor:**
- `ui/target_cursor.png` (small arrow, ~16×16)

### Battle background

- `battlegrounds/grass_field.png` (1280×620) — SVG→PNG via Inkscape

### Tilemap

- Cornelia outskirts tileset — reuse existing `cornelia_tileset.tres` (grass, paths, trees already in it)
- Cornelia outskirts map layout in `cornelia_outskirts.tscn`

### Audio

**Music** (generate via Python MIDI → fluidsynth → ffmpeg):
- `music/battle_theme.ogg` — normal battle music (already exists)
- `music/victory_fanfare.ogg` — short fanfare (already exists)
- `music/game_over.ogg` — game over theme (already exists)

**SFX** (generate via ffmpeg synthesis):
- `sfx/attack_swing.ogg` — weapon swing
- `sfx/attack_hit.ogg` — physical hit impact
- `sfx/attack_miss.ogg` — whiff
- `sfx/critical_hit.ogg` — crit impact (sharper/louder hit)
- `sfx/enemy_death.ogg` — enemy defeated
- `sfx/level_up.ogg` — level-up jingle
- `sfx/battle_start.ogg` — encounter sting (short)
- `sfx/run_fail.ogg` — failed escape attempt

---

## Implementation Order

### Step 1: Data model foundations

1. Create `EquipmentData` resource class (`scripts_consts/equipment_data.gd`)
2. Create starter equipment `.tres` files in `data/equipment/`
3. Add equipment slots to `CharacterData` in `party_data.gd`
4. Add computed properties: `get_attack_power()`, `get_absorb()`, `get_evade()`, `get_hit_percent()`, `get_max_hits()`, `get_crit_rate()`
5. Pre-equip starter gear in `PartyData._ready()`
6. Add EXP tracking to CharacterData: `current_exp: int`, `exp_to_next: int`
7. Add level-up stat growth tables and `level_up()` method
8. Create `EnemyData` resource class (`scripts_consts/enemy_data.gd`)
9. Create 5 enemy `.tres` files in `data/enemies/`
10. Create `EncounterFormation` and `EncounterTable` resource classes (`scripts_consts/encounter_data.gd`)
11. Add `encounter_table: EncounterTable` export to `LevelData`
12. Add `BATTLE_SCENE` to `Groups` constants

### Step 2: Encounter trigger

1. Add step counter logic to `player_movement.gd`
2. Add `encounter_triggered` signal on player
3. Wire WorldSession to receive encounter signal
4. Create `cornelia_outskirts.tscn` level with tilemap + door triggers
5. Create `cornelia_outskirts_encounters.tres` encounter table resource
6. Add door trigger from Cornelia town south gate to outskirts

### Step 3: Battle scene shell

1. Create `_scenes/battle_scene.tscn` (CanvasLayer, layer 20)
2. Create `scripts/battle/battle_scene.gd` with BattlePhase enum
3. Add WorldSession export + instantiation for battle scene
4. Wire `GameState.state_changed` → battle scene open/close
5. Implement battle transition effect (flash + fade)
6. Add battle background TextureRect
7. Generate grass field battle background asset

### Step 4: Battle sprites & layout

1. Generate 5 enemy sprites (SVG → PNG)
2. Implement Battler wrapper class
3. Spawn party Sprite2D nodes at PARTY_POSITIONS
4. Spawn enemy Sprite2D nodes with dynamic positioning
5. Implement targeting cursor display

### Step 5: Battle HUD

1. Build bottom status bar (4-column party status: name + HP)
2. Build command menu popup (Attack, Magic disabled, Item, Run)
3. Build enemy targeting panel
4. Build item select panel
5. Build party target panel (for items)
6. Wire up GameButton + cursor movement with SFX

### Step 6: Command input

1. Implement COMMAND_SELECT phase with `_command_index` loop
2. Implement TARGETING phase (enemy selection)
3. Implement ITEM_SELECT phase
4. Implement ITEM_TARGET phase (ally selection)
5. Implement Run command (immediate resolution)
6. Cancel navigation between phases

### Step 7: Combat formulas

1. Create `scripts/battle/battle_formulas.gd` with static functions
2. Implement physical damage formula (per hit)
3. Implement multi-hit calculation with per-hit hit/miss rolls
4. Implement critical hit calculation
5. Implement enemy AI targeting (formation weights)
6. Implement enemy damage calculation
7. Implement Run success formula
8. Implement EXP distribution formula

### Step 8: Turn resolution

1. Build sorted action queue (party commands + enemy AI, sorted by AGI)
2. Implement auto-retarget for dead targets
3. Implement await-based sequential action processing loop
4. Implement attack animation (sprite lunge tween)
5. Implement staggered damage number popups (Label + Tween)
6. Implement hit flash on targets
7. Implement enemy death fade-out
8. Implement item use resolution (heal + green number popup)
9. Implement battle-end checks after each action

### Step 9: Victory & rewards

1. Implement VICTORY phase transition
2. Play victory fanfare via MusicManager
3. Show EXP/Gil reward panel
4. Distribute EXP to alive party members
5. Check for level-ups, display stat gain screens
6. Fade out battle, transition back to FIELD
7. Resume field music

### Step 10: Game Over

1. Implement GAME_OVER phase detection
2. Play Game Over theme
3. Show Game Over overlay with text
4. Auto-advance or confirm → `change_scene_to_file` to title screen

### Step 11: Audio & polish

1. Generate battle SFX (swing, hit, miss, crit, enemy death, level-up, battle start)
2. Wire SFX to combat actions via SfxManager
3. Wire battle/victory/game over music via MusicManager
4. Test and tune damage numbers, timing, tween durations
5. Test multi-hit display timing
6. Test full battle loop: encounter → fight → victory → field return
7. Test Game Over flow → title screen

### Step 12: Integration testing

1. Walk from Cornelia to outskirts, trigger encounter
2. Fight all 5 enemy types across multiple formations
3. Test multi-hit attacks (Warrior with Rapier should get 1 hit at level 1)
4. Test critical hits
5. Test auto-retarget (kill enemy before another character acts)
6. Test item use (Potion) in battle
7. Test Run command (succeed and fail)
8. Test formation targeting (front characters get hit more)
9. Test EXP distribution and level-up
10. Test Game Over (let all party members die)
11. Test return to Cornelia town after battle
12. Verify PartyMenu still works correctly during MENU state
13. Verify dialogue still works correctly during DIALOGUE state
