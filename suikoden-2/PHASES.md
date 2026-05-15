# Suikoden II — Phased Implementation Plan

---

## Phase 1 — Field Movement & Dialogue

Establish the foundational layer: a controllable character exploring a town, talking to NPCs, and navigating menus.

- Player character (Riou) with 4-directional movement and dash (hold L1/R1)
- One town environment (Kyaro Town) with collision, NPC placement, and interactable objects
- Dialogue system: text boxes with character portraits, player choice prompts
- Field input mapping: D-Pad move, × confirm/interact, ○ cancel, □ open menu, L1/R1 dash
- Pause menu skeleton: Items, Equipment, Status, Formation, Save, Settings screens
- Save system with save point markers; save/load to file slots
- Scene transition system (enter/exit buildings, area transitions)

### Assets

**Sprites**
- Riou — field sprite (walk, dash, idle, 4 directions)
- 8–10 NPC townsfolk (generic Kyaro residents)

**Tilemaps**
- Kyaro Town (exterior streets, interior buildings)

**2D Art**
- Riou portrait
- Dialogue window frame (default style)

**Audio**
- Kyaro Town background music
- Footstep SFX (tile-dependent: grass, stone, wood)
- Dialogue text advance SFX
- Menu open/close SFX
- Menu cursor move SFX
- Save point interact SFX

**UI**
- Dialogue text box with portrait slot
- Pause menu screen layouts (Items, Equipment, Status, Formation, Save, Settings)
- Save/Load file select screen

---

## Phase 2 — Turn-Based Combat Foundation

Build the core battle system with physical attacks, rows, turn order, and random encounters — enough to fight and win.

- 6-member party battle system with front row (3) and back row (3)
- Turn structure: assign all 6 commands, then resolve in SPD order
- Battle commands: Attack, Defend, Item (consumables), Shift (swap rows)
- Top-level options: Fight, Run (LCK + level gap), Bribe (pay potch), Auto (all attack)
- Weapon range system: Short (front only → front enemies), Medium (both rows → front enemies), Long (both rows → all enemies)
- Physical damage formula: Raw = (ATK × modifiers) − DEF, with randomized spread (±1–9 or ±1–3 based on Raw threshold), clamped to 0 minimum
- ATK derived from STR + weapon power; DEF derived from PROT + armor totals
- Critical hits scaling with LCK
- SPD-based multi-hit follow-ups on additional enemies (never same enemy twice, requires 2+ enemies)
- Random encounter triggering on field maps and overworld
- Enemy AI: basic targeting (random, lowest HP, front row preference)
- Battle victory: potch drop, EXP distribution
- 4 starter party characters: Riou (S-range), Nanami (S-range), Jowy (S-range), Viktor (S-range)
- 4 basic enemy types: 2 melee, 1 ranged, 1 group (to test row targeting)

### Assets

**Sprites**
- Riou, Nanami, Jowy, Viktor — battle sprites (idle, attack, defend, hit, faint)
- 4 enemy sprites (e.g., Highland Soldier, Cutrabbit, Worm, Hawk)
- Battle row position markers

**2D Art**
- Nanami, Jowy, Viktor portraits
- Battle background (Kyaro forest area)

**VFX**
- Physical attack slash
- Critical hit flash
- Defend shield glow
- Damage number popups
- Enemy defeat dissolve

**Audio**
- Regular battle music
- Victory fanfare
- Battle encounter transition SFX
- Sword slash SFX (S-range)
- Hit/damage received SFX
- Critical hit SFX
- Character faint SFX
- Enemy defeat SFX
- Flee success/fail SFX
- Menu select SFX (battle command)

**UI**
- Battle HUD: character names, current/max HP, weapon range indicator (S/M/L), front/back row layout
- Battle command menu (Attack, Defend, Item, Shift)
- Top-level battle menu (Fight, Run, Bribe, Auto)
- Enemy targeting cursor
- EXP/potch reward screen

---

## Phase 3 — Stats, Equipment & Leveling

Add character progression: the full stat model, equipment management, EXP scaling, and a first dungeon with a boss.

- Full 10-stat system: HP, STR, DEX, PROT, MAG, MDEF, SPD, LCK (base); ATK, DEF (derived)
- Per-character growth rates (rank tiers) applied on level-up
- Level cap: 99; soft stat cap: 255 from leveling
- EXP rubber-band: scaled by level gap between party member and enemy. Lower-level characters gain dramatically more; higher-level characters gain diminishing returns
- Fainted characters earn no EXP unless revived before battle ends
- Equipment slots: Head, Body, Shield, Accessory
- Armor class restrictions: Robes (R), Martial Arts (MA), Light Armor (Lt), Heavy Armor (Hvy) — each character compatible with one class
- Shield equip/not-equip per character; accessory restrictions by age/race
- Weapon sharpening foundation: each character has a unique named weapon, upgraded by level (1–16) at blacksmiths — no weapon drops or purchases
- Party bag: 30 shared item slots; items must be placed on a character for battle use
- Consumable items: Medicine, Mega Medicine, Antitoxin, Escape Talisman
- Stat-boosting stones: Stone of Power, Skill, Defense, Magic Defense, Magic, Speed, Luck (+1 to +3)
- One dungeon (Sindar Ruins) with fixed enemy encounter table, treasure chests, and a boss encounter
- Flik added as 5th party character (M-range) to test medium-range mechanics

