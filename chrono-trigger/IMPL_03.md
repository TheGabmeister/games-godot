# Phase 3 — Party and multi-enemy combat

## Goal

Expand the battle system from 1v1 to 3v3. Three party members (Crono, Marle, Lucca) each have their own ATB gauge. Multiple enemies per encounter, with basic AI targeting random party members. Add the Item command (Tonic only) and an escape mechanic. Game over triggers when all three party members are KO'd.

## What we're building on

From Phase 2 we have: ATB combat loop, damage formula, attack animations, signal-driven battle_manager/battle_ui architecture, reusable FlashEffect component, entity scenes (player.tscn, enemy.tscn). Phase 3 generalizes everything from single combatant to arrays of combatants.

## Gameplay scene architecture

BattleManager, Inventory, and UI layers only exist during gameplay — not on a title screen or credits. Instead of autoloads, they live as children of a **gameplay scene** that wraps the current level.

```
scenes/gameplay.tscn (Node)
├── PartyManager      — party_manager.gd (runtime party state)
├── BattleManager     — battle_manager.gd
├── Inventory         — inventory.gd
├── BattleUI          — battle_ui.gd (CanvasLayer)
├── DialogueBox       — dialogue_box.gd (CanvasLayer)
└── Level             — the current level scene (debug_room.tscn), swapped per area
    ├── walls, floor
    ├── Player, Marle, Lucca
    ├── Enemies
    ├── NPC
    └── Camera
```

`gameplay.tscn` becomes the **main scene** in `project.godot` (replacing `debug_room.tscn`). The level is pre-loaded as the Level child. When a title screen is added in a later phase, the title screen becomes the main scene and instantiates `gameplay.tscn` on "New Game."

### Finding gameplay systems

Scripts inside the level (enemy.gd, npc.gd) need to find BattleManager, DialogueBox, etc. which now live outside their scene. Use **groups** instead of hard-coded paths.

Group name constants live in a single file to avoid magic strings:

```gdscript
# groups.gd
class_name Groups

const PARTY_MANAGER := "party_manager"
const BATTLE_MANAGER := "battle_manager"
const INVENTORY := "inventory"
const DIALOGUE_BOX := "dialogue_box"
```

Each gameplay system registers itself in `_ready()`:
```gdscript
# In battle_manager.gd:
func _ready() -> void:
	add_to_group(Groups.BATTLE_MANAGER)
```

Scripts find them via:
```gdscript
var battle_manager := get_tree().get_first_node_in_group(Groups.BATTLE_MANAGER)
```

This replaces the current hard-coded path in enemy.gd (`/root/DebugRoom/BattleManager`) and the hard-coded path in npc.gd (`/root/DebugRoom/DialogueBox`).

BattleUI still uses `@export var battle_manager_path: NodePath` since it's a sibling of BattleManager inside gameplay.tscn — the path is stable.

## New GameState

No new states. BATTLE still covers combat. Wait/Active mode is a battle_manager setting, not a GameState.

## Party members

### CharacterData resource

Move player stats out of battle_manager constants and into a resource, matching the EnemyData pattern.

```gdscript
# character_data.gd
class_name CharacterData
extends Resource

@export var character_name: String
@export var max_hp: int
@export var power: int
@export var speed: int
@export var stamina: int
@export var strike_percent: float
@export var weapon_ap: int
```

Authored as `.tres` files in `party/`.

### Party member stats

| Stat | Crono | Marle | Lucca |
|------|------:|------:|------:|
| HP | 70 | 65 | 62 |
| Power | 5 | 2 | 3 |
| Speed | 12 | 6 | 6 |
| Stamina | 5 | 3 | 4 |
| Strike % | 10 | 8 | 8 |
| Weapon AP | 3 | 2 | 3 |

These approximate L1 stats. Differentiation is minimal without techs/magic (Phase 4), but Speed and Power differences still matter for ATB order and damage.

### PartyManager

`PartyManager` (scripts/party_manager.gd) — a child of `gameplay.tscn` that owns all runtime party state. Registers in group `Groups.PARTY_MANAGER`.

