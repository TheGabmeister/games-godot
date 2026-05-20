# The Legend of Zelda: A Link to the Past — Gameplay Systems Spec

Super Nintendo Entertainment System (SNES), 1991. Published by Nintendo. Developed by Nintendo EAD. This spec covers the original SNES release (NA). The 2002 GBA port (A Link to the Past & Four Swords) adds the Palace of the Four Sword post-game dungeon, Roc's Cape item, and the Four Swords multiplayer mode — none of which are covered here.

---

## 1. Core Gameplay Systems

### Primary Gameplay Loop

Top-down action-adventure. Link explores an overworld, enters dungeons, solves puzzles, defeats enemies, collects key items that unlock new areas, and defeats dungeon bosses to advance the story. The game is divided into two acts: Light World (3 pendant dungeons) and Dark World (7 crystal dungeons), culminating in a final boss gauntlet.

### Combat System

Real-time melee combat. Link faces 8 directions but attacks in the 4 cardinal directions. No lock-on or targeting system — swings hit whatever is in the arc.

**Attack types:**

| Attack | Input | Damage Class | Notes |
|--------|-------|-------------|-------|
| Slash | B (tap) | Sword level | Standard arc swing |
| Spin Attack | B (hold ~30 frames, release) | Sword level + 1 | 360° arc, higher damage |
| Poke / Dash Attack | Pegasus Boots dash + B | Sword level - 1 | Lower damage, high speed |
| Sword Beam | B (at full health, Master Sword+) | Matches sword level | Ranged projectile |

**Sword damage (standard subclass 1 enemies):**

| Attack | Fighter's (L1) | Master (L2) | Tempered (L3) | Golden (L4) |
|--------|:-:|:-:|:-:|:-:|
| Slash | 2 | 4 | 8 | 16 |
| Spin Attack | 4 | 8 | 16 | 16 |
| Poke / Dash | 2 | 2 | 4 | 8 |
| Sword Beam | — | ~4 | ~8 | ~16 |

Each successive sword doubles the previous. Spin attack uses one damage class higher than slash (Golden Sword spin caps at the same 16 since Class 5 = Class 4 values).

**Damage calculation:** The game uses a 16-class × 8-subclass lookup table. Each weapon has a damage class (0x0–0xF); each enemy sprite has a per-class subclass assignment (0–7). The pair indexes into a ROM table for the final damage value or special effect (stun, freeze, burn, transform). Full tables in [docs/zelda-lttp/enemies.md](docs/zelda-lttp/enemies.md).

**Comparative weapon damage (subclass 1):**

| Weapon | Damage |
|--------|:------:|
| Boomerang | 1 (or stun) |
| Fighter's Sword | 2 |
| Thrown object (pot, bush, rock) | 2 |
| Master Sword / Arrow / Bomb | 4 |
| Tempered Sword / Fire Rod / Ice Rod / Hammer | 8 |
| Golden Sword / Bombos | 16 |
| Quake Medallion | 32 |
| Silver Arrow | 100 |

**Invincibility frames:** 58 frames (~0.97 seconds at 60 fps) after taking damage. Link's sprite blinks during this window. Recoil/knockback prevents movement input for a separate timer.

### Health System

| Stat | Value |
|------|-------|
| Starting hearts | 3 |
| Boss Heart Containers | 11 (Hyrule Castle escape + 10 dungeon bosses) |
| Heart Pieces in world | 24 (4 pieces = 1 container) |
| **Maximum hearts** | **20** (3 + 11 + 6) |
| Internal representation | 1 heart = 0x08; full 20 hearts = 0xA0 (160) |

Incoming damage is modified by armor (§5 Armor). Damage reduction is not a clean multiplier — each of the 10 bump classes (0x00–0x09) has independently defined values per mail tier. Bump classes 0x01 and 0x04 are **not reduced** by any armor. See [docs/zelda-lttp/enemies.md](docs/zelda-lttp/enemies.md) for the full bump damage table.

### Magic System

| Stat | Value |
|------|-------|
| Max magic (internal) | 0x80 (128) |
| Small magic jar refill | 0x10 (1/8 meter) |
| Large magic jar refill | 0x40 (1/2 meter) |
| Green Potion | Full meter |
| 1/2 Magic upgrade | Mad Batter (sprinkle Magic Powder at shrine near Dwarven Swordsmiths) |

**Magic costs per item:**

| Item | Base Cost | With 1/2 Magic |
|------|:---------:|:--------------:|
| Lamp | 4 | 2 |
| Fire Rod | 8 | 4 |
| Ice Rod | 8 | 4 |
| Magic Powder | 4 | 2 |
| Cane of Somaria | 8 | 4 |
| Bombos / Ether / Quake | 32 (1/4 meter) | 16 |
| Cane of Byrna | 16 initial + drain | 8 + half drain |
| Magic Cape | Sustained drain (~4 frames/tick) | Half rate |

