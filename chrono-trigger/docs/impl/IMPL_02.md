# Phase 2 — Battle on the field

## Goal

Crono encounters a single enemy in the debug room. Walking into the enemy triggers a seamless battle: ATB gauge fills, player selects Attack, damage is dealt, enemy dies, results display, field resumes. One character vs. one enemy — no party, no techs, no items.

## What we're building on

From Phase 1 we have: player movement, GameState autoload (FIELD/DIALOGUE), camera, NPC interaction, dialogue system. Phase 2 adds BATTLE to the GameState enum and introduces the first combat loop.

## New GameState

```
enum State { FIELD, DIALOGUE, BATTLE }
```

## Scene changes

Player, NPC, and Enemy are separate `.tscn` scenes instanced in `debug_room.tscn`. Per-instance properties (position, dialogue, enemy data) are set on the instance.

```
scenes/player.tscn (CharacterBody2D)
├── AnimatedSprite2D  — crono_frames.tres
├── FlashEffect       — flash_effect.gd, targets AnimatedSprite2D
├── CollisionShape2D  — RectangleShape2D
└── InteractRay       — RayCast2D

scenes/enemy.tscn (Area2D)
├── AnimatedSprite2D  — SpriteFrames (set per enemy type)
├── FlashEffect       — flash_effect.gd, targets AnimatedSprite2D
└── CollisionShape2D  — CircleShape2D, radius 48px

scenes/npc.tscn (StaticBody2D)
├── AnimatedSprite2D  — SpriteFrames
└── CollisionShape2D

debug_room.tscn (Node2D)
├── ... (walls, floor)
├── Player            — instance of player.tscn
├── NPC               — instance of npc.tscn, dialogue set per instance
├── Enemy             — instance of enemy.tscn, data set per instance
├── BattleManager     — battle_manager.gd
├── Camera            — camera.gd, follows Player
├── DialogueBox       — dialogue_box.gd
└── BattleUI          — battle_ui.gd, connects to BattleManager via export
```

The enemy uses Area2D (not StaticBody2D) so the player walks *into* it to trigger battle, rather than being blocked.

## Combatant stats

### Crono (player) — hardcoded

Stats are hardcoded in `player.gd` or `battle_manager.gd`. No resource needed yet — player stats will become data-driven when we add equipment and leveling in later phases.

| Stat | Value | Notes |
|------|------:|-------|
| HP | 70 | Roughly Crono's L1 HP |
| Power | 5 | Base physical stat |
| Speed | 12 | ATB fill rate |
| Stamina | 5 | Defense |
| Strike % | 10 | Crit chance (%) |
| Weapon AP | 3 | Wood Sword |

### Imp (enemy) — EnemyData resource

Enemy stats are defined as a resource so we can add more enemies by authoring `.tres` files.

```gdscript
# enemy_data.gd
class_name EnemyData
extends Resource

@export var enemy_name: String
@export var max_hp: int
@export var power: int
@export var speed: int
@export var stamina: int
@export var exp_reward: int
@export var gold_reward: int
@export var tp_reward: int
```

Authored as `.tres` files in `enemies/` (e.g., `enemies/imp.tres`). The enemy node holds `@export var data: EnemyData`.

**Imp stats:**

| Stat | Value | Notes |
|------|------:|-------|
| HP | 32 | Survives ~2 hits |
| Power | 4 | Enemy attack |
| Speed | 8 | Slower than Crono |
| Stamina | 4 | Defense |
| EXP | 10 | Battle reward |
| G | 5 | Gold reward |
| TP | 1 | Tech Point reward |

## ATB system

- Both Crono and the enemy have an ATB gauge (0.0 → 1.0).
- Each frame during BATTLE, gauge fills: `gauge += speed * delta * ATB_SCALE`. `ATB_SCALE` is a tuning constant (start with ~0.02).
- When a combatant's gauge hits 1.0, they can act.
- **Crono:** gauge full → command menu appears. Player selects "Attack" → Crono attacks → gauge resets to 0.
- **Enemy:** gauge full → enemy auto-attacks Crono → gauge resets to 0.
- Both gauges fill simultaneously. Whoever fills first acts first.