```gdscript
# party_manager.gd
extends Node

# Per-member runtime state
var members: Array = []  # Array of { "data": CharacterData, "current_hp": int, "is_ko": bool, "node": Node2D }
```

**Responsibilities:**
- Initialized with the 3 party members and their CharacterData resources at startup.
- Tracks `current_hp` and `is_ko` for each member — this persists between battles (Marle ends a fight at 30/65 HP, she starts the next at 30/65).
- Provides the party roster to BattleManager on battle start.
- After battle, BattleManager writes updated HP/KO state back to PartyManager.

**Data flow:**

```
CharacterData (.tres)       base stats (immutable)
        │
        ▼
PartyManager                runtime HP, KO status (persists across battles)
        │
        ▼ (copies on battle start)
BattleManager               ATB gauges, combat HP, turn queue (battle-scoped)
        │
        ▼ emits signals
BattleUI                    updates HUD
Party member nodes          play animations
```

Party member nodes (Player, Marle, Lucca) are purely visual — they subscribe to BattleManager signals and animate accordingly, the same way BattleUI does. They hold no combat state.

### Party member scenes

Create `scenes/party_member.tscn` (or reuse `player.tscn` as a base). Each party member needs:
- AnimatedSprite2D with their own SpriteFrames
- FlashEffect child node
- CollisionShape2D
- The same `play_attack()`, `play_idle()`, `play_hit(direction)` interface

Crono reuses the existing `player.tscn`. Marle and Lucca need new sprite sheets and SpriteFrames resources.

On the field, Marle and Lucca follow Crono in snake formation (see Party field movement section). In battle, all three participate.

## Multiple enemies

### Encounter groups

Support 1–4 enemies per encounter. The debug room has 2–3 Imps grouped together. Walking into any enemy in the group triggers battle with all enemies in the group.

To define groups: enemies that should fight together share an `encounter_group` string export. When one triggers, battle_manager collects all enemies with the same group ID.

```gdscript
# In enemy.gd, add:
@export var encounter_group: String = ""
```

### Enemy targeting by player

When the Attack command is selected, a target cursor appears on the enemies. Player uses left/right (or up/down) to cycle through living enemies, interact to confirm. If only one enemy remains, skip target selection.

### Enemy death and cleanup

Each enemy dies independently (plays `play_death()` as in Phase 2). Battle ends when all enemies in the encounter are dead.

## ATB system changes

### Multi-actor ATB

Every combatant (3 party members + N enemies) has an ATB gauge filling at `speed * delta * ATB_SCALE`.

When a party member's gauge fills:
1. That member is added to a ready queue (FIFO, ordered by fill time).
2. The first ready member gets the command menu. Others wait.
3. After acting, the next ready member gets the menu (if any).

When an enemy's gauge fills:
- It acts immediately (auto-attacks a random living party member).
- If `_animating` is true, the enemy waits until the current animation finishes.

### Wait vs. Active mode

A toggle in battle_manager (default: Active).

- **Active**: all gauges fill at all times during battle.
- **Wait**: all non-acting gauges pause while the player is in a submenu (Item list, target selection). The top-level command menu (Attack/Item) does **not** pause gauges.

```gdscript
enum BattleMode { ACTIVE, WAIT }
var battle_mode: BattleMode = BattleMode.ACTIVE
var _in_submenu := false
```

In `_process`, skip ATB fill for non-acting combatants when `battle_mode == WAIT and _in_submenu`.

## Item command

### Item data

For Phase 3, only one item: Tonic.

```gdscript
# item_data.gd
class_name ItemData
extends Resource

@export var item_name: String
@export var heal_amount: int
@export var target_type: String = "single_ally"  # "single_ally" for Phase 3
```

`items/tonic.tres`: `item_name = "Tonic"`, `heal_amount = 50`, `target_type = "single_ally"`.

### Inventory

`Inventory` (scripts/inventory.gd) — a child node of `gameplay.tscn` that persists item state across battles. Adds itself to the `"inventory"` group so battle_manager can find it. Phase 3 only uses it from battle; Phase 5 adds the field menu.

