# Suikoden II — Gameplay Systems Spec

PlayStation (PS1), 1998. Konami. JRPG.

---

## 1. Core Gameplay Systems

### 1.1 Primary Gameplay Loop

Suikoden II follows a three-layer loop: narrative-driven exploration through the Dunan region, turn-based party combat in random and scripted encounters, and army-building through the 108 Stars of Destiny recruitment system. Between story beats the player recruits characters, upgrades their headquarters castle, sharpens weapons, equips runes, and trades goods for profit.

### 1.2 Regular Combat

Six-member party, turn-based. Each round the player assigns commands to all six characters, then actions resolve in SPD order. Parties arrange in two rows of three (front/back).

**Battle commands (per character):**

| Command | Description |
|---------|-------------|
| Attack | Physical attack; range depends on weapon type (S/M/L) |
| Rune | Cast a spell from an equipped rune; consumes MP at the spell's level |
| Unite | Combined attack with specific character pair(s)/group(s) in the party |
| Item | Use a consumable item |
| Defend | Reduce incoming damage for the round |
| Shift | Swap row position (front ↔ back) |

**Top-level battle options (before individual commands):**

| Option | Description |
|--------|-------------|
| Fight | Open per-character command selection |
| Run | Attempt to flee; success influenced by LCK and level gap |
| Bribe | Offer potch to end the encounter |
| Auto | All characters auto-attack with physical strikes |

### 1.3 Weapon Range & Row System

| Range | Label | Front Row | Back Row | Target Restriction |
|-------|-------|-----------|----------|--------------------|
| Short | S | Can attack | Cannot attack | Front-row enemies only |
| Medium | M | Can attack | Can attack | Front-row enemies only |
| Long | L | Can attack | Can attack | Any enemy row |

Front-row characters take more damage. Back-row characters with S-range weapons cannot perform physical attacks.

### 1.4 Damage Formulas

**Physical damage (community-verified approximation):**

```
Raw = (ATK × Exertion × Fury) − DEF
If Raw < 0: Raw = 0
If Raw > 5: Raw = Raw + rand(1..9)
If Raw ≤ 5: Raw = Raw + rand(1..3)
Damage = Raw × DoubleStrike × Sleep × AttackRune × ElementResist × Crit
```

Where:
- ATK = STR + Weapon Attack Power
- DEF = PROT + Armor Defense totals
- Exertion Rune: ATK × (1 + turn_number / 6), capping at ×2 on turn 6
- Sleep: ×2 against sleeping targets (wakes them)
- Crit: increased damage; probability scales with LCK
- DoubleStrike: ×2 when Double-Strike Rune triggers (user also receives ×2 damage)

**Magic damage:** Spell base power × caster MAG × Rune Affinity modifier − target MDEF. Rune Affinity grades (§4.3) multiply output.

### 1.5 Multi-Hit Attacks

Characters with high SPD may perform follow-up strikes on additional enemies in the same turn. Follow-ups never hit the same enemy twice, and cannot trigger if only one enemy remains.

The **Double-Beat Rune** overrides this: it grants two consecutive attacks against the same target, independent of SPD. Follow-ups and Double-Beat can combine for multiple hits per turn.

### 1.6 Experience & Leveling

- Level cap: 99
- Fixed EXP thresholds per level
- EXP earned per battle scales with the level gap between party members and enemies
- Lower-level characters receive dramatically more EXP from the same encounter (rubber-band / catch-up mechanic)
- Higher-level characters receive diminishing EXP, discouraging over-grinding
- Fainted characters earn no EXP unless revived before battle ends

### 1.7 Duel System

Scripted one-on-one fights during key story moments. Three actions in a rock-paper-scissors triangle:

| Action | Beats | Loses To |
|--------|-------|----------|
| Attack | Defend | Wild Attack |
| Wild Attack | Attack | Defend |
| Defend | Wild Attack | Attack |

- Attack deals moderate damage
- Wild Attack deals heavy damage but is punished hard by Defend (attacker takes damage instead)
- Defend reduces incoming damage
- The opponent telegraphs their next move through dialogue lines before each round; reading these cues is the core skill

**Duels in the game:**