## Damage formula (simplified)

```
attack = weapon_ap + power
defense = target_stamina
raw_damage = max(1, attack - defense)
random_factor = randf_range(0.9, 1.1)
damage = int(raw_damage * random_factor)

# Crit check
if randf() * 100.0 < strike_percent:
    damage *= 2
```

This is a simplified version of the SPEC §6.1 formula. Good enough for Phase 2; we'll refine with the full formula when we add equipment and per-character stat routing.

## Battle animations

Each combatant owns its own animation methods (`play_attack()`, `play_idle()`, `play_hit(direction)`) — battle_manager calls them uniformly without knowing implementation details.

**Attacking:**
- Combatant plays attack animation via `play_attack()`, then lunges ~16px toward target (tween, 0.15s), then retreats.
- Player's attack animation is direction-aware (`attack_down`, `attack_up`, etc.).

**Taking damage (hit):**
- Target plays `play_hit(direction)` — player recoils via tween; enemy plays hit sprite.
- FlashEffect component (child node) handles the white flash: applies a ShaderMaterial with `flash.gdshader`, tweens `flash_amount` 0→1→0 three times.
- battle_manager emits `damage_dealt` signal; battle_ui spawns a floating damage number (Label, fades up over 0.6s). Crit numbers are gold/larger.

**Dying:**
- Enemy owns `play_death()`: plays die animation + fades out (modulate alpha 1.0 → 0.0 over 0.4s).
- Node removed after fade completes.

ATB gauges **pause** during an attack animation (`_animating` flag) so actions don't overlap. The sequence for one attack:

1. ATB gauges pause.
2. Attacker plays attack animation + lunges toward target (~0.15s).
3. Damage applied, target flashes + damage number pops (~0.3s).
4. Attacker returns to position (~0.15s).
5. ATB gauges resume.

Total: ~0.6s per attack.

## Battle music

A looping battle theme generated via the music pipeline (MIDI → FluidSynth → WAV → OGG).

- **File:** `music/battle.ogg`
- **Generation script:** `tools/music/battle_theme.py` — produces a short energetic loop (~16 bars).
- battle_manager starts the music on battle entry and stops it on victory/game over.
- An `AudioStreamPlayer` node named `BattleMusic` is added to the scene (or as a child of BattleManager). Set to loop.

### Audio flow

| Event | Action |
|-------|--------|
| Battle start | `BattleMusic.play()` |
| Victory (after death anim, before results) | `BattleMusic.stop()` |
| Game over | `BattleMusic.stop()` |

No field music in Phase 2 — silence outside of battle. Field music is a later phase concern.

## Battle flow

### Entry (field → battle)

1. Player's Area2D enters the Enemy's Area2D → signal fires.
2. `GameState.change(State.BATTLE)` — player movement stops.
3. BattleUI becomes visible. Battle music starts.
4. ATB gauges start filling.
5. Enemy sprite stays in place (no repositioning for Phase 2).

### Combat loop

1. ATB gauges fill each frame.
2. When Crono's gauge is full:
   - Command menu shows "Attack" (single option, auto-focused).
   - Player presses interact → attack animation plays (lunge, hit flash, damage number).
   - Apply damage formula. Subtract from enemy HP.
   - Reset Crono's ATB gauge.
3. When the enemy's gauge is full:
   - Enemy attacks Crono automatically — attack animation plays.
   - Apply damage formula (enemy power vs. Crono stamina).
   - Update player HP display.
   - Reset enemy's ATB gauge.
4. If enemy HP ≤ 0 → victory.
5. If Crono HP ≤ 0 → game over.

### Victory