```gdscript
# inventory.gd
extends Node

# { ItemData resource : int count }
var _items: Dictionary = {}

func _ready() -> void:
	add_to_group(Groups.INVENTORY)

func add_item(item: ItemData, count: int = 1) -> void: ...
func remove_item(item: ItemData, count: int = 1) -> void: ...
func get_count(item: ItemData) -> int: ...
func get_all_items() -> Array: ...  # returns [{ "item": ItemData, "count": int }, ...]
func has_item(item: ItemData) -> bool: ...
```

Initialize with 5 Tonics at startup (hardcoded for Phase 3). No field inventory UI yet — just in-battle usage.

### Item flow in battle

1. Command menu shows: **Attack** / **Item**
2. Player selects Item → item list submenu opens (shows "Tonic x5" or similar).
3. Player selects Tonic → target selection for party members (up/down to cycle, interact to confirm).
4. Tonic consumed: heal target by `heal_amount`, decrement count.
5. If count reaches 0, remove from list.
6. Cancel at any submenu step returns to the previous menu.

## Escape mechanic

Escape is **not** a menu command. The player holds two buttons simultaneously (L+R) at any time during battle.

- While both `escape_left` and `escape_right` are held, an escape gauge fills.
- When the gauge reaches 1.0, the party flees: battle ends, `GameState.change(FIELD)`, enemies remain on the field.
- Enemies can still act while the party is trying to escape.
- If the encounter is flagged `is_boss`, escape is disabled (gauge doesn't fill).

```gdscript
const ESCAPE_RATE := 0.5  # fills in ~2 seconds
var _escape_gauge := 0.0
```

### Enemy.gd addition

```gdscript
@export var is_boss: bool = false
```

## Battle UI changes

The UI needs significant expansion for multi-actor combat.

### Full screen layout

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                                                             │
│                                                             │
│                    (game field visible)                      │
│                                                             │
│                         ▼ target cursor                     │
│               [ Imp A ]     [ Imp B ]     [ Imp C ]         │
│                                                             │
│       [ Crono ]                                             │
│                   [ Marle ]                     ┌─────────┐ │
│                           [ Lucca ]             │> Attack │ │
│                                                 │  Item   │ │
│                                                 └─────────┘ │
│┌───────────────────────────────────────────────────────────┐│
││ ★Crono    HP: 70/70   [████████████████]  ATB [████████]  ││
││  Marle    HP: 65/65   [████████████████]  ATB [██████░░]  ││
││  Lucca    HP: 62/62   [████████████████]  ATB [███░░░░░]  ││
││                                                           ││
││  Imp A [████████]  Imp B [██████░░]  Imp C [████████████] ││
│└───────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

- **Bottom panel**: party stats (name, HP bar, ATB bar) and enemy HP bars. Always visible during battle.
- **Command menu** (right side): appears when a party member's ATB fills. Shows Attack / Item.
- **★ marker**: indicates which party member is currently acting.
- **▼ target cursor**: appears over enemies during target selection, or highlights a party member row during ally targeting.

### State: command menu (Attack / Item)

```
                                                  ┌─────────┐
                                                  │> Attack │
                                                  │  Item   │
                                                  └─────────┘
┌───────────────────────────────────────────────────────────┐
│ ★Crono    HP: 70/70   [████████████████]  ATB [████████] │
│  Marle    HP: 65/65   [████████████████]  ATB [██████░░] │
│  Lucca    HP: 62/62   [████████████████]  ATB [███░░░░░] │
│                                                          │
│  Imp A [████████]  Imp B [██████░░]  Imp C [████████████]│
└──────────────────────────────────────────────────────────┘
```

Navigate with move_up/move_down, confirm with interact. Cancel not applicable at top level.

### State: enemy target selection (after choosing Attack)

```
                         ▼
               [ Imp A ]     [ Imp B ]     [ Imp C ]


┌───────────────────────────────────────────────────────────┐
│ ★Crono    HP: 70/70   [████████████████]  ATB [████████] │
│  ...                                                     │
└──────────────────────────────────────────────────────────┘
```

A ▼ cursor appears above the targeted enemy's sprite on the field (not in the bottom panel). Cycle with move_left/move_right, confirm with interact, cancel to return to command menu. Single remaining enemy auto-targets (skip selection).

### State: item submenu (after choosing Item)

```
                                                  ┌─────────┐
                                                  │> Tonic 5│
                                                  │         │
                                                  └─────────┘
┌───────────────────────────────────────────────────────────┐
│ ★Crono    HP: 70/70   [████████████████]  ATB [████████] │
│  ...                                                     │
└──────────────────────────────────────────────────────────┘
```

Replaces the command menu content with the item list. Navigate with move_up/move_down, confirm with interact, cancel to return to command menu.

### State: ally target selection (after choosing Tonic)

```
┌───────────────────────────────────────────────────────────┐
│ ★Crono    HP: 70/70   [████████████████]  ATB [████████] │
│ >Marle    HP: 30/65   [████████░░░░░░░░]  ATB [██████░░] │
│  Lucca    HP: 62/62   [████████████████]  ATB [███░░░░░] │
│                                                          │
│  Imp A [████████]  Imp B [██████░░]  Imp C [████████████]│
└──────────────────────────────────────────────────────────┘
```

A > cursor highlights the target party member row. Cycle with move_up/move_down, confirm with interact, cancel to return to item list.

### Escape indicator

When L+R are held, a small "Escaping..." label appears above the party panel. Optional polish — the mechanic works without visual feedback.

## Battle manager signals (expanded)

The existing signal set expands to handle multiple combatants:

```gdscript
signal battle_started(party_data: Array, enemy_data: Array)
signal battle_ended
signal atb_updated(combatant_index: int, is_player: bool, value: float)
signal command_ready_changed(combatant_index: int, is_ready: bool)
signal party_hp_changed(combatant_index: int, current_hp: int, max_hp: int)
signal enemy_hp_changed(enemy_index: int, enemy_name: String, current_hp: int, max_hp: int)
signal damage_dealt(world_position: Vector2, amount: int, is_critical: bool)
signal victory_achieved(total_exp: int, total_gold: int, total_tp: int)
signal player_defeated
signal enemy_died(enemy_index: int)
signal combatant_ko(combatant_index: int)
```

`battle_started` now passes arrays so battle_ui can set up the correct number of rows.

## New input

| Action | Keyboard | Gamepad | Purpose |
|--------|----------|---------|---------|
| `cancel` | X | B (right face) | Back out of submenus |
| `escape_left` | Q | Left bumper (L1) | Hold with escape_right to flee |
| `escape_right` | E | Right bumper (R1) | Hold with escape_left to flee |

Existing `interact` (Z/Enter/A) confirms menu selections. Existing movement actions navigate menus.

## New sprites

### Marle

| File | Description |
|------|-------------|
| `party/marle_sheet.svg` → `marle_sheet.png` | 12 frames: 4 idle (2 frames × 2 dirs) + 4 walk (2 frames × 2 dirs) + 4 attack (1 frame × 4 dirs). Same 64×64 layout as Crono. |

SpriteFrames resource: `party/marle_frames.tres`. Same animation set as Crono (idle_down/up/left/right, walk_down/up/left/right, attack_down/up/left/right).

### Lucca

| File | Description |
|------|-------------|
| `party/lucca_sheet.svg` → `lucca_sheet.png` | Same 12-frame layout as Marle. |

SpriteFrames resource: `party/lucca_frames.tres`.

Export (add to `tools/export_sprites.sh`):
```
"$INKSCAPE" party/marle_sheet.svg --export-type=png --export-filename=party/marle_sheet.png -w 768 -h 64
"$INKSCAPE" party/lucca_sheet.svg --export-type=png --export-filename=party/lucca_sheet.png -w 768 -h 64
```

## Party field movement

Followers trail the leader using a position history buffer (snake formation).

### How it works

`player.gd` records its position every frame into a `PackedVector2Array` ring buffer (max ~120 entries, roughly 2 seconds at 60 FPS). Each follower replays the leader's recorded positions with a delay — follower 1 reads positions ~20 frames behind the leader, follower 2 reads ~40 frames behind.

```gdscript
# In player.gd:
var position_history: PackedVector2Array = PackedVector2Array()
const HISTORY_SIZE := 120
```

Each frame, `player.gd` appends its current `global_position` to the buffer (dropping the oldest entry when full).

### Follower script

`party_follower.gd` — attached to Marle and Lucca's nodes. Takes an export for the leader node and a `follow_delay` (frame count).

```gdscript
@export var leader_path: NodePath
@export var follow_delay: int = 20  # frames behind the leader
```

Each `_physics_process`:
1. Read the position from `leader.position_history` at index `size - follow_delay`.
2. Move toward that position at the leader's speed.
3. Update facing direction and play walk/idle animation accordingly.

Movement only happens in FIELD state — followers freeze during BATTLE and DIALOGUE, same as the player.

### Follower spacing

- Follower 1 (Marle): `follow_delay = 20` (~0.33s behind)
- Follower 2 (Lucca): `follow_delay = 40` (~0.67s behind)

When the player stops, followers catch up and stop near the player, naturally staggered.

## Scene changes

```
scenes/gameplay.tscn (Node)
├── PartyManager     — party_manager.gd
├── BattleManager    — battle_manager.gd
├── Inventory        — inventory.gd
├── BattleUI         — battle_ui.gd (CanvasLayer)
├── DialogueBox      — dialogue_box.gd (CanvasLayer)
└── Level            — instance of debug_room.tscn
    ├── walls, floor
    ├── Player (instance of player.tscn) — Crono, position (200, 240)
    ├── Marle (instance of party_member.tscn) — follower, follow_delay=20, position (170, 270)
    ├── Lucca (instance of party_member.tscn) — follower, follow_delay=40, position (170, 210)
    ├── Enemy1 (instance of enemy.tscn) — Imp, encounter_group="a", position (505, 290)
    ├── Enemy2 (instance of enemy.tscn) — Imp, encounter_group="a", position (535, 330)
    ├── Enemy3 (instance of enemy.tscn) — Imp, encounter_group="a", position (505, 370)
    ├── NPC
    └── Camera
```

BattleManager, Inventory, and UI layers live in `gameplay.tscn`. The level scene (`debug_room.tscn`) contains only world content. Marle and Lucca follow Crono on the field and participate when battle triggers.

## Battle flow (updated)

### Entry

1. Player's Area2D enters any Enemy's Area2D in a group → signal fires.
2. battle_manager collects all enemies in that `encounter_group`.
3. battle_manager reads the party roster and current HP from PartyManager.
4. `GameState.change(State.BATTLE)`.
5. `battle_started` signal emitted with party and enemy arrays.
6. All ATB gauges start filling.

### Combat loop

1. All ATB gauges fill each frame (respecting Wait mode if in submenu).
2. When a party member's gauge fills → added to ready queue.
3. First ready member gets command menu:
   - **Attack** → target selection (cycle enemies) → attack animation → damage.
   - **Item** → item list → select item → target selection (cycle allies) → apply item → consume.
4. When an enemy's gauge fills → auto-attacks a random living party member.
5. KO'd party members (HP ≤ 0) can't act, their ATB stops, they're skipped in target selection for items.
6. If all party members KO'd → game over.
7. If all enemies KO'd → victory.

### Victory

1. Each enemy plays death animation as it dies (during combat, not all at once).
2. Last enemy dies → battle over.
3. BattleManager writes updated HP/KO state back to PartyManager.
4. Results display: sum of all enemies' EXP, G, TP.
5. `battle_ended` → `GameState.change(FIELD)`.

### Game over

Same as Phase 2: show "Game Over", reload after 2s.

### Escape

1. Player holds escape_left + escape_right simultaneously.
2. Escape gauge fills at `ESCAPE_RATE * delta`.
3. When gauge ≥ 1.0: battle ends, enemies stay on field (but re-enable collision so they can trigger again).
4. If any enemy in the encounter has `is_boss = true`, escape gauge doesn't fill.

## Damage formula

No changes from Phase 2. The formula is the same, just applied with per-character stats from CharacterData resources instead of hardcoded constants.

## What we skip

- Techs, MP, elements — Phase 4.
- Items beyond Tonic — Phase 5.
- Field inventory/menu — Phase 5.
- Equipment affecting stats — Phase 5.
- Enemy AI beyond "attack random party member" — Phase 7.
- Revive (no way to recover KO'd members in Phase 3) — Phase 5 adds Revive item.
- Battle speed setting — Phase 10.
- Party member swapping — Phase 8 (End of Time).

## Test checklist

### Party field movement
- [ ] Followers trail the player with visible spacing
- [ ] Followers match the player's path (not a straight line to the player)
- [ ] Followers play walk animation while moving, idle when stopped
- [ ] Followers face the correct direction while following
- [ ] Followers stop when the player stops (catch up naturally)
- [ ] Followers freeze during BATTLE and DIALOGUE states
- [ ] Follower 2 is further behind than follower 1

### Party in battle
- [ ] All 3 party members have independent ATB gauges
- [ ] ATB gauges fill at different rates based on Speed
- [ ] Command menu appears for the correct party member when their ATB fills
- [ ] Multiple party members can be ready simultaneously; they act in fill order
- [ ] Acting party member's name is indicated in the UI
- [ ] Each party member's HP is displayed and updates independently

### Multi-enemy
- [ ] Walking into one enemy triggers battle with all enemies in the same encounter group
- [ ] Each enemy has its own ATB gauge and acts independently
- [ ] Target selection cursor cycles through living enemies
- [ ] Dead enemies are removed from target selection
- [ ] Battle ends only when all enemies are dead
- [ ] Results show combined EXP, G, TP from all enemies

### Command menu
- [ ] Menu shows Attack and Item options
- [ ] Up/down navigates between Attack and Item
- [ ] Interact confirms selection
- [ ] Selecting Attack opens enemy target selection
- [ ] Selecting Item opens item submenu

### Item usage
- [ ] Item submenu shows Tonic with count
- [ ] Selecting Tonic opens ally target selection
- [ ] Using Tonic heals target by 50 HP (capped at max)
- [ ] Tonic count decreases after use
- [ ] Tonic disappears from list when count reaches 0
- [ ] Cancel returns to previous menu at each step

### Target selection
- [ ] Enemy target cursor is visible and cycles correctly
- [ ] Ally target cursor is visible and cycles correctly
- [ ] Cancel from target selection returns to command menu
- [ ] Single remaining enemy auto-targets (skip selection)

### Escape
- [ ] Holding escape_left + escape_right fills escape gauge
- [ ] Releasing either button stops the gauge
- [ ] When gauge fills, battle ends and field resumes
- [ ] Enemies remain on field after escape (can re-trigger)
- [ ] Enemies can still attack during escape attempt
- [ ] Escape is blocked when any enemy has is_boss = true

### Wait/Active mode
- [ ] In Active mode, all gauges fill during submenus
- [ ] In Wait mode, non-acting gauges pause during item list and target selection
- [ ] Wait mode does NOT pause gauges at the top-level command menu (Attack/Item)

### Enemy AI
- [ ] Enemies attack random living party members
- [ ] Enemies do not target KO'd party members
- [ ] Multiple enemies act independently based on their ATB

### Game over
- [ ] Game over triggers when all 3 party members reach 0 HP
- [ ] Game over does NOT trigger if at least one member is alive

### Battle animations
- [ ] All 3 party members play attack/idle/hit animations correctly
- [ ] All enemies play attack/idle/hit/die animations correctly
- [ ] Lunge direction is correct for each attacker→target pair
- [ ] FlashEffect works on all combatants
- [ ] Damage numbers appear at the correct target positions