1. Flik
2. Amada
3. Luca Blight (after the three-party boss gauntlet)
4. Han Cunningham
5. Jowy Atreides (final; required for best ending — see §5.2)

### 1.8 Army Battles

Grid-based tactical combat using unit squads. Each unit has one commander and up to two sub-commanders whose stats and abilities contribute to the unit's power.

**Unit types:**

| Type | Movement | Attack Range | Notes |
|------|----------|-------------|-------|
| Infantry | Narrow | Adjacent (1 tile) | Balanced ATK/DEF |
| Cavalry | Wide | Adjacent (1 tile) | High mobility |
| Archer | Medium | 2 tiles | Weak in melee |
| Mage | Medium | 3 tiles | 0 melee power |

**Commands per unit:** Attack, Rune (special ability, limited uses), Wait.

**Type advantage system:**
- Strong vs. weak: damage dealt ×2, damage received ÷2
- Weak vs. strong: damage dealt ÷2, damage received ×2

**Unit stats:** Each unit's ATK and DEF are derived from the commander's base stats plus sub-commander bonuses (typically +0 to +3 ATK, +0 to +2 DEF). Top-tier units reach ~14 ATK or ~13 DEF.

**Special abilities** (assigned by sub-commanders):

| Ability | Effect |
|---------|--------|
| Cavalry | +2 movement range |
| Flight | +2 movement, ignore terrain (stacks with Cavalry) |
| Shortcut | Ignore terrain penalties |
| Encourage | All adjacent allied units may act again |
| Critical | Random chance of bonus damage |
| Melee | Higher chance to defeat Mage and Archer units |
| Fire Spear | 3-tile line attack (limited uses) |
| Bombard | 5-tile range attack (limited uses) |
| Repair Self | Heal unit (limited uses) |

Abilities do not stack — no benefit to two characters providing the same ability in one unit.

**Automation:** The "Leave it to Apple" option lets the AI handle all tactical decisions for a battle.

**Victory/failure:** Defeat all enemy units to win. If the protagonist's unit is destroyed, it triggers a bad ending. Oulan's Bodyguard ability prevents character death even if their unit falls.

---

## 2. Controls & Input (PS1)

| Context | D-Pad | × Button | ○ Button | △ Button | □ Button | L1 | R1 | Start | Select |
|---------|-------|----------|----------|----------|----------|----|----|-------|--------|
| Field | Move | Confirm/Interact | Cancel/Run | — | Menu/Command Window | Dash | Dash | Pause | — |
| Battle | Navigate menus | Confirm | Cancel | — | — | Rune shortcut | — | — | — |
| World Map | Move | Confirm | Cancel | — | Map toggle | Dash | Dash | — | — |
| Menus | Navigate | Confirm | Cancel/Back | — | — | — | — | — | — |

Hold L1 or R1 while moving on the field or world map to dash (run at increased speed).

---

## 3. World Structure

### 3.1 Setting

The Dunan region, directly north of the Toran Republic (setting of Suikoden I). The region is divided between the Highland Kingdom (east) and the City-States of Jowston (west), a confederation of politically autonomous city-states. The story follows the Dunan Unification War between these powers.

### 3.2 Area Types

**Towns & Cities (25):** Kyaro Town, Muse City, Coronet Town, Kuskus Town, South Window City, Radat Town, Lakewest Town, Two River City, Kobold Village, Greenhill City, Forest Village, Rockaxe, Highway Village, Banner Village, Gregminster, Rokkaku Hamlet, Drakemouth Village, Tigermouth Village, Tinto City, Crom Village, Mercenary Fortress, Ryube Village, Toto Village, Sajah Village, and the player's Headquarters castle.

**Dungeons & Paths (19):** Ryube Forest, North Sparrow Pass, Sindar Ruins, Cave of the Wind, North Window, Two River Sewers, Kobold Village Forest, Greenhill Forest, Path to Matilda, Mt. Rakutei, Banner Pass, Tinto Pass, Tinto Mines, Rockaxe Castle, L'Renouille, Tenzan Pass, Highland Garrison, Lampdragon Mountain, Castle Forest.

**Overworld Fields (8):** Labeled Area A through Area H, each with distinct enemy encounter tables and treasures.

### 3.3 Travel & World Map

