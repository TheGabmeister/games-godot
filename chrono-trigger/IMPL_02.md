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

The debug room gains an enemy. The NPC stays for dialogue testing.

```
debug_room (Node2D)
├── ... (existing Phase 1 nodes)
├── Enemy (Area2D)
│   ├── AnimatedSprite2D  — enemy_sheet.png via SpriteFrames
│   └── CollisionShape2D  — triggers battle on player contact
└── BattleUI (CanvasLayer)
    ├── ATBBar            — player's ATB gauge (ProgressBar or TextureProgressBar)
    ├── EnemyHPBar        — enemy HP display (ProgressBar + Label)
    ├── PlayerHPLabel     — "HP: X / Y" text
    └── CommandMenu       — "Attack" button (VBoxContainer with a single option for now)
```

The enemy uses Area2D (not StaticBody2D) so the player walks *into* it to trigger battle, rather than being blocked.

## Combatant stats

Hardcoded for Phase 2. No resources or data files — just values in scripts.

### Crono (player)

| Stat | Value | Notes |
|------|------:|-------|
| HP | 70 | Roughly Crono's L1 HP |
| Power | 5 | Base physical stat |
| Speed | 12 | ATB fill rate |
| Stamina | 5 | Defense |
| Strike % | 10 | Crit chance (%) |
| Weapon AP | 3 | Wood Sword |

### Imp (enemy)

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

## Battle flow

### Entry (field → battle)

1. Player's Area2D enters the Enemy's Area2D → signal fires.
2. `GameState.change(State.BATTLE)` — player movement stops.
3. BattleUI becomes visible.
4. ATB gauges start filling.
5. Enemy sprite stays in place (no repositioning for Phase 2).

### Combat loop

1. ATB gauges fill each frame.
2. When Crono's gauge is full:
   - Command menu shows "Attack" (single option, auto-focused).
   - Player presses interact → Crono attacks the enemy.
   - Apply damage formula. Subtract from enemy HP.
   - Brief visual feedback (enemy flashes white or blinks).
   - Reset Crono's ATB gauge.
3. When the enemy's gauge is full:
   - Enemy attacks Crono automatically (no menu).
   - Apply damage formula (enemy power vs. Crono stamina).
   - Brief visual feedback (screen flash or Crono blinks).
   - Update player HP display.
   - Reset enemy's ATB gauge.
4. If enemy HP ≤ 0 → victory.
5. If Crono HP ≤ 0 → game over.

### Victory

1. Enemy sprite disappears.
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

### battle_manager.gd (on a new BattleManager Node in the scene, or as autoload)

Owns the combat loop. Responsibilities:
- Holds references to the player combatant data and the enemy combatant data.
- Runs ATB fill in `_process()` when `GameState.current == BATTLE`.
- Manages turn order: when a gauge fills, triggers the corresponding action.
- Applies damage, checks win/lose conditions.
- Emits signals: `battle_started`, `battle_ended(result)`, `combatant_acted(who, action, damage)`.

### combatant_data.gd (resource or simple class)

Holds runtime combat stats for one combatant:
- `hp`, `max_hp`, `power`, `speed`, `stamina`, `strike_percent`, `weapon_ap`
- `atb_gauge: float` (0.0 to 1.0)
- `is_player: bool`

Hardcoded instances created in battle_manager when battle starts. No .tres files yet.

### enemy.gd (on Enemy node)

- Detects player contact via `body_entered` signal.
- Triggers battle start (calls battle_manager or emits a signal).
- Has hardcoded stats (HP, Power, Speed, etc.).
- `die()` method: plays a short effect then `queue_free()`.

### battle_ui.gd (on BattleUI)

- Listens to battle_manager signals to update display.
- Shows/hides ATB bar, enemy HP bar, command menu, results, game over.
- Command menu input gated on `GameState.current == BATTLE` and Crono's ATB being full.

### player.gd (modified)

- No changes to movement logic — GameState gate already prevents movement during BATTLE.
- Expose Crono's combat stats (or let battle_manager hardcode them).

## New sprites

| File | Description |
|------|-------------|
| `npc/enemy_sheet.svg` → `enemy_sheet.png` | Enemy (Imp) sprite sheet — same 8-frame format as other characters. Red/purple color scheme. |

Add to `tools/export_sprites.sh`:
```
"$INKSCAPE" npc/enemy_sheet.svg --export-type=png --export-filename=npc/enemy_sheet.png -w 512 -h 64
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
- Battle animation/effects beyond a simple blink/flash.
- Enemy respawn.
- EXP → level up (just display EXP earned, no leveling system yet).

## Test checklist

### Battle entry
- [ ] Walking into the enemy triggers battle
- [ ] Player movement stops when battle starts
- [ ] BattleUI appears (ATB bar, enemy HP, command menu)
- [ ] Enemy and player remain in their field positions

### ATB
- [ ] Crono's ATB gauge fills over time
- [ ] Enemy's ATB gauge fills over time (slower than Crono due to lower Speed)
- [ ] Command menu only appears when Crono's gauge is full
- [ ] After acting, ATB gauge resets to 0 and starts filling again

### Combat
- [ ] Pressing interact on "Attack" deals damage to the enemy
- [ ] Damage varies slightly between hits (random factor)
- [ ] Crits happen occasionally and deal double damage
- [ ] Enemy attacks Crono when its ATB fills
- [ ] Crono's HP display updates after taking damage
- [ ] Enemy HP bar updates after taking damage

### Victory
- [ ] Enemy disappears when HP reaches 0
- [ ] Results screen shows EXP, G, TP earned
- [ ] Results screen dismisses after a delay
- [ ] GameState returns to FIELD after victory
- [ ] Player can move again after battle ends

### Game over
- [ ] If Crono's HP hits 0, "Game Over" is displayed
- [ ] Scene reloads or restarts after game over