### Assets

**Sprites**
- Flik — field sprite (walk, dash, idle) and battle sprite (idle, attack, defend, hit, faint)
- 3–4 dungeon enemy types (distinct from Kyaro enemies)
- 1 boss sprite (Sindar Ruins boss)

**Tilemaps**
- Sindar Ruins dungeon (multi-room layout with branching paths)

**2D Art**
- Flik portrait
- Battle background (Sindar Ruins interior)
- Treasure chest open/closed sprites

**VFX**
- Level-up flash
- Stat increase popup

**Audio**
- Dungeon exploration music (Sindar Ruins)
- Boss battle music
- Boss defeat fanfare
- Treasure chest open SFX
- Equipment equip/unequip SFX
- Level-up SFX
- Stat stone use SFX

**UI**
- Equipment screen: slot display (Head, Body, Shield, Accessory), stat comparison on hover
- Status screen: full 10-stat display per character, level, EXP to next
- Item management: party bag with assign-to-character flow
- Boss HP bar

---

## Phase 4 — Rune Magic System

Introduce the rune-based magic system — spell casting, elemental interactions, rune attachment, and weapon runes.

- Rune slot system: Right Hand (available from recruitment), Left Hand (~level 25), Head (~level 40); varies per character
- Fixed rune slots: some characters have permanently attached runes (e.g., Riou's Bright Shield Rune on Right Hand)
- MP system: per-level spell charges (not a shared pool). MAG stat determines charges per level. ~101 MAG for 1 Level 4 cast; ~161 MAG for 2 Level 4 casts
- Rune command added to battle menu; opens spell list showing spell names, levels, remaining charges
- 3 starter magic runes with 4-level spell progressions:
  - Fire/Rage: Fire Wall (~150, row) → Dancing Flames (~300, all) → Explosion (~700, all) → Final Flame (~900, all)
  - Water/Flowing: Kindness Rain (heal one) → Protect Mist (DEF up) → Silent Lake (silence all) → Mother Ocean (full heal all)
  - Wind/Cyclone: Wind of Sleep (sleep, row) → The Shredding (dmg, one) → Healing Wind (heal all) → Shining Wind (revive + heal all)
- Magic damage formula: spell base power × caster MAG × rune affinity modifier − target MDEF
- Elemental cycle: Fire → Wind → Earth → Lightning → Water → Fire (increased damage to next, reduced to previous)
- Rune affinity grades per character per element: A (+40%), B (+20%), C (×1), D (−20%), E (+20% but 20% backfire chance)
- 3 starter weapon runes: Poison (40% chance on hit), Double-Beat (two attacks same target), Double-Strike (×2 damage dealt and received)
- 2 starter special effect runes: Gale (SPD ×1.5), Wall (DEF ×2)
- Rune shop NPC: attach/remove runes for a fee
- Rune attachment at Rune Shop in Kyaro Town

### Assets

**Sprites**
- Rune orb item sprites (one per rune type, color-coded by element)

**VFX**
- Fire Wall (flame wave across enemy row)
- Dancing Flames (fire engulf all enemies)
- Explosion (large fire burst, all enemies)
- Final Flame (ultimate fire, all enemies)
- Kindness Rain (water droplets, heal one)
- Protect Mist (blue shield aura, DEF buff)
- Silent Lake (water dome, silence)
- Mother Ocean (tidal wave, full heal)
- Wind of Sleep (green swirl, sleep effect)
- The Shredding (wind blades, single target)
- Healing Wind (green glow, party heal)
- Shining Wind (radiant wind, revive + heal)
- Poison proc (purple bubbles on hit)
- Double-Beat second strike flash
- Backfire explosion (E-grade affinity failure)
- Generic rune equip/unequip glow

**Audio**
- Fire spell SFX (3 tiers: small, medium, large)
- Water spell SFX (healing chime, wave crash)
- Wind spell SFX (gust, howl)
- Poison proc SFX
- Silence inflict SFX
- Sleep inflict SFX
- Buff applied SFX (DEF up, SPD up)
- Backfire SFX
- Rune attach/detach SFX

**UI**
- Rune menu screen: equipped runes per slot, spell list with charges
- Rune shop interface: attach/remove, character select, slot select
- Spell targeting cursor (single, row, all)
- Elemental weakness/resistance indicators during targeting

---

**Vertical slice checkpoint — One town (Kyaro), one dungeon (Sindar Ruins) with a boss, 5-character party with physical combat, rune magic (3 elements), equipment, leveling with rubber-band EXP, and the core battle loop playable start to finish.**

---

## Phase 5 — Headquarters, Shops & Economy

Build the castle headquarters system, core facilities, the potch economy, and the weapon sharpening progression.

- North Window Castle as player headquarters
- Castle level system: Level 1 (1–30 recruits), Level 2 (31–61), Level 3 (62–100), Level 4 (101+); visual upgrades at each tier
- Recruitment framework: story auto-join, talk-and-ask, conditional (castle level, party member present, item required), challenge (minigame/duel), trade quest
- Party management: swap active party members at HQ
- Core HQ facilities (unlocked by recruiting the associated character):
  - Inn (Hilda) — rest and heal party
  - Item Shop (Alex) — buy/sell consumables
  - Armor Shop (Hans) — buy/sell equipment
  - Blacksmith (Tessei) — weapon sharpening
  - Rune Shop (Jeanne) — attach/remove runes (replaces town rune shops once recruited)
  - Appraiser (Lebrante) — identify ? items
- Weapon sharpening system: levels 1–16, costs 300–70,000 potch. Tessei limited by hammer tier: Iron (max 9), Copper (max 12), Silver (max 15), Gold (max 16). Town blacksmiths cap at 5–13 depending on town
- Warehouse (Barbara): 60-slot storage with Store, Retrieve, Strip, Arrange, Sell/Discard
- Potch economy: enemy drops, treasure chests, selling items. Shop pricing scales with story progression
- Trading Post system: 8 posts + HQ post, fluctuating buy/sell prices per goods. Key route: Ancient Text (Kobold Village 400–1,200 → Forest Village 25,000–35,000). Gordon recruitment requires 50,000 potch total profit

### Assets

**Sprites**
- Hilda, Alex, Hans, Tessei, Jeanne, Lebrante, Barbara, Gordon — field sprites
- 4 hammer items (Iron, Copper, Silver, Gold)

**Tilemaps**
- North Window Castle — Level 1 layout (interior rooms, exterior courtyard)
- North Window Castle — Level 2, 3, 4 layout variants (expanded wings, new rooms)

**2D Art**
- Hilda, Alex, Hans, Tessei, Jeanne, Lebrante, Barbara, Gordon — portraits
- Trading Post goods icons (Ancient Text, Crystal Ball, Deer Antler, etc.)

**Audio**
- Headquarters background music
- Weapon sharpening anvil SFX
- Shop buy/sell SFX
- Potch coin SFX
- Castle level-up fanfare
- New recruit jingle
- Warehouse store/retrieve SFX

**UI**
- Shop interface: buy/sell item lists with price, stat comparison
- Blacksmith interface: weapon select, level display, cost, hammer tier limit
- Warehouse interface: store/retrieve/strip/arrange/sell tabs
- Trading Post interface: goods list, buy/sell prices, profit tracker
- Castle level indicator
- Recruitment count display
- Party swap screen (available characters at HQ)

---

## Phase 6 — Unite Attacks & Status Effects

Layer in unite attacks, the full status effect system, and the remaining battle commands to complete regular combat depth.

- Unite attack system: specific character combinations trigger powerful joint attacks
- Unite command appears in battle menu when eligible characters are in the party
- Damage multipliers and side effects per unite (unbalanced after attack, self-damage, etc.)
- Representative subset of unite attacks for current roster:
  - Buddy Attack (Riou + Jowy): 1× all enemies
  - Family Attack (Riou + Nanami): 2× one enemy, Nanami unbalanced
  - Cross Attack (Viktor + Flik): 1.5× one enemy, 30% knockdown
  - Knight Attack (Miklotov + Camus): 2× one enemy, 30% unbalanced
  - Groupie Attack (Flik + Nina): 2.5× one enemy, Nina unbalanced
  - Double Leader Attack (Riou + Tir McDohl): 0.75× all enemies
- All 6 positive status effects: Anger (ATK ×1.5), Boost (ATK ×2, self-damage), Hyper (MAG +50%, +20% backfire), Invulnerable (immune 1 turn, cannot act), Regeneration (HP per turn), Toasty (HP regen duration)
- All 13 negative status effects: Poison (1/16 HP/turn, persists after battle), Sleep (no action, ×2 damage wakes), Silence (no rune magic), Paralysis (no action), Lose Balance (no attack/magic, items only), Shrink (ATK −50%), Bucket (accuracy −50%), Balloon (3 stacks → removed), Panic (uncontrollable), Target (enemies focus this character), Unfriendly (no unite attacks), Rust (weapon level −1), Faint (0 HP, no EXP)
- Status effect cures: items (Antitoxin, Needle, etc.) and food items
- Firefly Rune: intentionally inflicts Target on self (tank strategy)
- Exertion Rune: ATK × (1 + turn_number / 6), capping at ×2 on turn 6
- 6 additional party characters for testing unites: Miklotov (M-range), Camus (S-range), Nina (L-range), Tir McDohl (S-range), Gengen (S-range), Kinnison (L-range)

### Assets

**Sprites**
- Miklotov, Camus, Nina, Tir McDohl, Gengen, Kinnison — field and battle sprites
- Shiro (Kinnison's wolf) — battle sprite

**2D Art**
- Miklotov, Camus, Nina, Tir McDohl, Gengen, Kinnison — portraits

**VFX**
- Unite attack cut-in animations (per unite: Buddy Attack, Family Attack, Cross Attack, Knight Attack, Groupie Attack, Double Leader Attack)
- Poison bubbles (on-hit proc + per-turn tick)
- Sleep Z's particle
- Silence seal icon
- Paralysis spark
- Lose Balance wobble
- Shrink size-down effect
- Bucket overlay
- Balloon inflate (×1, ×2, ×3 + float away)
- Panic swirl
- Target crosshair marker
- Anger red aura
- Boost power-up glow
- Hyper magic shimmer
- Invulnerable golden shield
- Regeneration green pulse
- Toasty warmth glow
- Rust corrosion effect on weapon

**Audio**
- Unite attack activation SFX (dramatic chord)
- Per-unite attack SFX (sword clashes, combined strikes)
- Poison tick SFX
- Sleep SFX (lullaby chime)
- Silence SFX (mute effect)
- Paralysis SFX (electric crackle)
- Status cure SFX
- Anger roar SFX
- Boost power SFX

**UI**
- Unite command in battle menu with eligible pair/group indicator
- Status effect icons on battle HUD (per character)
- Status effect icon on pause menu status screen
- Cure item targeting for status removal

---

## Phase 7 — Duel System & Army Battles

Build the two alternate combat modes: one-on-one duels and grid-based army battles.

- **Duel system:**
  - One-on-one battle with 3 actions: Attack (beats Defend), Wild Attack (beats Attack), Defend (beats Wild Attack)
  - Attack: moderate damage. Wild Attack: heavy damage, but Defend reflects it back. Defend: reduces incoming
  - Opponent dialogue telegraph: each opponent has unique dialogue lines that hint at their next action
  - Duel HUD: both characters' HP bars, dialogue display, 3-action selection
  - 1 test duel (Flik) to validate system

- **Army battle system:**
  - Grid-based tactical map with terrain tiles
  - Units composed of 1 commander + up to 2 sub-commanders
  - 4 unit types determined by commander: Infantry (narrow move, 1-tile range), Cavalry (wide move, 1-tile range), Archer (medium move, 2-tile range), Mage (medium move, 3-tile range, 0 melee)
  - Commands per unit: Attack, Rune (special ability, limited uses), Wait
  - Type advantage: strong vs. weak = damage ×2 / received ÷2; weak vs. strong = damage ÷2 / received ×2
  - Unit ATK/DEF derived from commander stats + sub-commander bonuses (+0 to +3 ATK, +0 to +2 DEF)
  - Special abilities: Cavalry (+2 movement), Flight (+2 movement + ignore terrain, stacks with Cavalry), Shortcut (ignore terrain), Encourage (adjacent allies act again), Critical (random bonus damage), Melee (bonus vs. Mage/Archer), Fire Spear (3-tile line, limited), Bombard (5-tile range, limited), Repair Self (heal, limited)
  - Abilities do not stack within a unit
  - "Leave it to Apple" AI automation option
  - Victory: defeat all enemy units. Failure: protagonist's unit destroyed → bad ending. Oulan's Bodyguard prevents character death on unit defeat
  - 1 test army battle scenario to validate system

### Assets

**Sprites**
- Duel character sprites: Riou and Flik (duel-specific idle, attack, wild attack, defend, hit poses)
- Army battle unit tokens (Infantry, Cavalry, Archer, Mage — player and enemy variants)

**Tilemaps**
- 1 army battle grid map (plains terrain with varied tiles)

**2D Art**
- Duel background (Mercenary Fortress courtyard)
- Army battle terrain tile set (grass, road, forest, hill, water)

**VFX**
- Duel: Attack slash, Wild Attack heavy slash, Defend parry flash, damage reflected effect
- Army: unit attack animation, unit defeated explosion, Fire Spear trail, Bombard impact, Repair Self heal glow, Encourage pulse wave

**Audio**
- Duel music
- Duel attack SFX, wild attack SFX, defend block SFX, damage reflected SFX
- Army battle music
- Army unit move SFX
- Army unit attack SFX
- Army unit defeated SFX
- Army ability activation SFX (Fire Spear, Bombard, Encourage, Repair Self)
- Army victory fanfare
- Army defeat sting

**UI**
- Duel HUD: dual HP bars, dialogue box, 3-action selector (Attack, Wild Attack, Defend)
- Army battle HUD: grid overlay, unit info panel (commander, sub-commanders, ATK, DEF, abilities), command menu (Attack, Rune, Wait), turn indicator
- Army unit composition screen (assign sub-commanders pre-battle)
- "Leave it to Apple" toggle

---

## Phase 8 — Overworld & Prologue Arc

Connect the world together with the overworld map, story gating, and the first two story arcs (Prologue and South Window founding).

- World map: 2D overworld with scaled/rotated scrolling terrain, connecting towns and dungeons
- Overworld fields: Areas A–H with distinct random encounter tables
- Suiko Map minimap (bottom-right, unlocked by recruiting Templeton)
- Viki's Blinking Mirror: teleport party back to HQ from field
- Story gating: areas unlock as narrative advances
- Narrative scripting: cutscenes, forced party composition, story flags, branching dialogue choices

- **Prologue / Escape arc:**
  - Kyaro Town (already built in Phase 1; add story NPCs and events)
  - Mercenary Fortress (pre-destruction state)
  - Ryube Village, Ryube Forest
  - North Sparrow Pass
  - Flight from Highland, party separation events

- **South Window & Founding arc:**
  - South Window City, Coronet Town, Kuskus Town, Radat Town
  - North Window (dungeon, pre-castle)
  - Establishing New State Army HQ at North Window Castle
  - Core story recruits join automatically

### Assets

**Sprites**
- Story NPCs for Prologue: Highland soldiers, Luca Blight (field cameo), Pohl, Pilika
- 8–10 new recruitable character field sprites (story auto-joins during these arcs)
- Overworld Riou sprite (scaled-down for world map)
- Overworld enemy encounter sprites (ambush flash)

**Tilemaps**
- Mercenary Fortress (interior + exterior)
- Ryube Village
- Ryube Forest (dungeon)
- North Sparrow Pass (dungeon path)
- South Window City
- Coronet Town
- Kuskus Town
- Radat Town
- North Window (dungeon)
- Overworld terrain map (full Dunan region)

**2D Art**
- Story character portraits (Luca Blight, Pilika, Pohl, and arc-specific NPCs)
- Battle backgrounds: Ryube Forest, North Sparrow Pass, North Window, overworld fields (Areas A–C)
- Overworld terrain tiles (plains, forest, mountain, river, road)

**VFX**
- Cutscene fade transitions
- Mercenary Fortress fire/destruction effect

**Audio**
- Overworld exploration music
- Ryube Village music
- South Window City music
- Coronet Town music
- Kuskus Town music
- Radat Town music
- Mercenary Fortress music (pre-destruction + burning)
- North Sparrow Pass dungeon music
- North Window dungeon music
- Prologue story event music (escape, pursuit)
- Cutscene dramatic stings (2–3 variants)

**UI**
- World map minimap (Suiko Map)
- Blinking Mirror use confirmation prompt
- Story chapter/location title card

---

## Phase 9 — Story Arcs: Two River through Tinto

Build out the middle story arcs, their towns and dungeons, and the first army battles and duels in context.

- **Two River arc:** defending the multi-racial city from Highland siege
  - First army battle (defense of Two River)
  - Castle Level 2 trigger (31+ recruits)
- **Greenhill arc:** infiltrating the occupied academy city, liberation
  - Undercover gameplay segment
  - Castle Level 3 trigger (62+ recruits)
- **Tinto / Neclord arc:** vampire sideplot, alliance with the mining city
  - Neclord boss: immune to all damage except Star Dragon Sword (Viktor's unique weapon)
  - Nanami's plea branching point → **Bad ending** if player accepts fleeing
- Duel: Amada (Two River arc)
- Additional army battles during Greenhill and Tinto arcs
- ~20 new recruitable characters across these arcs (talk-and-ask, conditional, challenge types)
- Enemy encounter tables for all new areas

### Assets

**Sprites**
- ~20 new recruit field sprites + battle sprites for combat-capable recruits
- Neclord (field + boss battle sprite)
- Amada (field + duel sprite)
- Two River race-specific NPCs (humans, kobolds, wingers)
- Greenhill academy NPCs (students, faculty)
- Tinto miners and soldiers
- 12–15 new enemy types across all new areas
- 3–4 boss sprites (Two River, Greenhill, Neclord, arc mini-bosses)

**Tilemaps**
- Two River City (multi-district: human, kobold, winger)
- Two River Sewers (dungeon)
- Kobold Village
- Kobold Village Forest (dungeon)
- Greenhill City (occupied state + liberated state)
- Greenhill Forest (dungeon)
- Path to Matilda (partial access)
- Tinto City
- Crom Village
- Tinto Pass (dungeon)
- Tinto Mines (dungeon)
- Forest Village

**2D Art**
- Neclord, Amada portraits
- New recruit portraits (~20)
- Battle backgrounds: Two River Sewers, Kobold Village Forest, Greenhill Forest, Tinto Pass, Tinto Mines, overworld fields (Areas D–F)
- Duel background: Two River arena (Amada duel)
- Army battle maps: Two River defense, Greenhill liberation (2 maps)

**VFX**
- Neclord dark magic attacks
- Star Dragon Sword special damage effect (bypasses Neclord immunity)
- Army battle map-specific effects (siege, terrain destruction)

**Audio**
- Two River City music
- Kobold Village music
- Greenhill City music (occupied + liberated variants)
- Forest Village music
- Tinto City music
- Crom Village music
- Two River Sewers dungeon music
- Greenhill Forest dungeon music
- Tinto Mines dungeon music
- Neclord boss music
- Amada duel dialogue SFX
- Army battle music variant (siege/defensive)
- Bad ending music sting + scene

**UI**
- Bad ending screen and credits roll
- Undercover segment indicators (Greenhill infiltration)

---

## Phase 10 — Story Arcs: Matilda through Endgame & Endings

Complete the final story arcs, the climactic Luca Blight encounter, the final boss, and all four endings.

- **Matilda arc:** securing the Knightdom's allegiance
  - Duel: Han Cunningham
- **Luca Blight night ambush:**
  - Three consecutive battles with three pre-selected 6-member parties (led by Flik, Viktor, Riou)
  - Luca's HP carries across all 3 fights without regeneration; transitions at 2/3 and 1/3 HP
  - 3 actions per turn; resists all damage types; vulnerable to Lightning and Earth
  - Flaming Arrows (AoE fire) and multi-slash attacks
  - Concluding duel: Riou vs. Luca Blight
- **Rockaxe & L'Renouille final campaign:**
  - Timed dialogue prompt: Nanami's arrow scene (fast response required to save Nanami — prerequisite for Best ending)
  - Army battles during the final campaign
  - Castle Level 4 trigger (101+ recruits)
- **Beast Rune final boss:** multi-phase encounter; True Rune manifests after Jowy's defeat
- **Final duel:** Riou vs. Jowy Atreides
- **Four endings:**
  - Bad: already implemented in Phase 9 (Nanami's plea)
  - Standard: accept leadership at Great Hall after final boss
  - Alternate: refuse leadership → Tenzan Pass → defeat Jowy in duel twice
  - Best (True): all 108 Stars before Rockaxe + Nanami saved + no permanent army deaths + refuse leadership + defend-only in Jowy duel + refuse rune's offer
- Ending flags system: track recruitment count, Nanami survival, army deaths, duel choices

### Assets

**Sprites**
- Luca Blight — full boss battle sprite (multi-attack animations, Flaming Arrows, 3 actions/turn)
- Luca Blight — duel sprite
- Han Cunningham — field + duel sprite
- Beast Rune — multi-phase boss sprite (2–3 forms)
- Jowy Atreides — duel sprite (final duel variant)
- Gorudo — field sprite
- ~10 new recruit field + battle sprites
- 8–10 new enemy types (Highland elite, L'Renouille monsters)

**Tilemaps**
- Highway Village, Banner Village
- Path to Matilda, Mt. Rakutei (dungeons)
- Banner Pass (dungeon)
- Rockaxe (town + castle dungeon)
- L'Renouille (final dungeon)
- Tenzan Pass (ending location)
- Highland Garrison (dungeon)
- Lampdragon Mountain (dungeon)
- Great Hall (ending scene location)

**2D Art**
- Luca Blight, Han Cunningham, Gorudo, Beast Rune portraits
- New recruit portraits (~10)
- Battle backgrounds: Mt. Rakutei, Banner Pass, Rockaxe Castle, L'Renouille, Tenzan Pass
- Duel backgrounds: Han Cunningham duel, Luca Blight night ambush, Jowy final duel
- Army battle maps: Matilda campaign, Rockaxe siege, L'Renouille assault (3 maps)
- Ending scene illustrations (4 endings)

**VFX**
- Luca Blight Flaming Arrows (AoE fire wave)
- Luca Blight multi-slash (3 consecutive attacks)
- Beast Rune phase transition effects
- Beast Rune unique attack VFX
- Bright Shield Rune healing Jowy (Best ending scene)
- Nanami arrow scene (arrows, shield)
- Ending-specific cutscene effects

**Audio**
- Luca Blight boss music (unique track)
- Luca Blight duel music
- Final dungeon music (L'Renouille)
- Beast Rune boss music
- Jowy final duel music
- Han Cunningham duel music
- Matilda area music
- Rockaxe town/castle music
- Standard ending music
- Alternate ending music
- Best (True) ending music
- Credits music
- Nanami arrow scene dramatic sting
- Luca Blight Flaming Arrows SFX
- Beast Rune attack SFX (per phase)
- Ending narration voice / text advance SFX

**UI**
- Three-party selection screen (Luca Blight night ambush)
- Timed dialogue prompt indicator (Nanami arrow scene)
- Ending title cards
- Credits roll screen

---

## Phase 11 — Minigames & Side Content

Add all headquarters minigames, the detective system, Clive's timed quest, and the cook-off sub-plot.

- **Cook-off minigame (Hai Yo):**
  - Iron Chef-style: prepare 3-course meal (appetizer, main course, dessert)
  - Panel of 4 judges (randomly selected from 108 Stars); host hints at preferences
  - Score 0–5 per dish per judge; highest total wins
  - 5 preparation variants per dish using ingredients (Sugar, Salt, Mayonnaise, Red Pepper, Soy Sauce)
  - Winning earns opponent's recipe; losing risks Moon Bird Recipe
  - Full sub-plot: Hai Yo vs. Black Dragon Clan

- **Chinchirorin (Shilo):** dice gambling with 3 dice, standard chinchirorin rules. Winning 5,000 potch at Lakewest recruits Shilo. Available at HQ after recruitment

- **Whack-a-Mole (Tony):** reaction minigame at the Farm. Unlocked by recruiting Tony from Forest Village

- **Rope Climbing:** laundry area at HQ. Available at Castle Level 2+

- **Fishing:** available at various water locations across the world

- **Dancing Stage:** rhythm-based minigame at HQ, unlocked via recruited characters

- **Richmond's Investigations:** pay 100–800 potch per secret; 2–4 secrets per character. Some secrets locked behind other recruitment conditions. Detective Agency facility at HQ

- **Clive's Quest:** timed sidequest following the Howling Voice Guild storyline. Must reach: Lakewest <11h, Forest Village <13h, Rockaxe <14h, Radat <15h (cumulative play-time)

- **Bath (Tetsu):** place antique items in the bath area; specific combinations trigger unique bath scenes

### Assets

**Sprites**
- Hai Yo — field sprite
- Richmond — field sprite
- Clive — field sprite
- Elza — field sprite (Clive's Quest)
- Shilo — field sprite
- Tony — field sprite
- Tetsu — field sprite
- Cook-off opponent sprites (Black Dragon Clan chefs)
- Mole sprites (Whack-a-Mole)
- Fish sprites (various species)

**2D Art**
- Hai Yo, Richmond, Clive, Elza, Shilo, Tony, Tetsu — portraits
- Cook-off stage background
- Cook-off dish illustrations (appetizer, main, dessert variants)
- Cooking ingredient icons
- Chinchirorin dice face sprites
- Chinchirorin table background
- Whack-a-Mole field background
- Rope Climbing background
- Fishing location backgrounds
- Bath scene backgrounds with antique display slots
- Dancing Stage background

**VFX**
- Cook-off cooking animations (chop, fry, boil)
- Cook-off judge reaction animations (pleased, disgusted, neutral)
- Chinchirorin dice roll animation
- Whack-a-Mole hit/miss effects
- Fishing line cast and reel animations
- Fish bite indicator

**Audio**
- Cook-off music
- Cook-off chopping SFX, sizzle SFX, judge reaction SFX
- Cook-off win/lose fanfare
- Chinchirorin dice roll SFX, win SFX, lose SFX
- Whack-a-Mole hit SFX, miss SFX, mole pop-up SFX
- Rope Climbing effort SFX, success SFX
- Fishing cast SFX, reel SFX, splash SFX, catch SFX
- Dancing Stage music (rhythm track)
- Bath relaxation music
- Richmond investigation reveal SFX
- Clive's Quest event music (Howling Voice Guild theme)

**UI**
- Cook-off interface: ingredient selection, dish prep, judge scoring panel
- Chinchirorin interface: bet amount, dice display, payout
- Whack-a-Mole game screen with score/timer
- Rope Climbing game screen with height meter
- Fishing interface: cast power, reel tension, catch display
- Dancing Stage rhythm interface
- Richmond investigation dialogue screens
- Clive's Quest play-time tracker (internal; no explicit UI in original)
- Bath antique placement interface

---

## Phase 12 — Full Roster & Recruitment Completion

Populate all 108 Stars of Destiny with unique recruitment conditions, complete the unite attack roster, and fill out all runes and army battle content.

- All 108 Stars of Destiny with per-character recruitment conditions (story auto-join, talk-and-ask, conditional, challenge, missable — per §4.1)
- Missable character tracking: flag warnings or ensure story-gating aligns with recruitment windows
- All remaining magic runes:
  - Earth/Mother Earth: Clay Guardian → Earthquake (~300) → Copper Sun (~500) → Guardian Earth (~700)
  - Lightning/Thunder: Bolt of Wrath (~150) → Rainstorm (~250) → Soaring Bolt (~500) → Thunder Runner (~700)
  - Resurrection: Level 4 revive all fainted allies
  - Darkness and other remaining magic runes
- All character-specific runes: Bright Shield (Riou), Black Sword (Jowy), Star Dragon Sword (Viktor), Beast Rune
- All 5 Unite Magic combo spells (from Level 4 rune pairs):
  - Scorched Earth (Fire + Earth): ~1,300 all
  - Blazing Camp (Fire + Lightning): ~2,000 one + ~1,500 all
  - Water Dragon (Water + Wind): ~800 all + full heal
  - Thor (Water + Lightning): ~2,000 one + full heal
  - Storm Fang (Wind + Earth): ~1,000 all
- Complete unite attack roster: all 2-person, 3-person, 4-person, and 5-person unite attacks (~30 total), including:
  - Remaining 2-person: Warrior Attack, Trick Attack, Husband & Wife Attack, Dad & Daughter Attack, Manly Attack, Narcissus Attack, Winger Attack, Double Monster Attack, Double Kraken Attack, Loyal Dog Attack, Bow Wow Attack, Ninja Attack, Tackle Attack, Swordsman Attack, Bandit Attack, Servant Attack, Copycat Attack
  - 3-person: Bow Attack, Head's Up!!, Circus Attack, Flash Attack, Fancy Lad Attack, Pretty Girl Attack
  - 4-person: Beauty Attack, True Beauty Attack, Pretty Boy Attack, Beastmaster Attack, Twin Fighter Attack, Rival Attack
  - 5-person: 5 Squirrel Attack (instant kill, high probability)
- Listening Crystal choices: only 2 available — player chooses 2 of 3 monster recruits (Feather, Siegfried, Abizboah). Remaining unchosen monster is permanently unavailable; affects Rulodia recruitment and Double Monster/Double Kraken/Beastmaster unite availability
- All army battle special abilities populated across the full roster
- All remaining weapon runes and special effect runes not yet implemented

### Assets

**Sprites**
- Remaining ~70 recruit field sprites (non-combat HQ characters + remaining combat characters)
- Remaining combat character battle sprites (~50)
- Monster recruit sprites: Feather (griffon), Siegfried (unicorn), Abizboah (kraken), Rulodia (kraken)
- 5 Squirrels: Makumaku, Mikumiku, Mukumuku, Mekumeku, Mokumoku — field + battle sprites

**2D Art**
- Remaining ~70 character portraits
- Unite attack cut-in illustrations (all new unites)

**VFX**
- Earth magic VFX: Clay Guardian shield, Earthquake ground shake, Copper Sun radiance, Guardian Earth eruption
- Lightning magic VFX: Bolt of Wrath single strike, Rainstorm bolt barrage, Soaring Bolt massive strike, Thunder Runner chain lightning
- Resurrection revive glow
- Darkness magic VFX set
- Unite Magic VFX: Scorched Earth, Blazing Camp, Water Dragon, Thor, Storm Fang (5 large-scale combo spell effects)
- Remaining unite attack cut-in animations (~20+)
- 5 Squirrel Attack instant-kill animation
- Bright Shield Rune unique VFX
- Beast Rune unique VFX

**Audio**
- Earth spell SFX (rumble, cracking)
- Lightning spell SFX (thunder crack, electric arc)
- Resurrection spell SFX (heavenly chime)
- Darkness spell SFX (ominous drone)
- Unite Magic cast SFX (5 variants: Scorched Earth, Blazing Camp, Water Dragon, Thor, Storm Fang)
- Remaining unite attack SFX (~20+)
- 5 Squirrel Attack SFX
- Listening Crystal use SFX
- Monster recruit join jingle

**UI**
- Listening Crystal choice prompt (pick 2 of 3)
- Full recruitment checklist (108 Stars tracker — for player reference at HQ)

---

## Phase 13 — Collectibles, Save Transfer & Polish

Wire up all collectible systems, Suikoden I save transfer, cosmetic customization, and final polish across the full game.

- **Window Sets:** collectible items given to Tenkou to customize dialogue/menu window border color and shape
- **Sound Sets:** collectible items given to Connell to change in-game UI sound effects. Sound Set 1 (Elza, Muse), Sound Set 2 (Yellow Doremi Elf, Greenhill Forest)
- **Old Books:** library collection given to Barbara
- **Guardian Deity statue (Jude):** 16 plans across 4 segments (Head, Body, Legs, Tail) × 4 types (Dragon, Unicorn, Turtle, Rabbit). Combinations yield item rewards
- **Antique Items:** placed in the Bath for cosmetic display; specific combinations trigger unique bath scenes
- **Recipe collection:** all recipes for Cook-off minigame, including Recipe #39 (Special Stew) from Suikoden I transfer
- **Suikoden I save transfer system:**
  - Detect Suikoden I clear save / final save point at new game start
  - Level bonuses for returning characters: +1 per 10 levels above 60
  - Weapon level bonuses: old levels 12–16 boost starting weapons
  - Equipment transfer: Tir retains armor; Humphrey may transfer Windspun Armor
  - 108 Stars in old save → Gremio alive + Recipe #39
  - Tir McDohl becomes recruitable (enables Double Leader Attack)
- **Sound mode:** Stereo/Mono toggle in settings
- **Remaining overworld content:** ensure all 8 field areas (A–H) have finalized encounter tables and treasure placement
- **Remaining town content:** Gregminster, Rokkaku Hamlet, Drakemouth Village, Tigermouth Village, Sajah Village, Lakewest Town — if not already built during story phases, finalize now
- **Castle Forest** (dungeon) — remaining dungeon not covered by story arcs
- **Full enemy encounter tables:** finalize all area-specific enemy rosters, drop tables, EXP values
- **Balance pass:** weapon sharpening cost curve, shop price scaling, enemy stat tuning, rune affinity per-character tables, boss HP/damage tuning

### Assets

**Sprites**
- Tenkou, Connell, Jude — field sprites (if not already built)
- Remaining town NPCs for Gregminster, Rokkaku, Drakemouth, Tigermouth, Sajah, Lakewest
- Castle Forest enemy types

**Tilemaps**
- Gregminster (if not built during Suikoden I transfer content)
- Rokkaku Hamlet
- Drakemouth Village
- Tigermouth Village
- Sajah Village
- Lakewest Town
- Castle Forest (dungeon)

**2D Art**
- Tenkou, Connell, Jude — portraits (if not already built)
- Window Set frame variants (all collectible styles)
- Guardian Deity statue segment illustrations (16 plans)
- Antique item icons
- Old Book item icons
- Recipe card illustrations
- Battle backgrounds for remaining areas (Areas G–H, Castle Forest)
- Suikoden I transfer prompt screen art

**Audio**
- Remaining town music tracks: Gregminster, Rokkaku Hamlet, Drakemouth, Tigermouth, Sajah, Lakewest
- Castle Forest dungeon music
- Sound Set variant SFX packs (complete alternate UI sound profiles)
- Guardian Deity statue completion fanfare
- Window Set change SFX

**UI**
- Window Set preview/selection screen (Tenkou)
- Sound Set preview/selection screen (Connell)
- Library book collection screen (Barbara)
- Guardian Deity plan selection and result screen (Jude)
- Suikoden I save transfer detection prompt at new game
- Transfer bonus summary screen
- Final credits with full 108 Stars roll call