### Movement

| Movement | Speed | Pattern |
|----------|-------|---------|
| Walk (cardinal) | 1.5 px/frame avg | Alternates 2px, 1px |
| Walk (diagonal) | 1.0 px/frame per axis | Constant 1px both axes |
| Slowed (sword out, carrying, tall grass) | 1.25 px/frame | 2-1-1-1 |
| Dash (Pegasus Boots, cardinal) | 4.0 px/frame | Constant |
| Dash (tall grass) | 3.0 px/frame | Constant |
| Swimming (max, cardinal) | ~0.9 px/frame | Acceleration-based |
| Swimming (button mash) | 1.5 px/frame | Acceleration-based |
| Stairs | 0.6875 px/frame avg | 1-1-1-0-1-1-0 |

Dash charge time: 29 frames. Direction changes reset the subpixel accumulator. Dashing into a wall causes a "bonk" — Link bounces back stunned for ~16 frames, can't act during this window. Bonking into certain objects (trees, bookshelves, piles of rocks) can dislodge hidden items.

Swimming uses acceleration/deceleration physics rather than fixed speeds.

No dedicated jump button. Ledge hops are automatic (20-frame initiation delay).

### Progression Systems

Progression is item-gated rather than level-based. There is no experience, no leveling. Power growth comes from:
- **Swords** (4 tiers, each doubling damage — §5)
- **Armor/Mail** (3 tiers, reducing incoming damage — §5)
- **Shields** (3 tiers, blocking more projectile types — §5)
- **Gloves** (2 tiers, lifting heavier objects to access new areas — §5)
- **Heart Containers** (from bosses and 24 scattered Heart Pieces)
- **Capacity upgrades** (bombs 10→50, arrows 30→70 via Pond of Happiness)
- **1/2 Magic** (effectively doubles magic meter)

---

## 2. Controls & Input

SNES controller. Single-player only.

| Button | Action |
|--------|--------|
| D-Pad | Move Link (8 directions) |
| B | Sword attack (tap = slash, hold + release = spin attack) |
| Y | Use equipped item (selected via inventory screen) |
| A | Dash (with Pegasus Boots); lift/pull/push objects; interact with NPCs; read signs |
| X | Open map screen (overworld map or dungeon map) |
| Start | Open inventory/item subscreen |
| Select | Save & Quit (from pause menu) |
| L / R | No function during gameplay |

Context-sensitive actions on A: talk to NPCs when facing them, read signs, open chests, lift pots/bushes/rocks (with appropriate gloves), push statues, pull levers.

---

## 3. World Structure

### Dual Overworlds

The game features two parallel overworlds of identical dimensions that mirror each other tile-for-tile:

**Light World** — The primary Hyrule overworld. Contains towns, friendly NPCs, and the 3 pendant dungeons.

**Dark World** — A corrupted parallel dimension. Every Light World location has a twisted counterpart. Contains the 7 crystal dungeons and Ganon's Tower.

| Light World | Dark World |
|-------------|------------|
| Hyrule Castle | Pyramid of Power |
| Kakariko Village | Village of Outcasts |
| Lost Woods | Skeleton Forest |
| Death Mountain | Dark Death Mountain |
| Eastern Palace area | Palace of Darkness area |
| Desert of Mystery | Misery Mire |
| Great Swamp | Swamp Palace area |
| Lake Hylia | Ice Lake |
| Graveyard | Dark World Graveyard |

### World Transitions

**Light World → Dark World — 9 fixed portals:**

| # | Location | Requirement |
|---|----------|-------------|
| 1 | Death Mountain (near Tower of Hera) | None |
| 2 | Hyrule Castle outcropping | None (hidden) |
| 3 | Kakariko Village area | Magic Hammer |
| 4 | Link's House / central swamp | Magic Hammer |
| 5 | South of Eastern Palace | Magic Hammer |
| 6 | Lake Hylia island | Titan's Mitt |
| 7 | Southwest desert (Flute point 6) | Titan's Mitt + Flute |
| 8 | Southern Death Mountain | Titan's Mitt + Hookshot |
| 9 | East Death Mountain (Turtle Rock) | Hit 3 stakes in order |

**Dark World → Light World:** The Magic Mirror warps Link to the corresponding Light World position, leaving a temporary shimmering portal. Stepping back through the portal returns to the Dark World. The portal disappears if the Mirror is used again. This is a core puzzle mechanic — warp to Light World from a Dark World ledge to reach an otherwise inaccessible spot, then step back through.

