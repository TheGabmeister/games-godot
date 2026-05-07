# Game Spec Research & Writing

Research a game's gameplay mechanics and write a comprehensive systems-level spec document. The spec describes the game's design surface — features, systems, characters, items, enemies, story structure — without any code, engine specifics, or implementation details.

## Input

$ARGUMENTS

If no game is specified, ask the user which game to research.

## Process

1. **Research the game thoroughly** using web search. Focus on:
   - Official wikis (Fandom, dedicated wikis)
   - Strategy wikis (StrategyWiki, etc.)
   - Community FAQs (GameFAQs)
   - Mechanics guides and formula breakdowns
   - Speedrun/datamining communities for verified numbers
   - Public GitHub/GitLab repositories — search for decompilations, reverse-engineered source code, or fan recreations that expose internal mechanics

2. **Write the spec** as a single markdown file at the project root named `SPEC_<GAME_NAME>.md` (e.g., `SPEC_FINAL_FANTASY_6.md`). Use snake_case, uppercase, with spaces replaced by underscores.

## Spec Structure

Follow this section outline (adapt subsections to fit the game — not every game has every system):

```
# <Game Title> — Gameplay Systems Spec

<Game title, platform, release year. One line.>

---

## 1. Core Gameplay Systems
- Primary gameplay loop (combat, exploration, building, etc.)
- Battle/combat system (if applicable): turn structure, action economy, targeting, party size
- Movement/traversal mechanics
- Progression systems: leveling, skill trees, upgrades
- Resource management (HP, MP, stamina, ammo, etc.)

## 2. World Structure
- World layout (overworld, zones, procedural, etc.)
- Area types and how they connect
- Travel/fast-travel mechanics
- Time/day-night/weather systems if present
- Locked progression and gating mechanics

## 3. Playable Characters / Classes
- Full roster with roles, stats, unique mechanics
- Character-specific abilities or skill sets
- Recruitment/unlock conditions
- Party composition rules and constraints

## 4. Story & Progression
- Main story structure (acts, chapters, beats)
- Key branching points or player choices
- Side quests and optional content
- Multiple endings (if applicable)
- New Game+ or post-game content

## 5. Items & Equipment
- Equipment slots and categories
- Weapon/armor stat schemas
- Consumables and key items
- Crafting or upgrade systems
- Unique/legendary items and how to obtain them

## 6. Abilities / Skills / Magic
- Skill/magic system structure
- Learning/unlocking mechanics
- Combo or synergy systems
- Resource costs (MP, cooldowns, charges)
- Elemental or type systems

## 7. Enemies & Bosses
- Enemy categorization (by area, type, tier)
- Common enemy behaviors and mechanics
- Boss design patterns (phases, gimmicks, counters)
- Bestiary structure

## 8. Economy
- Currencies
- Shop systems and pricing tiers
- Income sources and sinks
- Trading/bartering if applicable

## 9. Minigames & Side Systems
- Optional gameplay diversions
- Rewards that feed back into main systems
- Collection/completion systems

## 10. Engine & Presentation Systems
- Dialogue/conversation system
- Save system
- Difficulty settings
- UI/menu structure
- Camera behavior
- Audio/music system behavior (not the music itself, but how it functions)

## 11. Multiplayer (if applicable)
- Co-op/competitive structure
- Shared vs. separate progression
- Matchmaking/lobby systems

## Genre-Specific Sections (include whichever apply)

### FPS / Third-Person Shooter
- Weapon handling: recoil patterns, spread, damage falloff, fire rate, reload times
- Movement mechanics: sprint, slide, mantle, wall-run, bunny hop, air control
- Health/shield/armor systems and regeneration rules
- Hitboxes and damage multipliers (headshot, limbs, torso)
- Ammo economy and pickup systems
- Map/level flow: lanes, sight lines, spawn logic
- TTK (time-to-kill) ranges and balance philosophy

### Fighting Game
- Frame data: startup, active, recovery, hit advantage, block advantage
- Input system: notation, motions, charge, button strength
- Combo system: links, chains, cancels, juggles, gravity scaling
- Meter/gauge mechanics: super meter, burst, install, V-trigger, etc.
- Defensive mechanics: blocking (high/low/cross-up), parry, push block, throw tech
- Character archetypes and matchup spread
- Round/match structure and win conditions
- Training mode features and data display

### RTS / Strategy
- Resource types, gathering rates, and worker mechanics
- Base building: structures, placement rules, tech tree dependencies
- Unit production: build times, population cap, supply mechanics
- Unit types: stats, roles, counters, upgrades
- Fog of war and scouting mechanics
- Formation, pathing, and control groups
- Win conditions (annihilation, objectives, score)
- Faction/race asymmetry and unique mechanics

### Racing
- Vehicle stats: speed, acceleration, handling, weight, drift
- Drift/boost mechanics: how to initiate, maintain, and chain
- Track hazards and shortcuts
- Item/power-up systems (if applicable)
- Rubber-banding / catch-up AI behavior
- Vehicle customization and upgrade paths
- Race types and win conditions

### Platformer
- Movement physics: gravity, jump height/duration, air control, coyote time
- Advanced movement: wall jump, dash, double jump, ground pound
- Power-ups and ability pickups
- Level design gating: what abilities unlock what paths
- Collectibles and their rewards
- Death/checkpoint system
- Scoring/ranking systems

### Roguelike / Roguelite
- Run structure: floors, rooms, branches, loops
- Procedural generation rules and seed system
- Item/relic pools and synergy mechanics
- Meta-progression: what carries between runs
- Shop/economy within a run
- Character/class unlocks and differences
- Difficulty scaling per floor/loop
- Boss rotation and scheduling

### Survival / Crafting
- Vital meters: hunger, thirst, stamina, temperature, sanity
- Gathering: resource nodes, tools, yield rates
- Crafting system: recipes, stations, tiers, research/unlock
- Building: structural rules, snapping, decay/durability
- Threat cycles: day/night, horde events, environmental hazards
- Inventory and storage limits
- Respawn/death penalty

### Stealth
- Detection model: sight cones, sound propagation, light/shadow
- Alert states and escalation (unaware → suspicious → alerted → combat)
- Takedown mechanics: lethal/non-lethal, conditions, noise
- Gadgets and distraction tools
- Guard AI: patrol routes, communication, search patterns
- Scoring/rating: ghost, no-kill, time, detection count
- Disguise or social stealth systems

### Puzzle
- Core mechanic and rule set
- Difficulty curve and level progression
- Scoring/grading system
- Hint/undo systems
- Procedural vs. hand-crafted levels
- Time pressure or turn limits

### Sports / Simulation
- Player/team ratings and stat model
- Match simulation rules
- Season/career/franchise structure
- Transfer/draft/trade mechanics
- Training and player development
- Physics or simulation fidelity model

## 12. Open Questions / Unverified
- Mechanics where community sources conflict
- Exact formulas or numbers not yet pinned down
- Areas needing ROM/datamine verification

## 13. References
- Links to wikis, FAQs, and guides used
- Organized by source type
```

## Writing Guidelines

- **Systems-level only.** Describe WHAT the game does, not HOW to build it. No code, no engine details, no node trees, no implementation choices.
- **Be specific with numbers.** Include stat values, damage formulas, level caps, item counts, frame data — whatever the community has verified. Use tables for structured data.
- **Note uncertainty.** If sources conflict or numbers aren't verified, say so in §13.
- **Use the game's own terminology.** Character names, ability names, status effect names — use the canonical names from the game.
- **Platform matters.** Note which version you're speccing (SNES, PS1, remaster, etc.) and call out version differences that affect mechanics.
- **Tables for structured data.** Weapon lists, character stats, enemy tables — use markdown tables.
- **Cross-reference within the doc.** Use `§N` notation to reference other sections.
- **Separate companion docs for large data sets.** If a section would exceed ~200 lines of tables (e.g., full bestiary, full equipment list, full tech list), note that it belongs in a companion file like `docs/<game>/bestiary.md` and create that file too.
- **Aim for completeness on the game's core identity.** A Final Fantasy spec needs exhaustive job/ability coverage. A Metroidvania spec needs exhaustive ability-gate coverage. A roguelike spec needs exhaustive item/synergy coverage. Identify what makes the game tick and go deep there.
