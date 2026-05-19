# Final Fantasy I Pixel Remaster — Gameplay Systems Spec

Final Fantasy I Pixel Remaster. Originally NES (1987), Pixel Remaster released 2021 (Steam/Mobile), 2023 (PS4/Switch). This spec targets the Pixel Remaster version.

---

## 1. Core Gameplay Systems

### 1.1 Primary Gameplay Loop

1. **Town phase** — buy equipment, spells, and consumables; rest at an inn to restore HP and spell charges; talk to NPCs for story progression
2. **Overworld travel** — walk or sail between towns and dungeons; random encounters occur every ~20–30 steps
3. **Dungeon exploration** — navigate multi-floor dungeons, open treasure chests, encounter random battles
4. **Boss encounter** — story-gated boss at dungeon end; defeating it advances the narrative and unlocks new areas
5. **Repeat** with stronger gear and higher-level spells

### 1.2 Combat System

Turn-based, party-vs-group. Four player characters face one or more groups of enemies (up to 9 enemies on screen).

**Turn structure:**
1. Player inputs commands for all 4 characters at round start
2. Turn order resolves based on Agility; ties broken randomly
3. Each unit acts once per round (Haste doubles a character's number of attacks, not extra turns)
4. If a targeted enemy dies before the attacker acts, the attack retargets automatically (Pixel Remaster fix from NES behavior where the attack would whiff)
5. Round ends when all units have acted; repeat

**Available commands:**
- **Attack** — physical attack with equipped weapon (or bare fists)
- **Magic** — cast a spell from the character's learned spell list; consumes one charge of that spell's level
- **Item** — use a consumable (Potion, Ether, Phoenix Down, etc.)
- **Run** — attempt to flee; success based on party Luck vs. enemy Agility; cannot run from bosses

### 1.3 Physical Damage Formula

**Damage per hit:**
```
Damage = random(AttackPower .. AttackPower × 2) − target's Absorb
Minimum damage per hit = 1
```

**AttackPower (player):**
```
AttackPower = Strength / 2 + WeaponDamage
```
Monk/Master unarmed damage uses a different formula — see §4.4.

**Number of hits:**
```
MaxHits = floor(Hit% / 32) + 1
```
Warriors and Monks gain +3 Hit% per level (~1 extra hit every 11 levels). Other classes gain +1 Hit% per level.

**Hit probability (per hit):**
```
BaseChance = 168 (out of 200, ~84%)
HitChance = BaseChance + AttackerHit% − DefenderEvade%
```
- Blindness on attacker: −40 to HitChance
- Blindness on defender: +40 to HitChance

**Critical hits:**
```
CritRate = WeaponIndex  (for armed attacks)
CritRate = Level × 2     (for Monk/Master unarmed)
CritRate = 0              (for other classes unarmed)
```
Critical hits ignore the target's Absorb — full random damage applies. The crit check shares the same roll as the hit check: if a character's hit rate is low, successful hits are more likely to be crits.

**Buff stacking:**
Temper (+14 ATK) and Saber (+16 ATK, +accuracy) stack with each other and can be cast multiple times on the same target. This is the primary way to push physical damage in boss fights.

### 1.4 Magic Damage Formula

```
Damage = random(SpellPower .. SpellPower × 2)
```
- On a "miss" (spell doesn't fully connect), damage is halved
- Elemental weakness: +50% damage, +20% hit chance
- Elemental resistance: damage halved
- Spell hit chance = SpellAccuracy − target's MagicDefense

**Elemental damage spell progression:**

| Spell | Level | Element | Power | Target |
|-------|-------|---------|-------|--------|
| Fire | 1 | Fire | 10–40 | One |
| Thunder | 1 | Lightning | 10–40 | One |
| Blizzard | 2 | Ice | 20–80 | One |
| Fira | 3 | Fire | 30–120 | All |
| Thundara | 3 | Lightning | 30–120 | All |
| Blizzara | 4 | Ice | 40–160 | All |
| Firaga | 5 | Fire | 50–200 | All |
| Thundaga | 6 | Lightning | 60–240 | All |
| Blizzaga | 7 | Ice | 70–280 | All |
| Holy | 8 | — | ~80 power | All |
| Flare | 8 | Non-elemental | ~100 power | All |

**Dia line** (White Magic, undead-only): Dia 20–80 / Diara 40–160 / Diaga 60–240 / Diaja 80–320, all target all undead enemies.

### 1.5 Defense and Evasion

**Absorb (physical defense):**
```
Absorb = sum of all equipped armor Absorb values
```
Each piece of armor adds to Absorb but penalizes Evade%. Monk/Master unarmed Absorb uses a separate formula — see §4.4.

**Evade%:**
```
Evade% = 48 + Agility − sum of equipped armor evasion penalties
```
Spells like Blink (+80), Invis (+40), and Invisira (+40 all) add directly to Evade%.

### 1.6 Elemental System

Eight elements in the Pixel Remaster:

| Element | Offensive spells | Defensive spells |
|---------|-----------------|-----------------|
| Fire | Fire, Fira, Firaga | NulBlaze (halves Fire) |
| Ice | Blizzard, Blizzara, Blizzaga | NulFrost (halves Ice) |
| Lightning | Thunder, Thundara, Thundaga | NulShock (halves Lightning) |
| Earth | Quake | — |
| Poison | Scourge | — |
| Time | Slow, Haste, Stop | — |
| Death | Death, Kill, Break, Banish | NulDeath (blocks instant death) |
| Status | Sleep, Silence, Confuse, Hold, Stun | — |

Weapons can carry elemental properties (e.g., Flame Sword = Fire, Ice Brand = Ice). Armor can resist one or more elements. In the Pixel Remaster, weapon elemental properties function correctly (unlike the NES original where they were bugged).

### 1.7 Status Effects

| Status | Effect | Cure | Persists after battle? |
|--------|--------|------|----------------------|
| KO | Character cannot act; party wipe = Game Over | Life, Full-Life, Phoenix Down | Yes |
| Stone | Character cannot act; counts as KO for party wipe | Stona, Gold Needle | Yes |
| Poison | Lose HP each turn; lose 1 HP per step on field | Poisona, Antidote | Yes |
| Darkness | Hit rate reduced by 40 | Blindna, Eye Drops | Yes |
| Silence | Cannot cast magic | Vox, Echo Grass | Yes |
| Sleep | Cannot act; woken by physical damage | Ends after a few turns or on hit | No |
| Paralysis | Cannot act | Ends after a few turns | No |
| Confusion | Attacks random targets including allies | Ends after a few turns or on hit | No |

**Ribbon** prevents all status effects. Equipped in the helm slot.

### 1.8 Progression Systems

**Experience and leveling:**
- Level cap: 99
- After battle, all surviving party members receive an equal share of total EXP; KO'd members receive nothing
- Gil is awarded in full (not split)
- Each level grants stat increases based on current class — see §4 for growth details

**Game Over:**
If all four party members are KO'd or Stoned, the game ends. The player returns to the title screen and must reload from the last save (inn save, Quick Save, or autosave).

**Party formation:**
Party order (set via the Formation menu) affects targeting priority. Characters in position 1–2 are targeted more often by enemy physical attacks. Back positions (3–4) are hit less frequently. This makes it important to place high-HP classes (Warrior, Monk) in front.

### 1.9 Magic / Spell Charge System

Magic uses a **Vancian charge system** (borrowed from D&D). Spells are organized into 8 levels with 4 spells per level. Each spell level has a separate charge pool.

**Charges:**
- Characters start with ~2–3 charges for their lowest available spell level
- Maximum charges per spell level: **9** (reached around level 50 for dedicated casters)
- Charges increase at fixed level thresholds as the character levels up

**Learning spells:**
- Spells are purchased from magic shops in towns
- Each class can learn **3 spells per spell level** (shops sell 4 per level, so one must be skipped)
- Once learned, a spell is permanent

Class spell access levels are listed in §4.1 and §4.2.

**Charge restoration:**
- Inn: full HP + all spell charges restored (costs Gil)
- Tent: partial HP restored, some charges restored (world map / save point only)
- Cottage: full HP + all charges restored (world map / save point only)
- Ether: restores a fixed number of charges across all spell levels (consumable)

---

## 2. Controls & Input

### 2.1 Control Scheme (Gamepad)

| Input | Field | Battle | Menu |
|-------|-------|--------|------|
| D-pad / Left stick | Move character (8 directions including diagonals) | Navigate command menu | Navigate menus |
| A / Confirm | Talk / Interact / Examine | Confirm selection | Confirm |
| B / Cancel | Cancel / Close menu | Cancel / Back | Back |
| Start | Open main menu | — | — |
| Select | Toggle minimap | — | — |
| L/R | — | — | Page through equipment/spells |

Diagonal movement is supported (Pixel Remaster addition over the NES original).

### 2.2 Boost Options (Pixel Remaster)

Accessible from the Config / Boost menu at any time:

- **EXP multiplier**: ×1 to ×4
- **Gil multiplier**: ×1 to ×4
- **Encounter toggle**: random encounters on/off
- **Auto-battle**: repeats previous round's commands
- **Battle speed**: adjustable

Presentation options (font, soundtrack) are covered in §11.

---

## 3. World Structure

### 3.1 World Layout

The overworld is a single continuous map with ocean, land, rivers, and mountains. Travel modes unlock progressively:

| Mode | Unlocked by | Traversal |
|------|------------|-----------|
| Walking | Start of game | Land only |
| Ship | Defeat Bikke's pirates in Pravoka | Ocean travel; dock at ports |
| Canoe | Obtained from Sage in Crescent Lake | Rivers and lakes |
| Airship | Use Levistone at desert south of Crescent Lake | Fly anywhere; land on grass |

### 3.2 Towns

| Town | Region | Key services | Spell levels sold |
|------|--------|-------------|------------------|
| Cornelia | Starting area | Inn, weapon/armor/item/magic shops | Lv 1 |
| Pravoka | Northeast coast | Inn, weapon/armor/item/magic shops | Lv 2 |
| Elfheim | Southern forest | Inn, weapon/armor/item/magic shops | Lv 3–4 |
| Melmond | Western continent | Inn, weapon/armor/item/magic shops | Lv 5 (partial) |
| Crescent Lake | Southern continent | Inn, weapon/armor/item/magic shops | Lv 5–6 |
| Onrac | Northeast continent | Inn, item/magic shops | Lv 7 |
| Gaia | Far northeast | Inn, item/magic/weapon shops | Lv 7–8 |
| Lufenia | Ancient floating continent | Magic shop | Lv 8 |

All item shops in the Pixel Remaster stock a standard set of consumables regardless of town: Potion, Hi-Potion, Ether, Phoenix Down, Antidote, Eye Drops, Echo Grass, Gold Needle, Remedy, Sleeping Bag, Tent, Cottage.

### 3.3 Dungeons (Progression Order)

| # | Dungeon | Boss(es) | Progression gate | Rec. Lv |
|---|---------|----------|-----------------|---------|
| 1 | Chaos Shrine | Garland | Rescues Princess Sarah | 1–3 |
| 2 | Pravoka (town event) | Bikke's Pirates | Unlocks Ship | 3–5 |
| 3 | Marsh Cave | Piscodemons | Obtain Crown | 6–8 |
| 4 | Western Keep | Astos | Crystal Eye → Jolt Tonic → Mystic Key | 8–10 |
| 5 | Terra Cavern | Vampire, Lich | Earth Crystal | 12–16 |
| 6 | Mt. Gulg | Marilith | Fire Crystal | 16–20 |
| 7 | Ice Cavern | Evil Eye | Obtain Levistone → Airship | 18–22 |
| 8 | Citadel of Trials | Dragon Zombie | Obtain Rat's Tail → Class Change | 20–24 |
| 9 | Waterfall Cavern | — | Obtain Warp Cube | 22–25 |
| 10 | Sunken Shrine | Kraken | Water Crystal | 24–28 |
| 11 | Tower of Mirage / Flying Fortress | Blue Dragon, Warmech, Tiamat | Wind Crystal | 28–32 |
| 12 | Chaos Shrine (Past) | Four Fiends (rematch), Chaos | Final dungeon | 35–50 |

Boss stats (HP, weaknesses, abilities) are in §7.4.

### 3.4 Progression Gating

The game uses **key items** (§3.5) and **vehicles** to gate progression. The first half is strictly linear; after obtaining the airship (dungeon 7), the player can tackle the remaining content in any order, though party level strongly suggests a natural path.

All dungeons remain accessible after completion — nothing is missable.

### 3.5 Key Items

| Item | Obtained | Used for |
|------|----------|----------|
| Lute | Princess Sarah after rescuing her | Opens the final passage in the Chaos Shrine (Past) |
| Crown | Marsh Cave treasure | Trade to Astos (who attacks) |
| Crystal Eye | Defeat Astos | Give to Matoya |
| Jolt Tonic | Matoya (in exchange for Crystal Eye) | Wake the Elf Prince |
| Mystic Key | Elf Prince (after waking) | Opens sealed doors throughout the world |
| Nitro Powder | Cornelia Castle (Mystic Key door) | Give to Nerrick the Dwarf to open canal |
| Star Ruby | Terra Cavern | Give to Titan to pass through cave |
| Earth Rod | Sage Sadda in Melmond | Breaks the stone plate in Terra Cavern to reach Lich |
| Canoe | Sage Lukahn in Crescent Lake | Travel on rivers and lakes |
| Levistone | Ice Cavern treasure | Raise the Airship from the desert |
| Rat's Tail | Citadel of Trials treasure | Give to Bahamut for class change |
| Bottled Faerie | Gaia (hidden spring) | Give to oasis trader for Oxyale |
| Oxyale | Trade Bottled Faerie | Breathe underwater in Sunken Shrine |
| Rosetta Stone | Sunken Shrine treasure | Give to Dr. Unne in Melmond to learn Lufenian |
| Warp Cube | Waterfall Cavern treasure | Teleport from Tower of Mirage to Flying Fortress |
| Chime | Lufenia (after learning language) | Enter the Tower of Mirage |
| Adamantite | Flying Fortress treasure | Give to Smith in Mt. Duergar for Excalibur |

---

## 4. Playable Characters / Classes

The player creates a party of 4 characters at game start, choosing from 6 classes. Each class promotes to an advanced form via Bahamut after obtaining the Rat's Tail (§3.5).

### 4.1 Base Classes

| Class | HP (Lv1) | STR | AGI | VIT | INT | LCK | Equipment | Magic |
|-------|----------|-----|-----|-----|-----|-----|-----------|-------|
| Warrior | 35 | 10 | 8 | 15 | 1 | 8 | Swords, axes, hammers, heavy armor, shields | None |
| Monk | 33 | 12 | 5 | 10 | 1 | 5 | Nunchaku, light armor | None |
| Thief | 30 | 5 | 15 | 5 | 1 | 15 | Daggers, light swords, light armor | None |
| Red Mage | 30 | 5 | 10 | 5 | 10 | 5 | Swords, medium armor | White 1–5, Black 1–5 |
| White Mage | 33 | 5 | 5 | 8 | 15 | 5 | Staves, hammers, robes | White 1–7 |
| Black Mage | 25 | 3 | 5 | 2 | 20 | 10 | Staves, daggers, robes | Black 1–7 |

### 4.2 Promoted Classes

| Base → Promoted | New capabilities | Notable stats (Lv99) |
|----------------|-----------------|---------------------|
| Warrior → **Knight** | Gains White Magic Lv 1–3 (Cure, Protect, Blink) | HP 62, STR 59, AGI 43 |
| Monk → **Master** | Magic evasion roughly doubles; unarmed damage spikes | HP 53, STR 36, AGI 30 |
| Thief → **Ninja** | Gains Black Magic Lv 1–4 (including Haste); equips almost everything | HP 48, STR 38, AGI 47 |
| Red Mage → **Red Wizard** | White and Black Lv 1–7 (locked out of Lv 8) | HP 43, STR 30, AGI 27 |
| White Mage → **White Wizard** | White Lv 1–8 (Holy, Full-Life, NulAll, Dispel) | HP 48, STR 23, AGI 22 |
| Black Mage → **Black Wizard** | Black Lv 1–8 (Flare, Stop, Kill, Warp) | HP 37, STR 15, AGI 18 |

### 4.3 Stat Growth (Pixel Remaster)

In the Pixel Remaster, stat growth is **deterministic** — stats are a function of current level and current class only. A level 20 Knight who leveled as a Warrior has identical stats to one who leveled as any other class. This eliminates the NES version's random stat-up system.

Each level grants guaranteed increases to:
- **Hit%** — Warriors/Monks: +3/level; others: +1/level
- **Magic Defense** — fixed per-class schedule
- **STR, AGI, VIT, INT, LCK** — increase at fixed per-class level thresholds

**Intelligence** actually functions in the Pixel Remaster (it was broken and had no effect in the NES original). This means dedicated casters (Black Wizard, White Wizard) scale noticeably harder than Red Wizard in the late game.

### 4.4 Monk/Master Unarmed Scaling

| Metric | Formula |
|--------|---------|
| Unarmed AttackPower | Level × 2 |
| Unarmed Absorb (no armor) | Level |
| Unarmed Accuracy | 80% base |
| Unarmed Critical Rate | Level × 2 |

Monks surpass all available weapons by approximately level 17 and should fight unarmed from that point. They must have both hands empty (no single-weapon equip). At high levels, Monks/Masters deal the highest raw physical damage in the game.

---

## 5. Story & Progression

### 5.1 Main Story Structure

The story is divided into three acts:

**Act 1 — The Prophecy (Cornelia → Earth Crystal)**
The four Warriors of Light arrive in Cornelia. They rescue Princess Sarah from Garland at the Chaos Shrine, cross the newly built bridge north, and journey through Pravoka, Elfheim, and the Western Keep. They collect key items through a chain of trades (Crown → Crystal Eye → Jolt Tonic → Mystic Key), then delve into the Terra Cavern to defeat Lich and restore the Earth Crystal.

**Act 2 — The Four Crystals (Mt. Gulg → Flying Fortress)**
The Warriors restore the remaining three crystals:
- Fire Crystal — defeat Marilith in Mt. Gulg
- Water Crystal — defeat Kraken in the Sunken Shrine
- Wind Crystal — defeat Tiamat in the Flying Fortress

Along the way they obtain the Canoe, Airship, and class upgrades from Bahamut. The Airship opens the world for non-linear exploration.

**Act 3 — The Time Loop (Chaos Shrine Past)**
With all four crystals restored, the Warriors use the Lute to open a portal in the Chaos Shrine. They travel 2,000 years into the past, fight upgraded versions of all four Fiends, and confront Chaos — Garland transformed by the Fiends' power into an immortal time loop. Defeating Chaos breaks the loop and restores peace.

### 5.2 Side Content

- **Citadel of Trials** — optional dungeon for class change (but effectively required)
- **Waterfall Cavern** — houses the Warp Cube; Defender sword as bonus loot
- **Adamantite → Excalibur** — optional trade quest in Mt. Duergar / Flying Fortress
- **Warmech** — 1% encounter rate on the bridge before Tiamat; 32,000 EXP reward, functions as a hidden superboss

### 5.3 No New Game+ or Post-Game

The Pixel Remaster has no New Game+ mode and no post-game content. The GBA-era bonus dungeons (Earthgift Shrine, Hellfire Chasm, Lifespring Grotto, Whisperwind Cove) were **removed** in the Pixel Remaster.

---

## 6. Items & Equipment

### 6.1 Equipment Slots

Each character has 5 equipment slots:
1. **Weapon** (right hand)
2. **Shield** (left hand)
3. **Body armor**
4. **Head armor** (helmets, Ribbon)
5. **Arm armor** (gloves/gauntlets, Protect Ring)

Monks cannot equip shields. Mages have very limited armor options — mostly robes, armlets, and caps.

### 6.2 Weapons

See companion doc: [docs/ff1/weapons.md](docs/ff1/weapons.md)

**Summary by category:**

| Category | Count | Damage range | Key classes |
|----------|-------|-------------|-------------|
| Swords | 21 | 7–56 | Warrior/Knight, Thief/Ninja, Red Mage |
| Daggers | 4 | 5–22 | All physical classes, Black Mage |
| Axes | 4 | 16–28 | Warrior/Knight, Ninja |
| Hammers | 3 | 9–18 | Warrior/Knight, White Mage, Ninja |
| Nunchaku | 2 | 12–16 | Monk/Master, Ninja |
| Staves | 6 | 6–15 | Various; Staff equippable by all |

**Notable weapons:**
- **Masamune** (56 ATK, 50 Hit%) — strongest weapon; equippable by all classes; found in Chaos Shrine (Past)
- **Excalibur** (45 ATK, 35 Hit%) — Knight-only; crafted from Adamantite; strong vs. all monsters
- **Sasuke** (33 ATK, 35 Hit%) — Ninja-only; found in Flying Fortress

**Special weapon properties:**
- Elemental damage (Flame Sword, Ice Brand, Coral Sword)
- Racial bonus ("Strong vs." Dragon, Undead, Were, Giant, Water enemies)
- Cast spell on use (Thor's Hammer → Thundara, Light Axe → Diara, Defender → Blink, Spellbinder → Confuse, Healing Staff → Cure)

### 6.3 Armor

See companion doc: [docs/ff1/armor.md](docs/ff1/armor.md)

**Categories:**

| Type | Count | Notable best |
|------|-------|-------------|
| Body armor | 16 | Dragon Mail (highest DEF) |
| Shields | 9 | Aegis Shield (Knight-only, elemental resist) |
| Helmets | 7 | Ribbon (prevents all status effects) |
| Gloves | 8 | Protect Ring (equippable by all, resists Death) |

**Armor mechanics** (see §1.5 for formulas):
- Each piece adds to Absorb and penalizes Evade%
- Some armor grants elemental resistance (halves damage from that element)
- Some armor casts spells when used as items in battle (e.g., Healing Helm → Heal, Gauntlets → Thundara)

### 6.4 Consumable Items

| Item | Price | Effect |
|------|-------|--------|
| Potion | 40 Gil | Restores ~30 HP |
| Hi-Potion | 150 Gil | Restores ~150 HP |
| Ether | 150 Gil | Restores spell charges across all levels |
| Phoenix Down | 500 Gil | Revives KO'd ally with 1 HP |
| Antidote | 75 Gil | Cures Poison |
| Eye Drops | 75 Gil | Cures Darkness |
| Echo Grass | 75 Gil | Cures Silence |
| Gold Needle | 500 Gil | Cures Stone |
| Remedy | 1,500 Gil | Cures all status ailments |
| Sleeping Bag | 75 Gil | Restores some HP (world map/save point) |
| Tent | 250 Gil | Restores some HP + charges (world map/save point) |
| Cottage | 2,000 Gil | Full HP + all charges (world map/save point) |

---

## 7. Enemies & Opponents

### 7.1 Enemy Count

The Pixel Remaster bestiary contains **128 entries** including all regular enemies and bosses.

### 7.2 Enemy Types

| Type | Characteristics | Examples |
|------|----------------|----------|
| Beast | Standard physical attackers | Goblin, Wolf, Ogre |
| Undead | Weak to Fire and Dia spells; appear in dark/underground areas | Skeleton, Ghoul, Vampire Lord |
| Elemental | Resist their own element; may be immune to physical | Green Slime (DEF 255), Fire Elemental |
| Dragon | High HP, powerful breath attacks | Red Dragon, Blue Dragon |
| Mage-type | Cast offensive/status spells | Piscodemon, Mindflayer |
| Mechanical | Rare; very high stats | Warmech |

Full enemy stat tables are in the companion doc: [docs/ff1/bestiary.md](docs/ff1/bestiary.md)

### 7.3 Bosses

| Boss | HP | Location | Weakness | Notable |
|------|-----|----------|----------|---------|
| Garland | 212 | Chaos Shrine | — | Tutorial fight |
| Bikke's Pirates | 9× 24 | Pravoka | — | Group fight; awards Ship |
| Piscodemons | 4× 84 | Marsh Cave | — | Group fight; guards Crown |
| Astos | 420 | Western Keep | — | Casts Death |
| Vampire | 280 | Terra Cavern | Fire, Dia | Guards passage to Lich |
| **Lich** | 1,200 | Terra Cavern | Fire, Dia | Earth Fiend; casts elemental spells |
| Evil Eye | 162 | Ice Cavern | — | Guards Levistone |
| **Marilith** | 1,440 | Mt. Gulg | — | Fire Fiend; 6 physical hits/turn |
| Dragon Zombie | — | Citadel of Trials | Fire, Dia | Guards Rat's Tail |
| **Kraken** | 1,800 | Sunken Shrine | Lightning | Water Fiend; 8 physical hits/turn |
| Blue Dragon | 454 | Tower of Mirage | — | 92 ATK; mini-boss |
| Warmech | 2,000 | Flying Fortress bridge | — | 128 ATK; 1% encounter rate; 32,000 EXP |
| **Tiamat** | 2,400 | Flying Fortress | — | Wind Fiend; Blaze, Thunderbolt, Poison Gas, Ice Storm |
| Lich (Past) | 2,800 | Chaos Shrine (Past) | Holy | Resists most elements |
| Marilith (Past) | 3,200 | Chaos Shrine (Past) | — | 6 hits/turn |
| Kraken (Past) | 3,600 | Chaos Shrine (Past) | — | 8 hits/turn |
| Tiamat (Past) | 5,500 | Chaos Shrine (Past) | — | Strongest fiend rematch |
| **Chaos** | 20,000 | Chaos Shrine (Past) | — | 170 ATK, 100 DEF; self-heals with Curaga; casts Flare, Blaze, Tsunami, Earthquake |

### 7.4 Encounter Mechanics

- Encounter rate is higher in dungeons than on the overworld
- Encounter groups are drawn from area-specific formation tables (not publicly documented for the Pixel Remaster)
- Cannot run from boss encounters
- **Pre-emptive strike**: party acts first; based on party Agility vs. enemy Agility
- **Ambush**: enemies act first and party is turned around; same Agility comparison, reversed
- Encounter toggle available via Boost menu (§2.2)

---

## 8. Economy

### 8.1 Currency

**Gil** is the sole currency. No secondary currencies exist.

### 8.2 Income Sources

| Source | Amount range |
|--------|-------------|
| Random battles | 3–4,000 Gil per fight (scales with area) |
| Boss battles | Varies |
| Treasure chests | Fixed Gil amounts in some chests |

Gil income can be multiplied ×1–×4 via the Boost menu (§2.2).

### 8.3 Expenses

| Category | Cost range |
|----------|-----------|
| Inn (full rest) | 30–300 Gil per stay (scales by town) |
| Lv 1–2 spells | 50–250 Gil each |
| Lv 3–4 spells | 1,000–2,500 Gil each |
| Lv 5–6 spells | 4,000–13,000 Gil each |
| Lv 7–8 spells | 30,000–40,000 Gil each |
| Early weapons | 5–550 Gil |
| Mid weapons | 550–4,500 Gil |
| Cat Claws (most expensive buyable weapon) | 65,000 Gil |
| Consumables | 40–2,000 Gil |

### 8.4 Economy Curve

The early game is tight — Gil income from Cornelia-area enemies is low (3–18 Gil) and equipment + spells cost 50–550 Gil. By mid-game (Terra Cavern), enemies drop 200–900 Gil per fight and the economy loosens. Late-game enemies in the Chaos Shrine (Past) drop 2,000–4,000 Gil, but the most expensive purchases (Lv 7–8 spells at 30,000–40,000 Gil) still require deliberate farming.

---

## 9. Minigames & Side Systems

### 9.1 Bestiary Completion

The in-game bestiary tracks all 128 enemies encountered. Defeating every unique enemy (including the 1% Warmech) unlocks a completion achievement. Accessible from the title screen: Extras → Bestiary.

### 9.2 Music Player

The Pixel Remaster includes a Music Player (Extras menu) that unlocks tracks as the player progresses. Both rearranged and original NES versions of each track are available.

### 9.3 Art Gallery

An art gallery unlocks concept art and promotional illustrations as the player hits milestones.

### 9.4 15 Puzzle

A sliding tile puzzle minigame accessible from a specific location (ship). Completing it awards Gil.

---

## 10. UI & HUD

### 10.1 Field HUD

- **Minimap** — toggleable; shows current floor layout with explored/unexplored areas, treasure chest indicators (opened/unopened count), and party position
- **Directional indicator** — marks exits and points of interest
- **No persistent HP/MP display** on the overworld; accessible via menu

### 10.2 Battle HUD

- **Party status** (right side) — character names, current HP / max HP, spell charges remaining per level
- **Command menu** — Attack, Magic, Item, Run; appears for each character in turn
- **Enemy display** (left/center) — enemy sprites grouped by type
- **Damage numbers** — float above targets on hit
- **Status icons** — displayed next to character names when afflicted

### 10.3 Menu Screens

- **Items** — consumable inventory; use or sort
- **Magic** — view learned spells and remaining charges per level
- **Equipment** — equip/remove weapon, armor, shield, helm, gloves; stat comparison shown
- **Status** — full character stats: Level, EXP, HP, STR, AGI, VIT, INT, LCK, ATK, DEF, EVA, Hit%, MagDEF
- **Formation** — reorder party members (position affects targeting priority)
- **Config** — battle speed, message speed, sound settings, boost settings

### 10.4 Boss Health

Boss HP bars are not displayed by default. The player must observe damage numbers and estimate remaining HP.

---

## 11. Engine & Presentation Systems

### 11.1 Save System

- **Inn save** — saving occurs when resting at an inn (costs Gil)
- **Quick Save** — save anywhere at any time; creates a single suspend-state save
- **Autosave** — triggers at key progression points (entering/exiting dungeons, before bosses)
- Save slots: multiple (exact count varies by platform)

### 11.2 Dialogue System

Standard JRPG text boxes. NPCs deliver fixed dialogue; some NPC text changes after story events. No dialogue choices or branching conversations.

### 11.3 Camera

Fixed top-down perspective for both overworld and dungeons. No camera rotation. Battle scenes use a fixed side-view (party on right, enemies on left).

### 11.4 Audio & Presentation Options

**Soundtrack:**
- **Rearranged soundtrack** by Nobuo Uematsu (re-orchestrated for Pixel Remaster) — default
- **Original NES soundtrack** — toggled in Config menu
- Context-sensitive music: overworld, town, dungeon, battle, boss, victory fanfare, game over, story events
- Battle music transitions: field music → battle theme on encounter → victory fanfare on win → field music resumes
- Boss fights use a distinct boss theme; Chaos has a unique final boss theme

**Font:** toggleable between Modernized typeface (Pixel Remaster default) and Classic pixelized typeface (NES-style).

### 11.5 Difficulty

No difficulty selection. The Pixel Remaster is generally easier than the NES original. Key changes that lower difficulty:
- Auto-retarget on dead enemies (§1.2)
- Working Intelligence stat (§4.3)
- Deterministic stat growth (§4.3)
- Boost options — up to ×4 EXP/Gil, encounter toggle (§2.2)
- Ethers, Hi-Potions, Phoenix Downs available in all item shops
- Bug fixes: elemental weapon properties function, various NES formula errors corrected

---

## 12. Open Questions / Unverified

- **Exact spell charge tables**: the precise number of charges gained per spell level at each character level is not fully documented in public sources. Maximum is confirmed as 9 charges per level, reached around Lv 50 for dedicated casters.
- **Pixel Remaster-specific formula changes**: the Pixel Remaster is known to use corrected versions of NES formulas (Intelligence works, auto-retarget, elemental weapons function), but the exact revised formulas have not been fully datamined and published.
- **Exact Absorb/Evade values for all 40 armor pieces**: individual armor defense and evasion penalty values are not fully listed in a single public Pixel Remaster source.
- **Enemy formation tables**: dungeon-specific encounter group compositions and probabilities are not publicly documented for the Pixel Remaster.
- **Ether charge restoration amount**: confirmed to restore charges but the exact number restored per use is unclear from available sources.
- **Surprise/preemptive attack probability formula**: known to be based on Agility comparison but exact formula for Pixel Remaster is unverified.

---

## 13. References

### Guides & Wikis
- [RPG Site — FF1 Magic List](https://www.rpgsite.net/feature/11511-final-fantasy-1-magic-list-all-ff1-spells-their-effects-how-to-get-more-magic)
- [RPG Site — FF1 Weapons List](https://www.rpgsite.net/feature/11513-final-fantasy-1-weapons-ff1-best-weapons-weapon-list-locations)
- [RPG Site — FF1 Walkthrough](https://www.rpgsite.net/feature/11508-final-fantasy-1-walkthrough-where-to-go-dungeon-maps-ff1-step-by-step-guide)
- [RPG Site — FF1 Bosses Guide](https://www.rpgsite.net/feature/11519-final-fantasy-1-bosses-guide-how-to-beat-every-ff1-boss-battle)
- [RPG Site — FF1 Job Upgrade Guide](https://www.rpgsite.net/feature/11510-final-fantasy-1-job-upgrade-how-to-change-class-to-knight-master-ninja-and-wizard)
- [Vorxu — FF1 Pixel Remaster Guide](https://vorxu.com/final-fantasy-1-pixel-remaster)
- [Vorxu — Bestiary](https://vorxu.com/final-fantasy-1-pixel-remaster/bestiary)
- [Vorxu — All 64 Spells](https://vorxu.com/final-fantasy-1-pixel-remaster/magic)
- [Vorxu — Bosses](https://vorxu.com/final-fantasy-1-pixel-remaster/bosses)
- [Vorxu — Classes & Builds](https://vorxu.com/final-fantasy-1-pixel-remaster/classes)
- [Vorxu — Armor](https://vorxu.com/final-fantasy-1-pixel-remaster/armor)
- [The Gamer — FF Pixel Remaster Magic Guide](https://www.thegamer.com/final-fantasy-pixel-remaster-magic-guide-explained/)
- [The Gamer — Pixel Remaster vs. Original Differences](https://www.thegamer.com/final-fantasy-pixel-remasters-originals-differences/)
- [GameFAQs — FF1 Game Mechanics Guide (AstralEsper)](https://gamefaqs.gamespot.com/nes/522595-final-fantasy/faqs/57009)
- [GameFAQs — FF1 Pixel Remaster Magic FAQ](https://gamefaqs.gamespot.com/pc/323458-final-fantasy-pixel-remaster/faqs/7215)
- [Final Fantasy Wiki (Fandom) — Version Differences](https://finalfantasy.fandom.com/wiki/Final_Fantasy_version_differences)
- [Steam Community — 100% Bestiary Completion Guide](https://steamcommunity.com/sharedfiles/filedetails/?id=2567260207)

### Companion Docs
- [docs/ff1/weapons.md](docs/ff1/weapons.md) — Complete weapon table with stats, prices, classes, locations
- [docs/ff1/armor.md](docs/ff1/armor.md) — Complete armor table with defense, evasion, prices, classes
- [docs/ff1/bestiary.md](docs/ff1/bestiary.md) — Full 128-entry bestiary with stats and locations
- [docs/ff1/spells.md](docs/ff1/spells.md) — Complete 64-spell list with prices, effects, and class access