**Moon Pearl:** Without it (found in Tower of Hera), Link transforms into a helpless pink bunny in the Dark World, unable to fight or use items.

### Fast Travel

**Flute (Light World only):** Summons a bird that flies Link to one of 8 fixed destinations:

| # | Destination |
|---|-------------|
| 1 | Death Mountain entrance |
| 2 | Witch's Hut |
| 3 | Kakariko Village |
| 4 | Link's House |
| 5 | Eastern Palace |
| 6 | Desert of Mystery |
| 7 | Swamp Ruins |
| 8 | Lake Hylia |

**Combined travel:** Mirror to Light World → Flute to destination → find portal to re-enter Dark World in a different region.

### Dungeon Structure

Each dungeon contains:
- **Dungeon Map** — reveals room layout on the map screen
- **Compass** — marks chest locations and boss position on the map
- **Small Keys** — consumable; each opens one locked door in the current dungeon (not transferable between dungeons)
- **Big Key** — opens the boss door and all large treasure chests in the current dungeon
- **Key Item** — one major progression item per dungeon (see §4)
- **Boss** — defeating it yields a Heart Container and the dungeon's reward (Pendant or Crystal)

Dungeon progress (opened doors, collected keys/items) persists through death. Keys are dungeon-specific and cannot be stockpiled across dungeons.

---

## 4. Story & Progression

### Act 1 — Light World (Pendant Dungeons)

| # | Dungeon | Key Item | Boss | Reward |
|---|---------|----------|------|--------|
| 0 | Hyrule Castle (escape) | Lamp, Fighter's Sword & Shield | — | Rescue Zelda |
| 1 | Eastern Palace | **Bow** | Armos Knights | Pendant of Courage |
| 2 | Desert Palace | **Power Glove** | Lanmolas | Pendant of Power |
| 3 | Tower of Hera | **Moon Pearl** | Moldorm | Pendant of Wisdom |
| — | Agahnim's Tower | — | Agahnim | Opens Dark World |

After all 3 Pendants: retrieve the **Master Sword** from the Lost Woods pedestal. Then storm Agahnim's Tower to confront the sorcerer Agahnim, who banishes Link to the Dark World.

### Act 2 — Dark World (Crystal Dungeons)

| # | Dungeon | Key Item | Boss | Reward |
|---|---------|----------|------|--------|
| 4 | Palace of Darkness | **Magic Hammer** | Helmasaur King | Crystal 1 |
| 5 | Swamp Palace | **Hookshot** | Arrghus | Crystal 2 |
| 6 | Skull Woods | **Fire Rod** | Mothula | Crystal 3 |
| 7 | Thieves' Town | **Titan's Mitt** | Blind the Thief | Crystal 4 |
| 8 | Ice Palace | **Blue Mail** | Kholdstare | Crystal 5 |
| 9 | Misery Mire | **Cane of Somaria** | Vitreous | Crystal 6 |
| 10 | Turtle Rock | **Mirror Shield** | Trinexx | Crystal 7 |

### Act 3 — Endgame

| # | Dungeon | Key Item | Boss | Reward |
|---|---------|----------|------|--------|
| 11 | Ganon's Tower | **Red Mail** | Agahnim (rematch) + boss rush | Opens Pyramid |
| 12 | Pyramid of Power | — | **Ganon** (Silver Arrows required) | Triforce |

### Key Item Gates

| Item | Unlocks |
|------|---------|
| Lamp | Light dark rooms |
| Book of Mudora | Enter Desert Palace; obtain Ether/Bombos Medallions |
| Power Glove | Lift light rocks |
| Moon Pearl | Maintain human form in Dark World |
| Master Sword | Deflect Agahnim's magic; break barrier to Agahnim's Tower |
| Magic Hammer | Pound stakes; access most Dark World portals |
| Hookshot | Cross gaps in later dungeons |
| Titan's Mitt | Lift heavy rocks; access Ice Palace, Misery Mire, Turtle Rock regions |
| Flippers | Swim in deep water |
| Flute | Bird fast travel (Light World) |
| Fire Rod + Ice Rod | Both required for Trinexx (Turtle Rock boss) |
| Ether Medallion | Opens Misery Mire entrance |
| Quake Medallion | Opens Turtle Rock entrance |
| Silver Arrows | Required to kill Ganon (final phase) |

### Required Dungeon Order

Palace of Darkness must be first in Act 2 (Magic Hammer gates all other Dark World paths). Thieves' Town must precede Ice Palace, Misery Mire, and Turtle Rock (Titan's Mitt gates their portals). Within those constraints, order is flexible.

### No Branching, No Multiple Endings, No New Game+

