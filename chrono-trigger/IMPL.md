## Implementation Phases

Each phase produces something playable. Early phases hardcode freely; abstractions and data-driven patterns are introduced only when the phase's complexity requires them. Content is a thin vertical slice — just enough characters, enemies, and areas to exercise every system the phase adds.

### Phase 1 — A character in a room
- Player character (Crono) with 8-directional free-form movement.
- One field map (e.g., Crono's house or a section of Truce village) with collision.
- Camera follows the player.
- One NPC that can be interacted with: press interact → dialogue textbox with typewriter text, button to advance.
- **Validates:** scene setup, character controller, input handling, basic NPC interaction.

### Phase 2 — Battle on the field
- One character (Crono) vs. one enemy.
- ATB gauge that fills based on Speed stat; Attack command when full.
- Physical damage formula (simplified — power vs. defense, random factor, crits).
- Enemy HP bar; victory when HP reaches 0.
- Seamless field-to-battle transition: contact with enemy sprite → movement locks → battle UI appears → combat → results (EXP, G, TP) → return to field.
- **Validates:** ATB core loop, damage math, field-to-battle continuity.

### Phase 3 — Party and multi-enemy combat
- 3-member party (Crono, Marle, Lucca) in battle with individual ATB gauges.
- Multiple enemies per encounter with varying stats.
- Turn queue: multiple ready actors ordered by fill time.
- Wait vs. Active mode toggle (enemy gauges pause in submenus or not).
- Item command in battle (Tonic only — heals HP).
- Escape mechanic (hold two buttons; accumulates over time; blocked on boss flag).
- Game over on full party wipe.
- Basic enemy AI: attack a random party member.
- **Validates:** multi-actor ATB, party management in combat, enemy behavior basics.

### Phase 4 — Techs and elements
- Single Techs for Crono, Marle, Lucca with MP costs.
- AoE targeting shapes: single-target, line, circle-around-target.
- Four elements (Lightning, Fire, Water/Ice, Shadow) with resistance multipliers per enemy (0% / 50% / 100% / 200% / absorb).
- Status effects: Haste, Slow, Poison, Sleep (minimum set to cover buff, debuff, DoT, and incapacitate).
- TP accumulation from battles → tech unlock at thresholds.
- **Validates:** tech system, elemental damage, status effect framework, progression-gated abilities.

### Phase 5 — Inventory, equipment, and menus
- Field menu overlay: Status/Equip, Item, Tech (view-only), Save.
- Shared inventory pool: consumables stack to 99, equipment listed individually.
- Equipment slots (weapon / helm / armor / accessory) with class-locked weapons.
- Stat comparison preview when browsing equipment.
- Item usage both in field menu and in battle.
- Save/Load to file with save-point restriction in dungeons.
- **Validates:** menu UX, inventory data model, equipment affecting combat stats, persistence.

### Phase 6 — Multiple areas and world traversal
- Room-to-room transitions (doorways, fade-to-black).
- World map with location markers → enter location → field map.
- Party snake formation: 2 followers trail the leader, replaying position history.
- Encounter trigger types: contact, proximity (enemy chases), ambush (hidden until trigger tile).
- Enemy field behavior: stationary and patrol patterns.
- Shops: buy equipment/consumables, sell at 50%, inn full-heal.
- At least 3–4 connected areas (e.g., Truce village + overworld + Guardia Forest + Zenan Bridge) to stress transitions.
- **Validates:** scene transitions, world map, encounter design, economy loop.

### Phase 7 — Advanced combat
- Dual Techs: two characters with full ATB → combined tech, shared MP cost.
- Triple Techs: three characters, Rock accessory requirement.
- Enemy counters: react to specific damage types or any hit.
- Boss AI: phase transitions (HP thresholds), conditional attacks, kill-order rules. Implement at least one multi-phase boss (e.g., Dragon Tank with head/grinder/body).
- Charm ability (Ayla): steal mid-battle from enemy charm slot.
- **Validates:** combo system, boss complexity, the point where hardcoded enemy AI needs a data-driven pattern.

### Phase 8 — Time travel and progression gating
- Storyline counter (single value) + supplementary bit flags.
- NPC dialogue that changes based on story counter.
- Time gates: interact with portal → era transition → load corresponding world map and field areas.
- At least 2–3 eras with shared geography (e.g., 600 AD and 1000 AD versions of Guardia region).
- Sealed chests: pendant-charge flag, double-dip trick (inspect in past → take upgraded in future → return for base in past).
- End of Time hub: party member swap screen, Spekkio room, pillars of light to each era.
- **Validates:** game-state system, content gating, time-travel mechanics, party roster management. This is where a formal event/flag system becomes necessary.

### Phase 9 — Event scripting
- Event command system for cutscenes: movement paths, animation triggers, dialogue sequences, screen effects (fade, flash, shake), audio changes, camera pans.
- Branching dialogue choices (binary and multi-option prompts).
- Party-composition-aware scene variants.
- Player input locked during scripted sequences.
- Implement at least one full narrative sequence end-to-end (e.g., the Millennial Fair opening through Marle's disappearance).
- **Validates:** narrative delivery, the event scripting vocabulary from §10.2. Complexity here justifies a declarative event format rather than hardcoded scripts.

### Phase 10 — End-to-end loop and polish
- New Game+: carry-over rules (levels, equipment, techs) and reset rules (story counter, key items, gold to 200G, warp-to-Lavos option).
- Key items tracked in a separate list; quest chains gated by key item possession.
- Epoch flight on the world map + time gauge for era selection.
- Multiple endings: at least 2–3 endings determined by story counter at time of Lavos defeat.
- At least one minigame (e.g., Gato fight at the Fair as a battle tutorial).
- Config menu: battle speed, message speed, window skin, cursor memory.
- **Validates:** full gameplay loop from start to endgame, replayability systems, content scaling readiness.