- Movement on a 2D sprite-based overworld connecting towns and dungeons
- Random encounters occur on the overworld and in dungeons
- World map display (bottom-right minimap) unlocked by recruiting Templeton and receiving the Suiko Map
- No fast-travel system in the original PS1 version; Viki's Blinking Mirror teleports the party back to headquarters only

### 3.4 Locked Progression & Gating

Progression is story-gated. New areas open as the narrative advances. The Matilda region has a well-known sequence-break glitch ("Matilda Glitch") that allows early access.

---

## 4. Playable Characters / 108 Stars of Destiny

### 4.1 Recruitment System

108 recruitable characters (the Stars of Destiny), plus several additional non-Star characters (~117 total). Characters join through various methods:

| Method | Examples |
|--------|---------|
| Automatic (story) | Riou, Nanami, Jowy, Viktor, Flik |
| Talk & ask | Many Stars simply need to be found and spoken to |
| Conditional | Headquarters at certain level, specific party member present, item required |
| Challenge | Win a minigame or duel (e.g., Shilo — win 5,000 potch at Chinchirorin) |
| Trade quest | Gordon — earn 50,000 potch profit through Trading Posts |
| Missable | Some characters are permanently missable if not recruited before certain story events |

Recruiting all 108 Stars before the battle of Rockaxe is required for the best ending (§5.2).

### 4.2 Stat System

Ten primary attributes per character:

| Stat | Full Name | Function |
|------|-----------|----------|
| HP | Hit Points | Health; character faints at 0 |
| STR | Strength | Raw physical power; contributes to ATK |
| DEX | Dexterity | Hit accuracy and evasion |
| PROT | Protection | Physical defense base; contributes to DEF |
| MAG | Magic | Magic power; determines MP pool and spell potency |
| MDEF | Magic Defense | Reduces incoming magic damage |
| SPD | Speed | Turn order priority |
| LCK | Luck | Critical hit chance, flee success rate |
| ATK | Attack Power | Derived: STR + weapon power |
| DEF | Defense Power | Derived: PROT + equipped armor totals |

- Each character has unique per-stat growth rates (community-designated as rank tiers)
- Soft cap: 255 per base stat from leveling; equipment can push beyond
- Stat-boosting stones grant +1 to +3 to a single stat (Stone of Power, Stone of Skill, Stone of Defense, Stone of Magic Defense, Stone of Magic, Stone of Speed, Stone of Luck)

### 4.3 Rune System

Runes are the magic system. Characters have up to three rune slots: Right Hand, Left Hand, Head.

**Slot unlock levels (vary per character; typical progression):**
- Right Hand: available from recruitment
- Left Hand: unlocks ~level 25
- Head: unlocks ~level 40