Single linear story. One ending. No post-game content beyond finding remaining collectibles on the save file.

---

## 5. Items & Equipment

### Swords (Progressive)

| Sword | Damage | How Obtained |
|-------|:------:|-------------|
| Fighter's Sword | 1× | Uncle in Hyrule Castle escape |
| Master Sword | 2× | Lost Woods pedestal (3 Pendants) |
| Tempered Sword | 4× | Reunite Dwarven Swordsmiths; costs 10 Rupees |
| Golden Sword | 8× | Throw Tempered Sword into Pyramid Fairy fountain |

Master Sword and above fire sword beams at full health.

### Shields (Progressive)

| Shield | Blocks | How Obtained |
|--------|--------|-------------|
| Fighter's Shield | Arrows, rocks | Uncle; buyable (50 Rupees) |
| Red Shield | + fireballs | Waterfall of Wishing (throw in Fighter's Shield) or Dark World shop (500 Rupees) |
| Mirror Shield | + laser beams; reflects | Turtle Rock dungeon |

Fighter's and Red Shields can be eaten by Like-Likes, requiring replacement.

### Armor (Progressive)

| Mail | Damage Reduction | Location |
|------|:----------------:|----------|
| Green Mail | 0% | Starting equipment |
| Blue Mail | ~50% | Ice Palace |
| Red Mail | ~75% | Ganon's Tower |

### Gloves (Progressive)

| Glove | Ability | Location |
|-------|---------|----------|
| Power Glove | Lift light (green) rocks | Desert Palace |
| Titan's Mitt | Lift heavy (dark) rocks | Thieves' Town |

### Y-Button Inventory Items

| Item | Upgrade | Location | Effect |
|------|---------|----------|--------|
| Bow & Arrows | → Silver Arrows (Pyramid Fairy) | Eastern Palace | Ranged attack; Silver Arrows required to kill Ganon |
| Boomerang | → Magical Boomerang (Waterfall of Wishing) | Hyrule Castle | Stuns enemies, retrieves items; Magical version has longer range |
| Hookshot | — | Swamp Palace | Grapples to objects, stuns/damages enemies |
| Bombs | — | Various; purchasable | Destroys cracked walls, damages enemies |
| Mushroom / Magic Powder | Mushroom traded to Witch | Lost Woods / Witch's Hut | Powder transforms enemies, lights torches |
| Fire Rod | — | Skull Woods | Shoots fireballs; lights torches at range |
| Ice Rod | — | Cave east of Lake Hylia | Freezes enemies |
| Bombos Medallion | — | Desert tablet (Book of Mudora + Master Sword) | Fire explosion, all on-screen enemies |
| Ether Medallion | — | Tower of Hera tablet (Book of Mudora + Master Sword) | Freeze/lightning, all on-screen; opens Misery Mire |
| Quake Medallion | — | Catfish in Dark World lake | Earthquake, all on-screen; opens Turtle Rock |
| Lamp | — | Link's House | Lights torches, illuminates dark rooms |
| Magic Hammer | — | Palace of Darkness | Pounds stakes, flips enemies |
| Flute | — | Dug up in Light World grove | Fast travel to 8 locations |
| Bug-Catching Net | — | Sick Boy in Kakariko | Catches Fairies/Bees; deflects Agahnim's magic |
| Book of Mudora | — | Kakariko library (dash into bookshelf) | Translates Hylian; required for Medallion tablets |
| Cane of Somaria | — | Misery Mire | Creates pushable blocks; blocks split into 4 projectiles |
| Cane of Byrna | — | Death Mountain cave (spike floor) | Protective barrier; drains magic |
| Magic Cape | — | Graveyard (dash into tombstone) | Invisibility + invulnerability; drains magic |
| Magic Mirror | — | Old Man on Death Mountain | Warps Dark World → Light World |
| Shovel | Replaced by Flute | Flute Boy in Dark World | Digs up buried items |

### Passive / Auto-Equipped Items

| Item | Location | Effect |
|------|----------|--------|
| Pegasus Boots | Sahasrahla (after Eastern Palace) | Dash; break obstacles |
| Zora's Flippers | King Zora (500 Rupees) | Swim in deep water |
| Moon Pearl | Tower of Hera | Prevents bunny transformation in Dark World |

### Bottles (4 total)

| # | Location |
|---|----------|
| 1 | Kakariko Bottle Merchant (100 Rupees) |
| 2 | Kakariko bar back entrance (bomb wall, open chest) |
| 3 | Under bridge near Link's House (requires Flippers) |
| 4 | Dark World locked chest (bring to Light World thief) |

**Bottle contents:**

| Content | Effect |
|---------|--------|
| Red Potion | Fully restores hearts |
| Green Potion | Fully restores magic |
| Blue Potion | Fully restores hearts AND magic |
| Fairy | Restores 7 hearts; auto-revives on death (7 hearts) |
| Bee | Attacks nearby enemies when released |
| Golden Bee | Stronger bee; longer duration; sellable for 100 Rupees |

### Upgrade Fountains

| Fountain | Location | Upgrades |
|----------|----------|----------|
| Waterfall of Wishing | Northeast (requires Flippers) | Fighter's Shield → Red Shield; Boomerang → Magical Boomerang |
| Pyramid Fairy | Pyramid crack (requires Super Bomb) | Tempered Sword → Golden Sword; Bow → Silver Arrows |
| Pond of Happiness | Lake Hylia island | +5 Bombs or +5 Arrows per 100 Rupees thrown (Bombs 10→50, Arrows 30→70) |

### Heart Pieces

24 total (4 pieces = 1 Heart Container = 6 additional containers).

**Light World (12):** Lost Woods bush pit; Kakariko Well (bomb wall); Thieves' Hideout basement; 15-Second Race; Swamp Ruins (drain lever); near Sanctuary (dash into rocks); Desert Cave (bomb south wall); Desert Palace ridge; Zora's Falls (swim south); Spectacle Rock cave; Spectacle Rock top (Mirror from Dark World); Lumberjack Tree (post-Agahnim).

**Dark World (12):** Pyramid right side; Digging Game; Treasure Chest Game; Stake Field (hammer all stakes); south of Haunted Grove (Mirror from plant ring); Ice Lake rock (Mirror); Ghostly Garden (Mirror, bomb cave); outside Skull Woods (Magic Cape past bumper); Misery Mire area (left cave); Misery Mire area (Mirror to Desert ridge); Turtle Rock area (invisible path); inside Turtle Rock (Mirror on ledge).

---

## 6. Enemies & Opponents

### Enemy Design Philosophy

Light World enemies deal less damage (bump classes 0x00–0x03, up to 1 heart) and have low HP (1–8). Dark World enemies are significantly tougher (bump classes 0x05–0x08, 2–4 hearts contact damage) with higher HP (4–64). Dungeon enemies escalate in parallel with the dungeon's position in the sequence.

### Behavioral Archetypes

| Archetype | Behavior | Examples |
|-----------|----------|----------|
| Patrol | Walks a fixed route, attacks on contact | Soldiers, Moblin |
| Charge-on-sight | Idles until Link enters line of sight, then rushes | Rope (snake), Tektite |
| Ranged | Fires projectiles from a distance | Octorok, Zora, Archers |
| Stationary-until-triggered | Dormant until approached or attacked | Armos Statue, Deadrock |
| Erratic | Moves in unpredictable bouncing patterns | Mini Moldorm, Keese |
| Thief | Steals items/shields on contact | Pikit (steals items), Like-Like (eats shields) |
| Invulnerable hazard | Cannot be destroyed; must be avoided | Spark, Roller, Beamos, Anti-Fairy |
| Phasing | Appears/disappears or teleports | Wizzrobe, Poe, Wallmaster |

### Representative Enemy Progression

| Area | Example Enemy | HP | Contact Damage (Green Mail) |
|------|---------------|:--:|:---------------------------:|
| Hyrule Castle | Green Soldier | 4 | 1/2 heart |
| Eastern Palace | Popo | 2 | 1/2 heart |
| Death Mountain | Lynel | 24 | 4 hearts |
| Dark World Overworld | Hinox | 20 | 3 hearts |
| Ice Palace | Pengator | 16 | 2 hearts |
| Misery Mire | Wizzrobe | 2 | 4 hearts |
| Ganon's Tower | Stalfos Knight | 64 | 2 hearts |

Full enemy tables with sprite IDs, HP, bump classes, and drop packs: [docs/zelda-lttp/enemies.md](docs/zelda-lttp/enemies.md).

### Boss Fights

#### Armos Knights (Eastern Palace)
- **HP:** 48 per knight × 6 knights
- **Contact:** 1/2 heart
- **Phases:** Stationary formation → rotating → contract/expand → row movement → final red knight (HP resets to full when last knight turns red)
- **Weakness:** Bow (16 damage per arrow, 3 arrows per knight)

#### Lanmolas (Desert Palace)
- **HP:** 16 per worm × 3 worms
- **Contact:** 1 heart
- **Behavior:** Emerge from ground, scatter rocks (4 rocks normally, 8 for last worm). First spawn fixed; subsequent spawns randomized.
- **Weakness:** Bow (4 damage per arrow, strongly favored over sword)

#### Moldorm (Tower of Hera)
- **HP:** 12 (tail only — head is invulnerable)
- **Contact:** 1 heart
- **Phases:** Normal speed → ~33% speed increase at low HP. 20-frame invulnerability after each hit.
- **Hazard:** Falling off platform resets boss HP to full.

#### Agahnim (Hyrule Castle Tower)
- **HP:** 96
- **Immune to all direct attacks.** Must reflect energy balls with sword (or Bug-Catching Net).
- **Cycle:** Energy ball → 50/50 energy ball or unreflectable blue ball → lightning. Each reflected hit deals 16 damage (6 hits to win).
- **Second encounter (Ganon's Tower):** 3 copies; 2 are fakes (lighter color). Only real Agahnim's balls can be reflected.

#### Helmasaur King (Palace of Darkness)
- **HP:** 48 (body); mask has separate 17 HP
- **Contact:** 2 hearts
- **Phase 1:** Mask absorbs all damage to the body. Destroy it with Hammer (1 damage per hit, 17 hits) or Bombs (4 damage per hit, 5 bombs).
- **Phase 2 (mask destroyed):** Body exposed. Faster movement, weak to all weapons.
- **Attacks:** 50% tail swipe, 50% fireball.

#### Arrghus (Swamp Palace)
- **HP:** 32 (main eye); 8 per puff
- **Contact:** 2 hearts
- **Phase 1:** Pull puffs away with Hookshot, then strike.
- **Phase 2:** Eye exposed, jumps and crashes down.

#### Mothula (Skull Woods)
- **HP:** 32
- **Contact:** 2 hearts
- **Environmental hazards:** Spike projectiles every 64 frames; conveyor floors change direction every 96–223 frames.
- **Vulnerability window:** 10 frames post-hit before 32-frame invulnerability (allows double hits).

#### Blind the Thief (Thieves' Town)
- **HP:** Effectively 9 hits (fixed 1 hit per strike regardless of weapon)
- **Contact:** 2 hearts
- **Phases:** 3 hits per phase × 3 phases. Each decapitation spawns a floating head that shoots fireballs.
- **Trigger:** Must expose Blind to sunlight (bomb hole in ceiling).

#### Kholdstare (Ice Palace)
- **HP:** 64 per eyeball × 3 eyeballs; Shell HP 64
- **Contact:** 4 hearts
- **Phase 1:** Encased in ice. Fire Rod required (8 shots to break shell). Ice blocks fall from ceiling every 128 frames.
- **Phase 2:** 3 eyeballs bounce at 45° angles, occasionally charge Link.

#### Vitreous (Misery Mire)
- **HP:** 128 (main eye); 48 per small eyeball
- **Contact:** 4 hearts (small eyes)
- **Phase 1:** Small eyes launch at Link; main eye shoots lightning.
- **Phase 2:** Main eye chases Link around room.

#### Trinexx (Turtle Rock)
- **HP:** 40 per head (fire, ice, main body)
- **Contact:** 4 hearts
- **Phase 1:** Fire head → use Ice Rod. Ice head → use Fire Rod. Both required items.
- **Phase 2:** Shell breaks, snake form chases Link. Spin attacks effective.

#### Ganon (Pyramid of Power)
- **HP:** 255 total
- **Contact:** 8 hearts (Green Mail)
- **Phase 1 (Trident):** Throws trident, teleports. 12 sword hits to advance.
- **Phase 2 (Firebats):** Spins trident, ring of firebats. 12 hits to advance.
- **Phase 3 (Teleport):** Alternates positions, spiral fire attacks. Each hit triggers floor stomp removing tiles. 4 stomps to advance.
- **Phase 4 (Final):** Torches must stay lit (Fire Rod). Only **Silver Arrows** deal real damage — 24 damage each, 4 arrows to kill.

### Mini-Bosses

| Mini-Boss | HP | Contact | Location |
|-----------|:--:|:-------:|----------|
| Ball & Chain Guard | 16 | 1 heart | Hyrule Castle, Agahnim's Tower |
| Stalfos Knight | 64 | 2 hearts | Ice Palace, Ganon's Tower |
| Hinox | 20 | 3 hearts | Dark World overworld, dungeons |

Stalfos Knights collapse when struck but reform; must bomb the pile to kill permanently. Ganon's Tower features rematches against Armos Knights, Lanmolas, and Moldorm with original stats.

---

## 7. Economy

### Rupees

| Color | Value |
|-------|:-----:|
| Green | 1 |
| Blue | 5 |
| Red | 20 |

Maximum wallet capacity: **999 Rupees** (no upgrades).

### Shops

**Light World:**

| Shop | Item | Price |
|------|------|------:|
| Kakariko General / Lake Hylia / Death Mountain | Red Potion | 150 |
| | 10 Bombs | 50 |
| | Heart (heal) | 10 |
| Witch's Hut | Red Potion | 120 |
| | Green Potion | 60 |
| | Blue Potion | 160 |
| King Zora | Flippers | 500 |
| Bottle Merchant | Empty Bottle | 100 |

**Dark World:**

| Shop | Item | Price |
|------|------|------:|
| General Shops (×3) | Red Potion | 150 |
| | Fighter's Shield (if lost) | 50 |
| | 10 Bombs | 50 |
| Specialty (near Pyramid) | Red Shield | 500 |
| | Bee in Bottle | 10 |
| | 10 Arrows | 30 |
| Bomb Shop (Link's House equiv.) | 30 Bombs | 100 |
| | Super Bomb | 100 |

Super Bomb available only after clearing Ice Palace and Misery Mire.

### Income Sources

- Dungeon/overworld chests (fixed Rupee amounts)
- Enemy drops (prize pack system — see [docs/zelda-lttp/enemies.md](docs/zelda-lttp/enemies.md) §Prize Packs)
- Grass/pots/bushes (small pickups)
- Minigames (§8)
- Hidden Rupee Men (2 NPCs each give 300 Rupees)
- Golden Bee trade (sell to Bottle Merchant for 100 Rupees, repeatable)

---

## 8. Minigames & Side Systems

### Minigames

| Game | Location | Cost | Mechanic | Special Reward |
|------|----------|-----:|----------|----------------|
| Treasure Chest Game | Village of Outcasts | 30 | Open 2 of 16 randomized chests | Heart Piece (hidden among chests) |
| Digging Game | South of Village of Outcasts | 80 | 30 seconds to dig with Shovel | Heart Piece (random location each game) |
| Shooting Gallery | Village of Outcasts | 20 | 5 arrows at moving targets | Up to 124 Rupees (doubles per consecutive hit) |
| 15-Second Race | Kakariko Village | 20 | Clear obstacle course under 15 seconds | Heart Piece |

### Collectibles & Tracking

No formal bestiary, collectible gallery, or completion percentage counter. Tracked progress is limited to Pendant/Crystal count (visible on map screen) and Heart Piece collection (implicit via life meter). Capacity upgrades are covered in §5 Upgrade Fountains.

---

## 9. UI & HUD

### Gameplay HUD

Top of screen, always visible:

| Element | Position | Details |
|---------|----------|---------|
| Equipped Y-item | Top-left | Shows currently assigned inventory item |
| Magic Meter | Left of item box | Vertical green bar; shows "1/2" after Mad Batter upgrade |
| Rupee count | Below item box | Preceded by Rupee icon; up to 999 |
| Bomb count | Below Rupees | Preceded by Bomb icon |
| Arrow count | Below Bombs | Preceded by Arrow icon |
| Life meter | Top-right | Up to 20 hearts in rows; "LIFE" label above; partial hearts for fractional damage |

No minimap on the gameplay HUD. Map is a separate screen (X button).

### Inventory Screen (Start)

- **Item grid:** All Y-button items in a grid layout. Navigate with D-Pad, highlight to assign to Y. Bottles share a slot with sub-selection.
- **Equipment panel (right side):** Current Sword, Shield, Mail, Gloves icons (informational, not selectable).
- **Passive items:** Pegasus Boots, Flippers, Moon Pearl shown when collected.
- **Pendant/Crystal tracker:** Progress indicator for collection status.

### Map Screen (X)

- **Overworld:** Full world map with Link's position marker. Shows Light World or Dark World depending on current location.
- **Dungeon:** Room layout (if Map collected), chest positions (if Compass collected), boss location (if Compass collected). Visited rooms highlighted.

---

## 10. Engine & Presentation Systems

### Save System

- **Manual save only.** Start → Select → "Save and Quit." No auto-save.
- **Saves persist:** All items, dungeon clears, Heart Pieces, capacity upgrades, world state.
- **Respawn points on continue/death:**
  - Light World: Link's House, Sanctuary, Mountain Cave (3 choices)
  - Dark World: Pyramid of Power (only option)
  - Inside dungeon: Dungeon entrance (progress preserved)

### Camera

Fixed top-down perspective. Camera scrolls with Link, screen-by-screen transitions at room/area boundaries (no smooth scrolling between screens in dungeons; overworld scrolls smoothly).

### Environmental Effects

- **Opening rain:** Visible rain sprites with darker palette during Hyrule Castle rescue sequence. Rain stops after delivering Zelda to Sanctuary.
- **Misery Mire rain:** Perpetual magical rain in the Misery Mire area. Ether Medallion on specific tile clears rain and reveals dungeon entrance.
- **Dark World palette:** Permanently altered — darker purples/browns, overcast sky, dead trees, darker water. Global tileset swap on world transition.
- **World transition effect:** Screen wipe/flash effect when warping between worlds.

### Dialogue System

Text boxes appear at bottom of screen. NPC dialogue is non-branching (no dialogue choices). Telepathic messages from Zelda/Sahasrahla appear with distinct visual treatment. Signs can be read.

### Audio System

- Overworld and Dark World each have distinct themes.
- Each dungeon has its own music track.
- Boss encounters trigger boss battle music.
- Indoor/cave areas have separate ambient tracks.
- Music transitions on area change (immediate cut, no crossfade).
- Low-health warning beep plays continuously when at 1 heart or below.
- Sound effects layer over music for sword slashes, item pickups, enemy hits, etc.

---

## 11. Open Questions / Unverified

- **Exact spin attack charge threshold:** Community consensus is ~30–40 frames. ROM disassembly references RAM $3C lower nibble as the frame counter, but the exact threshold value at the specific ROM address has not been pinpointed in available sources.
- **Poke attack damage classes:** Sources agree poke uses a lower class than slash, but the exact class assignments for L1/L2 poke vs L3/L4 poke vary slightly between sources.
- **Cane of Byrna sustained drain rate:** The initial cost (16) is well-documented. The ongoing drain rate is timer-based (every N frames), but the exact frame interval varies across sources (4 frames vs 24 frames cited).
- **Magic Cape drain tiers:** ROM address 0x3ADA7 contains three escalating values [0x04, 0x08, 0x10], suggesting the drain accelerates, but the trigger conditions for tier escalation are not clearly documented.
- **Some enemy HP values:** Most common enemies are well-documented from ROM data. A few obscure sprites (variant palette swaps, unused enemies) have conflicting or absent data.
- **Bump class 0x01 and 0x04 armor immunity:** These classes deal identical damage regardless of mail tier — confirmed in the bump table, but the design rationale is not documented.
- **Prize pack group assignments for all enemies:** Most are documented but a few rare/dungeon-specific sprites have uncertain pack assignments.

---

## 12. References

### Datamining & ROM Analysis
- [Spannerisms — Damage to Enemies in ALttP](https://spannerisms.github.io/damage/) — complete damage class/subclass system
- [Spannerisms — All Sprite Damage](https://spannerisms.github.io/alldamage/) — per-sprite damage values
- [ALttP Disassembly RAM Map (GitHub)](https://github.com/walkingeyerobot/alttp-disassembly) — RAM addresses and flags
- [Puzzledude's All-in-One Hex Info (Zeldix)](https://www.zeldix.net/t1215-puzzledude-s-all-in-one-hex-info) — ROM hex reference
- [Archipelago Randomizer ROM.py](https://github.com/ArchipelagoMW/Archipelago/blob/main/worlds/alttp/Rom.py) — magic costs, item data

### Speedrun Community
- [ALttP Speedrunning Wiki — Movement](https://alttp-wiki.net/index.php/Movement)
- [ALttP Speedrunning Wiki — Subpixels](https://alttp-wiki.net/index.php/Subpixels)
- [ALttP Speedrunning Wiki — Enemy Prize Packs](https://alttp-wiki.net/index.php/Enemy_prize_packs)
- [ALttP Speedrunning Wiki — Boss Pages](https://alttp-wiki.net/index.php/Bosses)
- [ALttP Speedrunning Wiki — Sprite Damage Tables](https://alttp-wiki.net/index.php/Module:Sprite_Damage/sprites_table)

### Wikis & Guides
- [Zelda Wiki (zeldawiki.wiki)](https://zeldawiki.wiki/wiki/The_Legend_of_Zelda:_A_Link_to_the_Past)
- [Zelda Dungeon Wiki](https://www.zeldadungeon.net/wiki/A_Link_to_the_Past)
- [StrategyWiki](https://strategywiki.org/wiki/The_Legend_of_Zelda:_A_Link_to_the_Past)
- [GameFAQs — Monster/Attack Stats Guide (assassin17)](https://gamefaqs.gamespot.com/snes/588436-the-legend-of-zelda-a-link-to-the-past/faqs/39556)
- [GameFAQs — Secrets & Mini-games Guide](https://gamefaqs.gamespot.com/snes/588436-the-legend-of-zelda-a-link-to-the-past/faqs/77032)

### Design Analysis
- [Game Developer — Enemy Design in Link to the Past](https://www.gamedeveloper.com/design/enemy-design-in-link-to-the-past)

### Companion Documents
- [docs/zelda-lttp/enemies.md](docs/zelda-lttp/enemies.md) — full enemy tables, damage class system, bump damage table, prize pack system