1. Enemy plays death animation (die frames + alpha fade out over ~0.4s), then node is removed.
2. BattleUI hides the command menu and ATB bar.
3. Results display appears: "EXP +10 / G +5 / TP +1" — shown for ~2 seconds.
4. `GameState.change(State.FIELD)` — player can move again.
5. Enemy does not respawn (for Phase 2 simplicity).

### Game over

1. Show "Game Over" text centered on screen.
2. Pause briefly, then reload the scene (or restart — simplest approach).

## Scripts

All in `scripts/`.

### game_state.gd (modified)

- Add `BATTLE` to the State enum.

### battle_manager.gd (on BattleManager Node)

Owns the combat loop. Has **no reference to battle_ui** — communicates entirely via signals:

- `battle_started(player_hp, player_max_hp, enemy_name, enemy_hp, enemy_max_hp)`
- `battle_ended`
- `atb_updated(value)`
- `command_ready_changed(is_ready)`
- `player_hp_changed(current_hp, max_hp)`
- `enemy_hp_changed(enemy_name, current_hp, max_hp)`
- `damage_dealt(world_position, amount, is_critical)`
- `victory_achieved(exp_reward, gold_reward, tp_reward)`
- `player_defeated`

Responsibilities:
- Runs ATB fill in `_process()` when `GameState.current == BATTLE`.
- Manages turn order: when a gauge fills, triggers the corresponding action.
- Applies damage formula, checks win/lose conditions.
- Orchestrates attack sequence (lunge/retreat tweens), calls `play_attack()` / `play_hit()` / `play_idle()` on combatants uniformly.

### battle_ui.gd (on BattleUI)

- Has `@export var battle_manager_path: NodePath`.
- In `_ready()`, connects to all battle_manager signals and connects its own `attack_selected` signal back to `battle_manager._on_attack_selected`.
- Updates display in response to signals. Owns damage number spawning.
- Command menu input gated on `GameState.current == BATTLE` and command ready state.

### enemy_data.gd (resource)

`EnemyData` resource class (see Combatant stats section above). Authored as `.tres` files.

### enemy.gd (on Enemy node)

- Has `@export var data: EnemyData` — assigned in the inspector to a `.tres` file.
- Detects player contact via `body_entered` signal.
- Triggers battle start (calls battle_manager).
- Owns animation methods: `play_idle()`, `play_attack()`, `play_hit(direction)`, `play_die()`, `play_death()` (die + fade-out tween).

### player.gd (modified)

- No changes to movement logic — GameState gate already prevents movement during BATTLE.
- Owns battle animation methods: `play_attack()` (direction-aware), `play_idle()`, `play_hit(direction)` (recoil tween).
- Stats are hardcoded in battle_manager for Phase 2.

### flash_effect.gd (reusable component)

- Attached as child node of any entity that needs hit flashes.
- Has `@export var target: NodePath` pointing to the CanvasItem to flash.
- `flash()` method: applies ShaderMaterial with `flash.gdshader`, tweens `flash_amount` 0→1→0 three times, then restores original material.

### flash.gdshader

- `canvas_item` shader with a `flash_amount` uniform.
- Mixes the texture RGB toward white based on `flash_amount`.

## Sprite sheet changes

### Crono — add attack frames

Extend `player/crono_sheet.svg` from 8 frames to 12 frames (768×64 px). The 4 new frames are attack poses, one per direction.

```
| down_0 | down_1 | up_0 | up_1 | left_0 | left_1 | right_0 | right_1 | atk_down | atk_up | atk_left | atk_right |
```

- **atk_down/up/left/right** — arm or weapon extended in the facing direction. Single frame per direction (the lunge tween handles the motion).

Add new animations to `player/crono_frames.tres`:
- `attack_down`, `attack_up`, `attack_left`, `attack_right` — 1 frame each, no loop.

