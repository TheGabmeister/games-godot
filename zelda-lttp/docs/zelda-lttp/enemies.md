# A Link to the Past — Enemy & Damage Data

Companion to [SPEC.md](../../SPEC.md) §6.

---

## Damage Class System

ALttP uses a **damage class / subclass lookup table**. There are 16 damage classes (one per weapon type) and 8 subclasses (assigned per enemy sprite). The (class, subclass) pair indexes into a ROM table yielding the final damage value or special effect.

### Damage Classes by Weapon

| Class | Weapon |
|-------|--------|
| 0x0 | Boomerang |
| 0x1 | Sword L1 (Fighter's Sword) |
| 0x2 | Sword L2 (Master Sword) / Spin L1 |
| 0x3 | Sword L3 (Tempered Sword) / Spin L2 |
| 0x4 | Sword L4 (Golden Sword) / Spin L3 |
| 0x5 | Spin L4 |
| 0x6 | Arrow |
| 0x7 | Hookshot |
| 0x8 | Bomb |
| 0x9 | Silver Arrow |
| 0xA | Magic Powder |
| 0xB | Fire Rod |
| 0xC | Ice Rod |
| 0xD | Bombos Medallion |
| 0xE | Ether Medallion |
| 0xF | Quake Medallion |

### Full Damage Value Table (ROM Data)

| Class | Weapon | Sub0 | Sub1 | Sub2 | Sub3 | Sub4 | Sub5 | Sub6 | Sub7 |
|-------|--------|------|------|------|------|------|------|------|------|
| 0x0 | Boomerang | 0 | 1 | 32 | Stun-255 | Stun-128 | Stun-32 | 0 | 0 |
| 0x1 | Sword L1 | 0 | 2 | 64 | 4 | 0 | 0 | 0 | 0 |
| 0x2 | Sword L2 / Spin L1 | 0 | 4 | 64 | 2 | 3 | 0 | 0 | 0 |
| 0x3 | Sword L3 / Spin L2 | 0 | 8 | 64 | 4 | 0 | 0 | 0 | 0 |
| 0x4 | Sword L4 / Spin L3 | 0 | 16 | 64 | 8 | 0 | 0 | 0 | 0 |
| 0x5 | Spin L4 | 0 | 16 | 64 | 8 | 0 | 0 | 0 | 0 |
| 0x6 | Arrow | 0 | 4 | 64 | 16 | 0 | 0 | 0 | 0 |
| 0x7 | Hookshot | 0 | Stun-255 | 64 | Stun-255 | Stun-128 | Stun-32 | 0 | 0 |
| 0x8 | Bomb | 0 | 4 | 64 | Stun-255 | Stun-128 | Stun-32 | 32 | 0 |
| 0x9 | Silver Arrow | 0 | 100 | 24 | 100 | 0 | 0 | 0 | 0 |
| 0xA | Magic Powder | 0 | Faerie | Blob | Stun-255 | 100 | 0 | 0 | 0 |
| 0xB | Fire Rod | 0 | 8 | 64 | Burn | 4 | 16 | 0 | 0 |
| 0xC | Ice Rod | 0 | 8 | 64 | Freeze | 4 | 0 | 0 | 0 |
| 0xD | Bombos | 0 | 16 | 64 | Burn | 0 | 0 | 0 | 0 |
| 0xE | Ether | 0 | Freeze | 64 | 16 | 0 | 0 | 0 | 0 |
| 0xF | Quake | 0 | 32 | 64 | Stun-255 | 0 | 0 | 0 | Blob |

### Special Effect Codes

| Code | Effect |
|------|--------|
| $F9 | Target becomes a Faerie |
| $FA | Target becomes a Blob/Slime |
| $FB | Stun 32 frames |
| $FC | Stun 128 frames |
| $FD | Incineration (instant kill) |
| $FE | Frozen |
| $FF | Stun 255 frames |
| $00 | No damage / immune |

---

## Bump Damage Table (Contact Damage to Link)

Each enemy has a bump class (0x00–0x09). The three armor tiers modify incoming damage independently per class.

Internal units: 0x08 = 1 full heart.

| Bump Class | Green Mail | Blue Mail | Red Mail |
|------------|------------|-----------|----------|
| 0x00 | 0x02 (1/4 heart) | 0x01 (1/8 heart) | 0x01 (1/8 heart) |
| 0x01 | 0x04 (1/2 heart) | 0x04 (1/2 heart) | 0x04 (1/2 heart) |
| 0x02 | 0x00 (none) | 0x00 (none) | 0x00 (none) |
| 0x03 | 0x08 (1 heart) | 0x04 (1/2 heart) | 0x02 (1/4 heart) |
| 0x04 | 0x08 (1 heart) | 0x08 (1 heart) | 0x08 (1 heart) |
| 0x05 | 0x10 (2 hearts) | 0x08 (1 heart) | 0x04 (1/2 heart) |
| 0x06 | 0x20 (4 hearts) | 0x10 (2 hearts) | 0x08 (1 heart) |
| 0x07 | 0x20 (4 hearts) | 0x18 (3 hearts) | 0x10 (2 hearts) |
| 0x08 | 0x18 (3 hearts) | 0x10 (2 hearts) | 0x08 (1 heart) |
| 0x09 | 0x40 (8 hearts) | 0x30 (6 hearts) | 0x18 (3 hearts) |

Bump classes 0x01 and 0x04 are **not reduced** by armor upgrades.

---

## Light World — Overworld Enemies

| Enemy | Sprite | HP | Bump | Dmg (Green) | Locations |
|-------|--------|---:|------|-------------|-----------|
| Green Sword Soldier | 0x42 | 4 | 0x01 | 1/2 heart | Hyrule Castle, Kakariko |
| Blue Sword Soldier | 0x41 | 6 | 0x01 | 1/2 heart | Hyrule Castle grounds |
| Green Spear Soldier | 0x45 | 4 | 0x03 | 1 heart | Castle surroundings |
| Red Spear Soldier | 0x43 | 8 | 0x03 | 1 heart | Castle, post-Agahnim |
| Red Javelin Soldier | 0x48 | 8 | 0x03 | 1 heart | Castle towers |
| Red Bomb Soldier | 0x4A | 8 | 0x03 | 1 heart | Castle grounds |
| Green Recruit | 0x4B | 4 | 0x01 | 1/2 heart | Kakariko area |
| Assault Sword Soldier | 0x44 | 6 | 0x01 | 1/2 heart | Castle pursuit |
| Blue Archer | 0x46 | 6 | 0x01 | 1/2 heart | Castle walls |
| Green Archer | 0x47 | 4 | 0x01 | 1/2 heart | Castle walls |
| Octorok (1-way) | 0x08 | 2 | 0x01 | 1/2 heart | Overworld fields |
| Octorok (4-way) | 0x0A | 2 | 0x01 | 1/2 heart | Overworld fields |
| Crow / Raven | 0x00 | 4 | 0x03 | 1 heart | Trees, overworld |
| Vulture | 0x01 | 6 | 0x03 | 1 heart | Desert of Mystery |
| Buzzblob | 0x0D | 3 | 0x01 | 1/2 heart | Overworld grass |
| Armos Statue | 0x51 | 8 | 0x01 | 1/2 heart | Eastern Palace area |
| Leever | 0x71 | 4 | 0x01 | 1/2 heart | Desert |
| Geldman | 0x4C | 4 | 0x03 | 1 heart | Desert |
| Devalant | 0x64 | 4 | 0x03 | 1 heart | Desert |
| Tektite | 0xC9 | 4 | 0x05 | 2 hearts | Death Mountain |
| Lynel | 0xD0 | 24 | 0x06 | 4 hearts | Death Mountain |
| Poe | 0x19 | 8 | 0x05 | 2 hearts | Graveyard |
| Zora (fireball) | 0x55 | 8 | 0x01 | 1/2 heart | Waterways |
| Zora (walking) | 0x56 | 8 | 0x01 | 1/2 heart | Waterways |
| Rope (snake) | 0x6E | 4 | 0x01 | 1/2 heart | Caves, dungeons |
| Bee | 0x79 | 0 | 0x00 | 1/4 heart | Trees, bushes |

## Light World — Dungeon Enemies

| Enemy | Sprite | HP | Bump | Dmg (Green) | Locations |
|-------|--------|---:|------|-------------|-----------|
| Rat | 0x6D | 2 | 0x00 | 1/4 heart | Hyrule Castle Sewers |
| Keese (bat) | 0x6F | 1 | 0x00 | 1/4 heart | Sewers, caves, dungeons |
| Popo | 0x4E | 2 | 0x01 | 1/2 heart | Eastern Palace |
| Stalfos | 0xA7 | 4 | 0x01 | 1/2 heart | Eastern Palace, caves |
| Green Eyegore | 0x83 | 16 | 0x04 | 1 heart | Eastern Palace |
| Red Eyegore | 0x84 | 8 | 0x04 | 1 heart | Eastern Palace |
| Mini Moldorm | 0x18 | 3 | 0x03 | 1 heart | Tower of Hera |
| Hardhat Beetle (blue) | 0x26 | 6 | 0x05 | 2 hearts | Tower of Hera |
| Fire Snake | 0x80 | 3 | 0x04 | 1 heart | Tower of Hera, Ganon's Tower |

## Dark World — Overworld Enemies

| Enemy | Sprite | HP | Bump | Dmg (Green) | Locations |
|-------|--------|---:|------|-------------|-----------|
| Snapdragon | 0x0E | 12 | 0x08 | 3 hearts | Dark World overworld |
| Hinox | 0x11 | 20 | 0x08 | 3 hearts | Dark World overworld |
| Moblin | 0x12 | 4 | 0x05 | 2 hearts | Dark World forest |
| Mini Helmasaur | 0x13 | 4 | 0x03 | 1 heart | Dark World overworld |
| Ropa | 0x22 | 8 | 0x05 | 2 hearts | Dark World overworld |
| Pikit | 0xAA | 12 | 0x05 | 2 hearts | Dark World (steals items) |
| Stal | 0xD3 | 4 | 0x03 | 1 heart | Dark World |
| Hover | 0x81 | 4 | 0x03 | 1 heart | Dark World overworld |
| Zirro (blue) | 0xA8 | 4 | 0x05 | 2 hearts | Dark World sky |
| Zirro (red) | 0xA9 | 8 | 0x03 | 1 heart | Dark World sky |
| Crab | 0x58 | 2 | 0x05 | 2 hearts | Dark World water |
| Swimmers | 0x94 | 2 | 0x05 | 2 hearts | Dark World water |

## Dark World — Dungeon Enemies

| Enemy | Sprite | HP | Bump | Dmg (Green) | Locations |
|-------|--------|---:|------|-------------|-----------|
| Red Bari | 0x23 | 2 | 0x03 | 1 heart | Swamp Palace |
| Blue Bari | 0x24 | 2 | 0x01 | 1/2 heart | Swamp Palace |
| Terrorpin | 0x8E | 8 | 0x03 | 1 heart | Turtle Rock |
| Gibdo | 0x8B | 32 | 0x05 | 2 hearts | Skull Woods |
| Sluggula | 0x20 | 8 | 0x06 | 4 hearts | Skull Woods |
| Stalfos Knight | 0x91 | 64 | 0x05 | 2 hearts | Ice Palace, Ganon's Tower |
| Pengator | 0x99 | 16 | 0x05 | 2 hearts | Ice Palace |
| Freezor | 0xA1 | 16 | 0x06 | 4 hearts | Ice Palace |
| Wizzrobe | 0x9B | 2 | 0x06 | 4 hearts | Misery Mire |
| Blue Zazak | 0xA5 | 4 | 0x05 | 2 hearts | Dark dungeons |
| Red Zazak | 0xA6 | 8 | 0x05 | 2 hearts | Dark dungeons |
| Pokey | 0xC7 | 32 | 0x06 | 4 hearts | Misery Mire |
| Gibo | 0xC3 | 8 | 0x03 | 1 heart | Misery Mire |
| Slime | 0x8F | 4 | 0x05 | 2 hearts | Swamp Palace |
| Wallmaster | 0x90 | 8 | N/A | Grabs (warps to entrance) | Skull Woods |
| Kodongo | 0x86 | Invuln | 0x04 | 1 heart | Dark dungeons |
| Yellow Stalfos | 0x85 | 8 | 0x01 | 1/2 heart | Dark dungeons |
| Red Hardhat Beetle | 0x26 | 32 | 0x03 | 1 heart | Turtle Rock |
| Kyameron | 0x9A | 4 | 0x03 | 1 heart | Swamp Palace |
| Deadrock | 0x27 | 255 | 0x03 | 1 heart | Dark Mountain, dungeons |
| Floating Stalfos Head | 0x7C | 24 | 0x06 | 4 hearts | Dark dungeons |
| Swamola | 0xCF | 16 | 0x07 | 4 hearts | Swamp Palace |
| Chain Chomp | 0xCA | 5 | 0x07 | 4 hearts | Turtle Rock |

## Invulnerable Hazards

Spark, Roller, Beamos, Big Spike Trap, Guruguru Bar, Anti-Fairies, Boulders, Cannon Balls, Eye Lasers — all deal fixed contact damage based on bump class but cannot be destroyed.

---

## Enemy Drop System (Prize Packs)

Each enemy belongs to a prize pack group (0–7). Each group has a kill counter that cycles through a fixed 8-item sequence. When an enemy from that group is killed, the counter advances.

| Pack | Drop Rate | Sequence |
|------|-----------|----------|
| 0 | 0% | Nothing (Keese, Freezor, Bee, Wallmaster, etc.) |
| 1 | 50% | Heart, Heart, Heart, Heart, Green Rupee, Heart, Heart, Green Rupee |
| 2 | 50% | Blue Rupee, Green Rupee, Blue Rupee, Red Rupee, Blue Rupee, Green Rupee, Blue Rupee, Red Rupee |
| 3 | 50% | Big Magic, Small Magic, Small Magic, Blue Rupee, Big Magic, Small Magic, Heart, Small Magic |
| 4 | 100% | 1 Bomb, 1 Bomb, 1 Bomb, 4 Bombs, 1 Bomb, 1 Bomb, 8 Bombs, 1 Bomb |
| 5 | 50% | 5 Arrows, Heart, 5 Arrows, 10 Arrows, 5 Arrows, Heart, 5 Arrows, 10 Arrows |
| 6 | 50% | Small Magic, Green Rupee, Heart, 5 Arrows, Small Magic, 1 Bomb, Green Rupee, Heart |
| 7 | 50% | Heart, Fairy, Big Magic, Red Rupee, 8 Bombs, Heart, Red Rupee, 10 Arrows |

### Special Drop Rules

- Key-designated enemies always drop keys instead of prize pack items.
- Stunned enemies killed while stunned always drop a Green Rupee.
- Frozen enemies killed with Hammer always drop magic (100% rate).
- Dash kills (Pegasus Boots) force 0% drop rate.
- Pond of Happiness luck modifies random prize drop chances.