Some characters have fewer slots or permanently fixed runes (e.g., Riou's Bright Shield Rune on Right Hand).

**MP system:** Per-level spell charges, not a shared MP pool. A character's MAG stat determines charges at each level:

| Spell Level | MAG Threshold Examples |
|-------------|----------------------|
| Level 1 | Available at low MAG; 6+ casts typical |
| Level 2 | Moderate MAG; 3+ casts typical |
| Level 3 | Higher MAG; 1–2 casts |
| Level 4 | ~101 MAG for 1 cast; ~161 MAG for 2 casts |

**Rune types:**
- **Magic runes** — four-level spell progression. Major magic runes and sample spells:

| Rune | Lv 1 | Lv 2 | Lv 3 | Lv 4 |
|------|------|------|------|------|
| Fire/Rage | Fire Wall (~150 dmg, row) | Dancing Flames (~300, all) | Explosion (~700, all) | Final Flame (~900, all) |
| Water/Flowing | Kindness Rain (heal one) | Protect Mist (DEF up) | Silent Lake (silence all) | Mother Ocean (full heal all) |
| Wind/Cyclone | Wind of Sleep (sleep, row) | The Shredding (dmg, one) | Healing Wind (heal all) | Shining Wind (revive + heal all) |
| Earth/Mother Earth | Clay Guardian (DEF up) | Earthquake (~300, all) | Copper Sun (~500, all) | Guardian Earth (~700, all) |
| Lightning/Thunder | Bolt of Wrath (~150, one) | Rainstorm (~250, all) | Soaring Bolt (~500, one) | Thunder Runner (~700, all) |
| Resurrection | — | — | — | Revive all fainted allies |
| Black Sword (Unique) | Flash Judgement | — | — | Hungry Fiend |

- **Weapon runes** — passive effects on physical attacks (Poison: 40% chance, Sleep: 20%, Silence: 20%, Viper: 33% hit rate but instant-kill on hit, Fire Lizard, Double-Beat, Double-Strike, etc.)
- **Special effect runes** — passive stat bonuses (Gale: SPD ×1.5, Wall: DEF ×2, Exertion: escalating ATK per turn, Firefly: inflicts Target on self)
- **Command runes** — grant special battle commands
- **Character-specific runes** — unique to individual characters (Bright Shield, Black Sword, Star Dragon Sword, Beast Rune, etc.)

**Elemental cycle:** Fire → Wind → Earth → Lightning → Water → Fire. Each element deals increased damage to the next in the chain and reduced damage to the previous.

**Rune affinity:** Each character has an affinity grade per element that multiplies magic damage:

| Grade | Modifier | Notes |
|-------|----------|-------|
| A | +40% damage | Best affinity |
| B | +20% damage | Good |
| C | Normal (×1) | Average |
| D | −20% damage | Poor |
| E | +20% damage | Unstable; may backfire (20% chance) |

### 4.4 Unite Magic (Combo Spells)

When two compatible Level 4 rune spells are cast in the same turn (can be from one character with two rune slots), a Unite Magic triggers:

| Rune Pair | Spell Name | Effect |
|-----------|-----------|--------|
| Fire/Rage + Earth/Mother Earth | Scorched Earth | ~1,300 damage to all enemies |
| Fire/Rage + Lightning/Thunder | Blazing Camp | ~2,000 to one enemy, ~1,500 to all others |
| Water/Flowing + Wind/Cyclone | Water Dragon | ~800 to all enemies + full party heal |
| Water/Flowing + Lightning/Thunder | Thor | ~2,000 to one enemy + full party heal |
| Wind/Cyclone + Earth/Mother Earth | Storm Fang | ~1,000 to all enemies |

### 4.5 Character Roles

Of the 108 Stars, 72 can join the battle party, with ~8 additional non-Star combatants (~80 total battle-capable characters). The rest fill non-combat roles:

| Role | Description | Examples |
|------|-------------|---------|
| Combat | Join the battle party (up to 6 active) | Riou, Flik, Viktor, Nanami, Georg |
| Support | Provide passive party bonuses when assigned | Stallion (escape boost), Apple (tactics) |
| Headquarters | Staff castle facilities; non-combat | Hai Yo (restaurant), Tessei (blacksmith), Barbara (library) |

---

## 5. Story & Progression

### 5.1 Main Story Structure

The narrative follows Riou and Jowy, childhood friends and former Highland soldiers, through the Dunan Unification War. The story progresses through major city-state liberation arcs:

1. **Prologue / Escape** — Kyaro, Mercenary Fortress, flight from Highland
2. **South Window & Founding** — establishing the New State Army headquarters at North Window Castle
3. **Two River** — defending the multi-racial city from Highland siege
4. **Greenhill** — infiltrating and liberating the occupied academy city
5. **Tinto / Neclord** — vampire sideplot and alliance with the mining city
6. **Matilda** — securing the Knightdom's allegiance
7. **Luca Blight** — the three-party night ambush and duel against the Highland prince
8. **Rockaxe & L'Renouille** — final campaign against Highland, confrontation with Jowy and the Beast Rune

### 5.2 Endings & Branching Points

Four endings, determined by cumulative choices:

| Ending | Trigger | Requirements |
|--------|---------|-------------|
| **Bad** | Nanami's plea (Tinto arc) | Accept her offer to flee the war; game ends early |
| **Standard** | Post-final-boss Great Hall | Defeat final boss, accept leadership |
| **Alternate** | Tenzan Pass after Great Hall | Defeat final boss, refuse leadership, travel to Tenzan Pass, defeat Jowy in duel twice |
| **Best (True)** | Tenzan Pass with all conditions met | All 108 Stars recruited before Rockaxe + Nanami saved (respond to Gorudo's dialogue prompt quickly) + no permanent army battle deaths + defeat final boss + refuse leadership + defend-only in final Jowy duel + refuse the rune's offer |

### 5.3 Suikoden I Save Transfer

Loading a Suikoden I clear save (or save at final save point) when starting a new game grants:

| Bonus | Condition |
|-------|-----------|
| Level bonuses for returning characters | +1 per 10 levels above 60 in the old save |
| Weapon level bonuses | Old weapon levels 12–16 boost starting weapon levels |
| Equipment transfer | Tir retains armor; Humphrey may transfer Windspun Armor |
| Gremio alive + Recipe #39 (Special Stew) | Old save had all 108 Stars collected |
| Tir McDohl recruitable | Grants the Double Leader Attack unite |

### 5.4 Side Content

- **Clive's Quest** — timed sidequest (must reach each trigger location within cumulative play-time limits: Lakewest <11h, Forest Village <13h, Rockaxe <14h, Radat <15h). Follows the Howling Voice Guild storyline
- **Richmond's Investigations** — pay the detective to uncover 2–4 secrets per recruited character (100–800 potch per investigation). Some secrets require other characters to be recruited first
- **108 Stars completion** — the meta-collection quest driving the entire game toward the best ending

---

## 6. Items & Equipment

### 6.1 Inventory System

- **Party bag:** 30 item slots shared across the party. Items must be placed on individual characters to be usable in battle.
- **Warehouse:** 60-slot storage at headquarters (managed by Barbara). Supports Store, Retrieve, Strip (remove all equipped items from a character), Arrange (sort by type), and Sell/Discard.

### 6.2 Equipment Slots

| Slot | Categories | Notes |
|------|-----------|-------|
| Weapon | Unique per character (not swappable) | Upgraded via blacksmith sharpening |
| Head | Helmets, hats, headbands | Restricted by character class |
| Body | Robes (R), Martial Arts (MA), Light Armor (Lt), Heavy Armor (Hvy) | Each character compatible with one class |
| Shield | Shields | Some characters cannot equip shields |
| Accessory | Rings, badges, earrings, amulets, ornaments | Some restricted by age or race |

Rune slots (Right Hand, Left Hand, Head) are separate from equipment — see §4.3.

### 6.3 Weapon Sharpening System

Characters do not find or buy new weapons. Instead, each character has a named weapon that is upgraded by blacksmiths.

**Weapon levels:** 1–16.

**Blacksmith tiers:**

| Blacksmith | Max Level |
|------------|-----------|
| Town blacksmiths (varies) | 5–13 (Tinto highest at 13) |
| Tessei (HQ) + Iron Hammer | 9 |
| Tessei + Copper Hammer | 12 |
| Tessei + Silver Hammer | 15 |
| Tessei + Gold Hammer | 16 (max) |

**Sharpening costs (potch):**

| To Level | Cost |
|----------|------|
| 1–2 | 300 |
| 3–4 | 500 |
| 5–6 | 1,000 |
| 7–8 | 3,000 |
| 9–10 | 5,000 |
| 11–12 | 10,000 |
| 13–14 | 30,000 |
| 15–16 | 70,000 |

The four hammers are found in treasure chests/events throughout the game.

### 6.4 Consumable Items

Key consumables include Medicine (HP restore), Mega Medicine (full HP), Antitoxin (cure poison), Resurrection items (revive fainted characters), Escape Talisman (flee dungeons), and cooking ingredients used in the Cook-off minigame (§9.2).

---

## 7. Enemies & Bosses

### 7.1 Regular Enemies

Random encounters feature groups of 1–6 enemies arranged in front/back rows (mirroring party layout). Enemy difficulty scales by area, not by party level. Each area has a fixed encounter table.

### 7.2 Notable Boss Design

**Luca Blight (Night Ambush):**
- Three consecutive battles using three pre-selected parties (led by Flik, Viktor, Riou)
- Luca's HP carries across all three fights (does not regenerate)
- Three actions per turn; resists all damage types
- Uses unique Flaming Arrows (AoE fire) and multi-slash attacks
- Transitions to next party at 2/3 and 1/3 HP thresholds
- Concludes with a one-on-one duel (§1.7)

**Beast Rune (Final Boss):**
- Multi-phase encounter
- The True Rune manifests as a destructive entity after Jowy's defeat

**Neclord:**
- Requires the Star Dragon Sword (Viktor's unique weapon) to damage him; otherwise immune
- Returns from Suikoden I as a recurring vampire antagonist

### 7.3 Boss Patterns

Most bosses follow escalating-threat design: standard attacks early, then unique abilities at HP thresholds. Many are immune to instant-death and most status effects. Elemental weaknesses vary by boss (Luca Blight is notably vulnerable to Lightning and Earth magic).

---

## 8. Economy

### 8.1 Currency

**Potch** — sole currency for all transactions.

### 8.2 Income Sources

| Source | Notes |
|--------|-------|
| Enemy drops | Primary early-game income |
| Treasure chests | Fixed placement in dungeons |
| Trading Posts | Buy-low-sell-high commodity trading (§8.3) |
| Selling equipment/items | Standard shop sell-back |
| Chinchirorin gambling | Net gain if skilled/lucky (§9.3) |

### 8.3 Trading Post System

Eight Trading Posts across the world (plus one at Headquarters). Each stocks different trade goods at fluctuating prices. Prices change over in-game time.

**Key trade goods and routes:**

| Item | Buy Location | Buy Price Range | Sell Location | Sell Price Range |
|------|-------------|----------------|---------------|-----------------|
| Ancient Text | Kobold Village | 400–1,200 | Forest Village | 25,000–35,000 |
| Crystal Ball | Varies | Low | Varies | High |
| Deer Antler | Varies | Low | Varies | High |

Typical profit: ~20,000 potch per trading run. Gordon's recruitment challenge requires 50,000 potch total trading profit.

### 8.4 Major Sinks

| Sink | Cost Range |
|------|-----------|
| Weapon sharpening | 300–70,000 per level per character |
| Equipment purchases | Scales with story progression |
| Rune attachment (Rune shops) | Varies |
| Richmond investigations | 100–800 per secret |
| Chinchirorin wagers | Variable |

---

## 9. Minigames & Side Systems

### 9.1 Headquarters Castle

The player's castle (North Window) grows through four levels based on recruitment count and story progress:

| Level | Recruitment Count | Story Trigger |
|-------|-------------------|---------------|
| 1 | 1–30 | Until defense of Two River |
| 2 | 31–61 | Until recruiting Klaus and Kiba |
| 3 | 62–100 | Until liberation of Greenhill |
| 4 | 101+ | Until end of game |

**Facilities unlocked through recruitment:**

| Facility | Character | Function |
|----------|-----------|----------|
| Blacksmith | Tessei | Weapon sharpening (§6.3) |
| Rune Shop | Jeanne | Attach/remove runes |
| Item Shop | Alex | Buy/sell items |
| Armor Shop | Hans | Buy/sell equipment |
| Trading Post | Gordon | Commodity trading (§8.3) |
| Appraiser | Lebrante | Identify ? items |
| Inn | Hilda | Rest and heal party |
| Restaurant | Hai Yo | Cook-off minigame (§9.2) |
| Detective Agency | Richmond | Character investigations (§5.4) |
| Bath | Tetsu | Bath scenes with antique displays |
| Farm | Tony | Whack-a-Mole minigame |
| Chinchirorin | Shilo | Dice gambling (§9.3) |
| Library | Barbara | Bestiary/old book storage |
| Sound Room | Connell | Change in-game sound effects using Sound Sets |
| Window Settings | Tenkou | Customize UI window color and shape using Window Sets |
| Guardian Deity | Jude | Build a statue from 4 segment plans (Head, Body, Legs, Tail × Dragon/Unicorn/Turtle/Rabbit); combinations yield item rewards |

### 9.2 Cook-off Minigame

Iron Chef-style cooking competition run by Hai Yo. The player prepares a three-course meal (appetizer, main course, dessert) judged by a panel of four characters from the 108 Stars.

- Judges score each dish 0–5; highest total wins
- Judges are randomly selected; the host hints at their preferences
- Uses cooking ingredients (Sugar, Salt, Mayonnaise, Red Pepper, Soy Sauce, etc.) purchased from Trading Posts
- Each dish has five preparation variants
- Winning earns the opponent's recipe; losing risks the Moon Bird Recipe
- Full sub-plot: Hai Yo vs. the Black Dragon Clan, a shadowy underground cooking organization

### 9.3 Chinchirorin (Dice Gambling)

Dice game played against Shilo at Lakewest (and later at headquarters). Standard chinchirorin rules with three dice. Winning 5,000 potch from Shilo at Lakewest recruits him.

### 9.4 Other Minigames

| Minigame | Location | Unlock |
|----------|----------|--------|
| Whack-a-Mole | Farm (HQ) | Recruit Tony from Forest Village |
| Rope Climbing | Laundry area (HQ) | Castle Level 2+ (31+ characters) |
| Fishing | Various | Available at certain locations |
| Dancing Stage | HQ | Available via recruited characters |

### 9.5 Collectibles

| Collectible | Purpose |
|-------------|---------|
| Window Sets | Customize UI window appearance (given to Tenkou) |
| Sound Sets | Change in-game sound effects (given to Connell) |
| Recipes | Unlock dishes for Cook-off minigame |
| Old Books | Library collection (given to Barbara) |
| Listening Crystals | Recruit monster characters; only 2 available — choose 2 of 3 (Feather, Siegfried, Abizboah) |
| Guardian Deity Plans | 16 plans (4 segments × 4 types) for statue combinations |
| Antique Items | Display in the Bath for cosmetic scenes |

---

## 10. Status Effects

### 10.1 Positive Effects

| Status | Effect | Source |
|--------|--------|--------|
| Anger | ATK ×1.5 | Certain foods, runes, triggered by ally death |
| Boost | ATK ×2 for random turns; user takes half damage dealt | Spicy foods |
| Hyper | Magic damage +50%; backfire chance +20% | Sweet foods, Alert Rune |
| Invulnerable | Immune to damage for 1 turn; cannot act | Cream-based foods |
| Regeneration | Restore HP each turn end | Equipment (Silver Collar, Star Earrings, Sun Badge) |
| Toasty | Regenerate HP for set duration | Spicy foods, using the Bath |

### 10.2 Negative Effects

| Status | Effect | Cure |
|--------|--------|------|
| Poison | Lose 1/16 (~6%) max HP per turn; persists after battle | Antitoxin, tomato-based foods |
| Sleep | Cannot act; taking damage wakes but deals ×2 damage | Gyoza variants, Ramen, getting hit |
| Silence | Cannot cast rune magic | Spinach-based foods, Chinese Noodles |
| Paralysis | Cannot take any action | Defeat the inflicting enemy |
| Lose Balance (Unbalanced) | Cannot attack or use magic; can use items | Egg-based foods |
| Shrink | ATK −50% | Kiddie Pasta |
| Bucket | Accuracy −50% | Fish-fried foods |
| Balloon | Collect 3 → removed from battle | Needle item, Pointy Hat, fish foods |
| Panic | Uncontrollable; attacks randomly | Mayonnaise Pie, Chili Pasta |
| Target | All enemies focus attacks on this character | Clam-based foods; Firefly Rune intentionally inflicts this |
| Unfriendly | Cannot participate in Unite Attacks | Sandwich variants |
| Rust | Weapon level decreases by 1 | Sunomono variants |
| Faint | 0 HP; incapacitated, no EXP unless revived | Resurrection spells/items |

---

## 11. UI & HUD

### 11.1 Field HUD

Minimal HUD during field exploration. No persistent health bars or status indicators on screen. The player accesses party info through the menu (□ button).

### 11.2 Battle HUD

- Character names with current/max HP displayed for all six party members
- Party arranged visually in two rows of three (front/back)
- Weapon range indicator (S/M/L) next to each character
- Enemy sprites visible with targeting cursor
- Command menu appears per-character during the Fight phase
- Rune spell list shows spell names, levels, and remaining charges
- No enemy HP bars in regular encounters; bosses have visible HP in some encounters

### 11.3 Menu Screens

Accessed via □ button on the field:

| Screen | Contents |
|--------|----------|
| Items | Inventory management, use consumables |
| Equipment | Equip armor, accessories, view stats |
| Rune | View equipped runes and spells |
| Status | Full character stat display |
| Party | Change active party members (at HQ or certain locations) |
| Formation | Arrange front/back row positions |
| Save | Save to memory card (at save points only) |
| Settings | Sound mode (stereo/mono), window customization |

---

## 12. Engine & Presentation Systems

### 12.1 Save System

- Save at designated save points (glowing markers in towns and dungeons)
- One save file per memory card slot (15 blocks on PS1 memory card)
- Suikoden I save transfer read at new game start only (§5.3)

### 12.2 Camera

- Fixed top-down perspective in towns and dungeons (hand-drawn 2D tilesets with sprite characters)
- Scaled/rotated overworld with scrolling terrain
- Fixed camera in battle (side-view with party on left, enemies on right)
- Army battles use top-down tactical grid view

### 12.3 Dialogue System

- Text-box based dialogue with character portraits
- Timed dialogue prompts at critical story moments (Nanami's arrow scene requires fast response)
- Duel opponents telegraph moves through dialogue text (§1.7)
- Richmond investigation results delivered as dialogue sequences

### 12.4 Audio System

- Background music changes by location/event; battle music triggers on encounter
- Sound mode: Stereo/Mono toggle in settings
- Sound Sets alter UI sound effects (see §9.5)

---

## 13. Open Questions / Unverified

- **Exact physical damage formula:** Community research (Suikosource) is ongoing; the formula in §1.4 is an approximation. Precise interaction of modifiers (especially element resistance multipliers) may differ
- **Per-character stat growth rate tables:** Community has identified rank-based growth systems but complete tables for all 108 characters are not fully published in a single verified source
- **Exact rune slot unlock levels per character:** Vary significantly; ~25 (Left Hand) and ~40 (Head) are approximate averages for Riou but differ per character. The Suikoden Wikia has character-specific data
- **Enemy bestiary data:** Complete HP/EXP/drop/weakness tables for all enemies are partially documented across multiple FAQs but no single canonical source consolidates all values
- **Chinchirorin exact odds and payout rules:** Standard chinchirorin rules assumed but PS1-specific RNG implementation details are not documented
- **Army battle damage formula:** Exact ATK/DEF calculations for unit-based combat beyond the ×2/÷2 type advantage system
- **Rune affinity grades per character:** Complete A–E affinity tables exist on Suikosource but have not been fully cross-verified against datamines

---

## 14. References

### Wikis
- [Suikoden Wikia (Fandom)](https://suikoden.fandom.com/wiki/Suikoden_II) — character data, rune lists, equipment, unite attacks
- [Gensopedia](https://gensopedia.org/w/Suikoden_II) — locations, items, recruitment, lore
- [StrategyWiki — Suikoden II](https://strategywiki.org/wiki/Suikoden_II/Gameplay) — gameplay mechanics, controls, combined attacks

### Guides & FAQs
- [Game8 — Suikoden 2 Guides](https://game8.co/games/Suikoden-2/archives/501120) — stats, unite attacks, army battles, status effects, minigames
- [GameFAQs — Suikoden II](https://gamefaqs.gamespot.com/ps/198844-suikoden-ii/faqs) — Rune Guide (blazefeeler), Weapon System FAQ (DeathKnight), Character Database FAQ (SIMSteven), Richmond Secrets FAQ, Duel Guide, Boss Guide
- [RPG Site — Recruitment Guide](https://www.rpgsite.net/guide/16986-suikoden-ii-recruitment-guide-how-to-get-all-108-star-destiny-characters)
- [Neoseeker — Rune System FAQ](https://www.neoseeker.com/suikodenii/faqs/91502-suikoden-ii-rune-deathknight.html)

### Community Research
- [Suikosource — Physical Damage Formula Discussion](https://www.suikosource.com/phpBB3/viewtopic.php?t=15048)
- [Suikosource — Stat Growth Rates](https://www.suikosource.com/phpBB3/viewtopic.php?f=9&t=10487)
- [Suikosource — Rune Affinities](https://suikosource.com/games/gs2/guides/affinities.php)
- [OmniGamer — Suikoden II Stats Calculator](https://omnigamer.me/projects/sui2stats.html)