Update export:
```
"$INKSCAPE" player/crono_sheet.svg --export-type=png --export-filename=player/crono_sheet.png -w 768 -h 64
```

### New sprite — Enemy (Imp)

| File | Description |
|------|-------------|
| `enemies/imp_sheet.svg` → `imp_sheet.png` | Imp sprite sheet — 6 frames: idle (2 frames) + attack (1 frame) + hit (1 frame) + die (2 frames). Red/purple color scheme. |

The imp only faces down (toward the player) for Phase 2, so no directional variants needed.

```
| idle_0 | idle_1 | attack | hit | die_0 | die_1 |
```

- **idle_0 / idle_1** — standing, subtle shift. Looping at ~3 FPS.
- **attack** — lunging/striking pose. Single frame.
- **hit** — recoil pose. Single frame (white flash is handled by modulate, not sprite).
- **die_0 / die_1** — collapsing. Played once (fade-out handled by modulate alpha tween).

SpriteFrames resource: `enemies/imp_frames.tres`
- `idle`: 2 frames, loop, 3 FPS
- `attack`: 1 frame, no loop
- `hit`: 1 frame, no loop
- `die`: 2 frames, no loop, 4 FPS

Export (add to `tools/export_sprites.sh`):
```
"$INKSCAPE" enemies/imp_sheet.svg --export-type=png --export-filename=enemies/imp_sheet.png -w 384 -h 64
```

## New input

| Action | Keyboard | Gamepad | Purpose |
|--------|----------|---------|---------|
| (none) | — | — | "Attack" selection reuses the existing `interact` action |

No new input actions needed. The command menu uses `interact` to confirm and arrow keys to navigate (though there's only one option in Phase 2).

## What we skip

- Multiple party members — just Crono. Party combat is Phase 3.
- Techs, items, MP — just the Attack command.
- AoE targeting, enemy positioning — single target only.
- Wait vs Active mode — no submenus to pause for yet.
- Escape — Phase 3.
- Elaborate hit/death particle effects beyond flash and fade.
- Enemy respawn.
- EXP → level up (just display EXP earned, no leveling system yet).

## Test checklist

### Battle entry
- [x] Walking into the enemy triggers battle
- [x] Player movement stops when battle starts
- [x] BattleUI appears (ATB bar, enemy HP, command menu)
- [x] Enemy and player remain in their field positions

### ATB
- [x] Crono's ATB gauge fills over time
- [x] Enemy's ATB gauge fills over time (slower than Crono due to lower Speed)
- [x] Command menu only appears when Crono's gauge is full
- [x] After acting, ATB gauge resets to 0 and starts filling again

### Combat
- [x] Pressing interact on "Attack" deals damage to the enemy
- [x] Damage varies slightly between hits (random factor)
- [x] Crits happen occasionally and deal double damage
- [x] Enemy attacks Crono when its ATB fills
- [x] Crono's HP display updates after taking damage
- [x] Enemy HP bar updates after taking damage

### Battle animations
- [x] Crono lunges toward the enemy when attacking, then returns
- [x] Crono plays the attack sprite during the lunge
- [x] Enemy lunges toward Crono when attacking, then returns
- [x] Target flashes white when hit
- [x] Damage number floats up and fades out above the target
- [x] Crit damage numbers are visually distinct (larger or different color)
- [x] ATB gauges pause during attack animations
- [x] Enemy fades out on death

### Music
- [x] Battle music starts playing when battle begins
- [x] Battle music loops seamlessly
- [x] Battle music stops on victory (before results display)
- [x] Battle music stops on game over
- [x] No music plays outside of battle

### Victory
- [x] Enemy plays death animation then disappears
- [x] Results screen shows EXP, G, TP earned
- [x] Results screen dismisses after a delay
- [x] GameState returns to FIELD after victory
- [x] Player can move again after battle ends

### Game over
- [x] If Crono's HP hits 0, "Game Over" is displayed
- [x] Scene reloads or restarts after game over
