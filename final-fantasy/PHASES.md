# Final Fantasy I Pixel Remaster — Implementation Phases

Systems-first recreation. Not the full game — enough content to validate that every system scales. All 12 classes are implemented (core identity), but dungeons, towns, enemies, and equipment use representative subsets.

---

## Phase 1 — Field Movement & Dialogue

Establishes top-down exploration, tile collision, NPC interaction, and the town as a walkable space.

- 8-directional character movement with diagonal support
- Tile-based collision (walls, water, counters)
- NPC interaction: walk up and press Confirm to trigger dialogue
- Dialogue system: text box with character-by-character reveal, advance on Confirm
- One town: Cornelia — buildings for inn, weapon shop, armor shop, item shop, White Magic shop, Black Magic shop, castle entrance (shops are NPC dialogue placeholders for now — no buy/sell UI yet)
- Cornelia NPCs with fixed dialogue (King, Princess Sarah placeholder, shop clerks, ~6 townspeople)
- Title screen: New Game only (no save/load yet)
- Party of 4 predefined characters: Warrior, Monk, White Mage, Black Mage at level 1 with starting stats per SPEC §4.1

### Assets

**Sprites**
- Warrior overworld sprite (4-direction walk cycle)
- Monk overworld sprite (4-direction walk cycle)
- White Mage overworld sprite (4-direction walk cycle)
- Black Mage overworld sprite (4-direction walk cycle)
- NPC sprites: King of Cornelia, Princess Sarah, shop clerk (generic), townsperson A, townsperson B, townsperson C

**Tilemaps**
- Cornelia town tileset (buildings, paths, grass, trees, water, castle walls)
- Cornelia town map layout

**Audio**
- Cornelia town theme
- NPC talk SFX
- Footstep SFX (stone, grass)

**UI**
- Title screen (New Game only)
- Dialogue text box

---

## Phase 2 — Menu System

Adds the main menu shell, party status display, inventory viewing, and formation reordering — giving the player visibility into their party state.

- Main menu: opened with Start button; entries for Items, Magic, Equipment, Status, Formation, Config (Magic, Equipment, Config are stubs for now)
- Items screen: view consumables in inventory; use items on party members from the field
- Status screen: display character name, level, class, HP, and base stats (STR, AGI, VIT, INT, LCK)
- Formation screen: reorder party members via drag/swap (affects targeting priority in combat, Phase 3)

### Assets

**Audio**
- Menu open SFX
- Menu cursor move SFX
- Menu confirm SFX
- Menu cancel SFX

**UI**
- Main menu (Items, Magic, Equipment, Status, Formation, Config)
- Items list screen
- Status screen
- Formation reorder screen

---

## Phase 3 — Turn-Based Combat

Adds the full battle engine with physical attacks, the damage formula, multi-hit, critical hits, turn order, party formation targeting, battle rewards, leveling, and Game Over.

- Battle scene: side-view layout (party right, enemies left)
- Small field area outside Cornelia's gates (grass, paths) where random encounters occur; not the full overworld — just enough to fight
- Encounter trigger: step counter on field; ~20–30 steps between encounters
- Battle transition: screen effect from field to battle scene
- Turn input: player selects commands for all 4 characters, then the round resolves
- Turn order: sorted by Agility; ties broken randomly
- Attack command: physical damage formula — `Damage = random(ATK .. ATK×2) − Absorb`, minimum 1 per hit
- AttackPower: `Strength / 2 + WeaponDamage`
- Number of hits: `MaxHits = floor(Hit% / 32) + 1`
- Hit probability: `BaseChance = 168/200; HitChance = Base + AttackerHit% − DefenderEvade%`
- Critical hits: `CritRate = WeaponIndex` for armed, `Level × 2` for Monk unarmed, 0 otherwise; crits ignore Absorb
- Auto-retarget: if targeted enemy dies before attacker acts, attack redirects to next living enemy
- Party formation targeting: enemies target positions 1–2 more often than 3–4
- Run command: success based on party Luck vs. enemy Agility; disabled for bosses
- Item command: use consumables in battle (Potion only for now)
- Enemy AI: basic physical attacks with per-enemy ATK values
- Battle rewards: EXP split equally among surviving party members; Gil awarded in full
- Level-up: deterministic stat increases per class (SPEC §4.3); level cap 99; Hit% growth: Warriors/Monks +3/level, others +1/level
- Victory sequence: fanfare → EXP/Gil display → return to field
- Game Over: all party KO'd → Game Over screen → return to title
- Starter enemies (5): Goblin (8 HP, 4 ATK), Goblin Guard (16 HP, 8 ATK), Wolf (20 HP, 8 ATK), Black Widow (28 HP, 12 ATK), Gigas Worm (52 HP, 16 ATK)
- Party starts with pre-equipped starter gear (no shop UI yet): Warrior — Rapier (9 ATK), Leather Armor, Leather Shield, Leather Cap; Monk — Nunchaku (12 ATK), Clothes; White Mage — Hammer (9 ATK), Clothes; Black Mage — Knife (5 ATK), Clothes; all get Leather Gloves
- Additional starter equipment available in treasure or drops for testing: Staff (6 ATK), Leather Armor (4 DEF)

### Assets

**Sprites**
- Warrior battle stance sprite
- Monk battle stance sprite
- White Mage battle stance sprite
- Black Mage battle stance sprite
- Battle attack animation (slash)
- Goblin sprite
- Goblin Guard sprite
- Wolf sprite
- Black Widow sprite
- Gigas Worm sprite

**Tilemaps**
- Cornelia outskirts field area (grass, paths — small encounter zone)

**VFX**
- Damage number popup (white, floating)
- Critical hit flash
- Enemy death dissolve
- Battle transition swirl

**Audio**
- Battle theme (normal encounters)
- Victory fanfare
- Game Over theme
- Physical attack SFX (weapon swing)
- Physical hit SFX
- Miss SFX (whiff)
- Critical hit SFX
- Enemy death SFX
- Level-up SFX
- Battle start SFX (encounter sting)

**UI**
- Battle HUD: party names, HP/max HP (right side)
- Command menu: Attack, Magic (disabled), Item, Run
- Enemy targeting cursor
- EXP/Gil reward screen
- Level-up notification
- Game Over screen

---

## Phase 4 — Spell Charge System & Elemental Damage

Adds the Vancian spell charge engine, the Magic battle command, spell learning from shops, elemental weakness/resistance, and the first 16 spells — establishing magic as a combat pillar.

- Magic command in battle: select spell level → select spell → select target
- Spell charge system: 8 levels, separate charge pool per level, starting ~2–3 charges, max 9
- Charges increase at fixed level thresholds per class
- Spell learning: purchase from magic shops; 3 spells per level per class (4 available, must skip one)
- Magic menu screen (main menu): view learned spells and remaining charges per level
- Magic damage formula: `Damage = random(SpellPower .. SpellPower×2)`; miss = halved damage
- Spell hit chance: `SpellAccuracy − target's MagicDefense`
- Elemental system: 8 elements (Fire, Ice, Lightning, Earth, Poison, Time, Death, Status)
- Elemental weakness: +50% damage, +20% hit chance
- Elemental resistance: damage halved
- Basic shop buy screen: introduced here for magic shops; reused by item shops in Phase 5 and extended with sell/equipment in Phase 7
- Charge restoration: Ether restores charges (consumable); inn HP/charge restoration deferred to Phase 7
- All Lv 1–2 spells (16 spells):
  - White Lv 1: Cure (16–32 HP), Protect (+8 DEF), Dia (20–80 undead), Blink (+80 Evade)
  - White Lv 2: Blindna (cures Darkness), Silence (inflicts Silence), NulShock (halves Lightning), Invis (+40 Evade)
  - Black Lv 1: Fire (10–40 Fire), Sleep (inflicts Sleep), Focus (−20 Evade), Thunder (10–40 Lightning)
  - Black Lv 2: Blizzard (20–80 Ice), Dark (inflicts Darkness), Temper (+14 ATK), Slow (reduces hits)
- Stat-modifying buffs functional: Protect, Blink, Invis, Temper apply their stat changes immediately
- Debuffs functional: Slow reduces enemy hit count, Focus lowers Evasion by 20
- Basic status effects from Lv 1–2 spells: Sleep (cannot act; broken by hit), Darkness (−40 hit rate), Silence (blocks magic) — these three are functional; remaining statuses deferred to Phase 5
- Cornelia magic shops stocked with Lv 1 spells (50 Gil each)
- Enemies with elemental weaknesses (2 new): Skeleton (10 HP, weak Fire/Holy, undead), Green Slime (24 HP, DEF 255, weak Fire/Ice, elemental)

### Assets

**Sprites**
- Skeleton sprite
- Green Slime sprite

**VFX**
- Fire spell effect
- Thunder spell effect
- Blizzard spell effect
- Cure spell effect (healing glow)
- Dia spell effect (holy light on undead)
- Buff apply shimmer (generic, tinted per buff type)
- Sleep bubbles (status indicator)
- Darkness cloud (status indicator)
- Silence X (status indicator)

**Audio**
- Fire spell SFX
- Thunder spell SFX
- Blizzard/Ice spell SFX
- Cure/healing spell SFX
- Dia/Holy spell SFX
- Buff cast SFX (Protect, Temper, Blink, Invis)
- Debuff cast SFX (Slow, Dark, Focus)
- Status inflict SFX (Sleep, Silence)
- Shop buy SFX
- Shop theme

**UI**
- Magic command submenu: spell level tabs → spell list → target select
- Magic screen (main menu): learned spells and charge counts per level
- Basic shop buy screen: item list with prices, Gil counter, purchase confirmation
- Status effect icons (Sleep, Darkness, Silence)
- Elemental weakness/resistance popup text

---

## Phase 5 — Status Effects, Consumables & Mid-Level Magic

Adds the remaining 5 status effects (Poison, Stone, Paralysis, Confusion, KO revival), all consumable items, buff stacking, and Lv 3–4 spells — completing combat depth.

- Remaining status effects per SPEC §1.7:
  - KO: revivable via Life spell or Phoenix Down (previously just triggered Game Over)
  - Stone: cannot act; counts as KO for party wipe check; cured by Stona or Gold Needle
  - Poison: lose HP each turn in battle; lose 1 HP per step on field; persists after battle
  - Paralysis: cannot act; temporary, ends after a few turns
  - Confusion: attacks random targets including allies; temporary, broken by hit
- Status persistence rules: KO, Stone, Poison, Darkness, Silence persist after battle; Sleep, Paralysis, Confusion end when battle ends
- Buff stacking: Temper (+14 ATK) can be cast multiple times on same target; stacks with Saber (deferred to Phase 10)
- Haste: doubles a character's number of hits — key buff for boss fights
- All consumable items from SPEC §6.4 functional: Potion (30 HP), Hi-Potion (150 HP), Ether, Phoenix Down (revive 1 HP), Antidote, Eye Drops, Echo Grass, Gold Needle, Remedy (all status), Sleeping Bag, Tent, Cottage
- Tent: partial HP + some charges (world map only)
- Cottage: full HP + all charges (world map only)
- Cornelia item shop functional (reuses buy screen from Phase 4); stocked with all 12 consumable types
- All Lv 3–4 spells (16 spells):
  - White Lv 3: Cura (33–66 HP), NulBlaze (halves Fire), Diara (40–160 undead), Heal (12–24 HP all)
  - White Lv 4: Poisona (cures Poison), NulFrost (halves Ice), Fear (force enemies flee), Vox (cures Silence)
  - Black Lv 3: Fira (30–120 Fire, all), Hold (Paralysis), Thundara (30–120 Lightning, all), Focara (−20 Evade, all)
  - Black Lv 4: Sleepra (Sleep, one), Confuse (Confusion, all), Haste (double hits), Blizzara (40–160 Ice, all)
- Enemies for status testing (2 new): Ghoul (48 HP, weak Fire/Holy, undead), Cobra (56 HP, inflicts Poison)

### Assets

**Sprites**
- Ghoul sprite
- Cobra sprite

**VFX**
- Poison drip (status indicator)
- Stone grey-out (status indicator)
- Confusion stars (status indicator)
- Paralysis spark (status indicator)
- Status cure sparkle
- Fira spell effect (larger Fire)
- Thundara spell effect (larger Thunder)
- Blizzara spell effect (larger Blizzard)

**Audio**
- Status inflict SFX (Poison, Confusion, Paralysis, Stone)
- Status cure SFX
- Item use SFX
- Haste buff SFX
- Fira/Thundara/Blizzara SFX (deeper variants of Lv 1 spells)

**UI**
- Status effect icons (Poison, Stone, Paralysis, Confusion, KO) — adds to 3 from Phase 4 for full set of 8
- Phoenix Down / revive target selection
- Field poison step-damage indicator

---

## Phase 6 — Dungeon Exploration & First Boss

Adds multi-floor dungeons, treasure chests, the minimap, boss encounters with unique AI, and pre-emptive/ambush mechanics — completing the first full gameplay loop.

- Dungeon: Chaos Shrine (2 floors)
- Multi-floor navigation: stairs connecting floors
- Treasure chests: interact to open; contain items, equipment, or Gil
- Minimap: toggleable overlay showing floor layout, explored/unexplored tiles, chest status (opened/unopened count), party position
- Random encounters in dungeons (higher rate than overworld)
- Pre-emptive strike: party acts first; chance based on party Agility vs. enemy Agility
- Ambush: enemies act first, party turned around; reversed Agility comparison
- Boss encounter: Garland (212 HP) at end of Chaos Shrine floor 2
- Garland AI: physical attacks; cannot be fled from; no weakness
- Boss theme music triggers on boss encounter
- Dungeon enemies (2 new): Crazy Horse (20 HP, 10 ATK, beast), Ghoul reused from Phase 5
- Overworld segment: Cornelia → Chaos Shrine route with grass/forest tiles and random encounters
- Key item: Lute received from Princess Sarah after defeating Garland (stored in key item inventory; not usable yet)
- Key item inventory: separate from consumables; view-only for now
- Dialogue trigger: King of Cornelia updates dialogue after Garland is defeated
- Full loop playable: equip in Cornelia → buy spells → walk to Chaos Shrine → fight encounters → defeat Garland → receive Lute → return to Cornelia

### Assets

**Sprites**
- Garland boss sprite (battle)
- Crazy Horse sprite
- Princess Sarah NPC sprite (updated: post-rescue)
- Treasure chest sprite (closed, open)

**Tilemaps**
- Chaos Shrine tileset (stone floors, walls, pillars, altars, stairs)
- Chaos Shrine floor 1 map
- Chaos Shrine floor 2 map (boss room)
- Overworld tileset (grass, forest, mountains, water, paths)
- Overworld segment map: Cornelia → Chaos Shrine

**VFX**
- Treasure chest open sparkle
- Boss entrance flash
- Pre-emptive strike indicator
- Ambush indicator

**Audio**
- Dungeon theme (Chaos Shrine)
- Boss battle theme
- Overworld theme
- Treasure chest open SFX
- Boss encounter sting
- Key item acquired jingle
- Pre-emptive strike SFX
- Ambush SFX

**UI**
- Minimap overlay (floor layout, chest indicators, party marker)
- Minimap toggle (Select button)
- Key item inventory screen (view-only)
- Boss HP: no health bar displayed (player estimates from damage numbers per SPEC §10.4)

---

**Vertical slice checkpoint — Walk through Cornelia, buy gear and Lv 1–4 spells, travel the overworld to the Chaos Shrine, fight random encounters with physical attacks and magic, defeat Garland, receive the Lute, and return to town. All core combat math (multi-hit, crits, elements, status effects, buffs), the spell charge system, and dungeon exploration with minimap are functional. Progress does not persist between sessions yet — save system is Phase 8.**

---

## Phase 7 — Equipment Depth & Economy

Adds full equipment management with special properties, shop buy/sell, the inn as a rest point, and the economy loop that ties towns to dungeons.

- Equipment screen: equip/remove across 5 slots (weapon, shield, body, head, arms); stat comparison display showing ATK/DEF/EVA changes before confirming
- Class-based equipment restrictions: each item checks equippable classes before allowing equip
- Weapon special properties:
  - Elemental damage: weapon element applies to physical attacks; triggers weakness/resistance on target
  - Racial bonus: "Strong vs." multiplier against Dragon, Undead, Were, Giant, Water enemy types
  - Spell-casting weapons: use weapon as item in battle to cast a spell (e.g., Thor's Hammer → Thundara, Healing Staff → Cure)
- Armor special properties:
  - Elemental resistance: halves damage from specific elements
  - Spell-casting armor: use as item to cast spell (e.g., Healing Helm → Heal, Gauntlets → Thundara)
- Absorb/Evade tradeoff: heavier armor increases Absorb, decreases Evade% per SPEC §1.5
- Shop system: extends Phase 4 buy screen with sell screen (sell price = half buy price) and equipment shop categories
- Inn system: rest at inn → full HP + all spell charges restored; cost varies by town (30–300 Gil); inn saving deferred to Phase 8
- Economy validation: Cornelia shop prices match SPEC (Rapier 10 Gil, Leather Armor 50 Gil, Lv 1 spells 50 Gil, Potion 40 Gil)
- Equipment beyond Phase 3 starter gear (new items covering all categories and special types):
  - Swords: Broadsword, Mythril Sword, Flame Sword (Fire element), Ice Brand (Ice element), Coral Sword (Strong vs. Water)
  - Daggers: Mythril Knife
  - Axes: Battle Axe, Mythril Axe
  - Hammers: Mythril Hammer, Thor's Hammer (casts Thundara)
  - Nunchaku: Iron Nunchaku
  - Staves: Healing Staff (casts Cure)
  - Body: Chain Mail, Iron Armor, Copper Armlet, Silver Armlet
  - Shields: Iron Shield, Mythril Shield
  - Helmets: Helm, Great Helm
  - Gloves: Bronze Gloves, Steel Gloves

### Assets

**Sprites**
- Weapon icons (per weapon for inventory/equip screen)
- Armor icons (per armor piece for inventory/equip screen)

**Audio**
- Sell SFX
- Equip SFX
- Inn rest jingle

**UI**
- Equipment screen: 5-slot layout, stat comparison panel, class restriction indicator
- Shop screen: buy list with prices, sell list, Gil counter
- Inn screen: rest confirmation, cost display
- Weapon/armor detail tooltip (ATK/DEF, Hit/Evade, special properties, equippable classes)

---

## Phase 8 — Save System

Adds all persistence: Quick Save, inn save, autosave, multiple save slots, and the title screen load flow — the data model is now stable enough to serialize reliably.

- Save data model: party (4 characters — class, name, level, EXP, stats, equipment, learned spells, spell charges), consumable inventory, key item inventory, Gil, game position (current map + coordinates), progression flags (bosses defeated, NPCs triggered, chests opened)
- Quick Save: save game state at any point from the main menu; creates a suspend-state save; load from title screen
- Inn save: resting at an inn now persists to a save slot in addition to restoring HP/charges
- Autosave: triggers on entering/exiting dungeons and before boss fights
- Multiple save slots: player chooses a slot when saving at an inn; Quick Save uses a dedicated slot
- Title screen update: New Game, Continue (load most recent save), Load (select from save slots)
- Save file integrity: basic validation on load to detect corruption

### Assets

**Audio**
- Autosave indicator SFX

**UI**
- Save slot selection screen (multiple slots, with party summary and playtime per slot)
- Quick Save / Load confirmation prompts
- Autosave icon (brief on-screen indicator)
- Title screen updated: New Game, Continue, Load

---

## Phase 9 — Full Class Roster

Adds the Thief and Red Mage classes and the party creation screen — making all 6 base classes playable with any party composition.

- Party creation screen (New Game): choose 4 characters from 6 classes, assign names; replaces the hardcoded Warrior/Monk/White Mage/Black Mage party from Phase 1
- Two new base classes (Warrior, Monk, White Mage, Black Mage already playable since Phase 1):
  - Thief (30 HP, 5 STR, 15 AGI, 5 VIT, 1 INT, 15 LCK): daggers, light swords, light armor; no magic; highest Agility
  - Red Mage (30 HP, 5 STR, 10 AGI, 5 VIT, 10 INT, 5 LCK): White 1–5, Black 1–5; swords, medium armor; jack-of-all-trades
- All 6 classes use deterministic stat growth per SPEC §4.1; all combat formulas (including Monk unarmed scaling from Phase 3) apply to new classes automatically
- Allow duplicate classes in a party (e.g., 4× Warrior is valid)

### Assets

**Sprites**
- Thief overworld sprite (4-direction walk cycle)
- Red Mage overworld sprite (4-direction walk cycle)
- Thief battle stance sprite
- Red Mage battle stance sprite

**UI**
- Party creation screen: class select grid (6 classes), name input, stat preview per class, party slot display (4 slots)

---

## Phase 10 — Class Change & High-Level Magic

Adds all 6 promoted classes, the class change system, the remaining 40 spells (Lv 5–8), and Intelligence scaling — completing the character progression system. The actual quest to trigger class change (Citadel of Trials + Bahamut) is in Phase 13.

- Class change system: promotes all 4 party members simultaneously when triggered
  - Warrior → Knight (gains White Lv 1–3: Cure, Protect, Blink)
  - Monk → Master (magic evasion roughly doubles; unarmed damage spike)
  - Thief → Ninja (gains Black Lv 1–4 including Haste; equips almost everything)
  - Red Mage → Red Wizard (White/Black Lv 1–7; locked out of Lv 8)
  - White Mage → White Wizard (White Lv 1–8: Holy, Full-Life, NulAll, Dispel)
  - Black Mage → Black Wizard (Black Lv 1–8: Flare, Stop, Kill, Warp)
- Promoted class sprites replace base class sprites on field and in battle
- Promoted equipment access: Ninja equips nearly everything; Knight gains heavy armor access
- Intelligence scaling: affects spell effectiveness; dedicated casters (Black/White Wizard) scale harder than Red Wizard in the late game
- Class change testable via debug trigger; quest content (Citadel of Trials, Rat's Tail, Bahamut) deferred to Phase 13
- All Lv 5–8 spells (40 spells):
  - White Lv 5: Curaga (66–132 HP), Life (revive 1 HP), Diaga (60–240 undead), Healara (24–48 HP all)
  - White Lv 6: Stona (cures Stone), Protera (+12 DEF all), Exit (warp out of dungeon), Invisira (+40 Evade all)
  - White Lv 7: Curaja (full HP), NulDeath (blocks instant death), Diaja (80–320 undead), Healaga (48–96 HP all)
  - White Lv 8: Holy (~80 power, all), NulAll (halves all spell damage), Full-Life (revive full HP), Dispel (remove enemy buffs)
  - Black Lv 5: Firaga (50–200 Fire, all), Scourge (instant death, all), Teleport (previous floor), Slowra (reduce hits, one)
  - Black Lv 6: Thundaga (60–240 Lightning, all), Death (instant death, one), Quake (instant death Earth, all), Stun (Paralysis, one)
  - Black Lv 7: Blizzaga (70–280 Ice, all), Saber (+16 ATK +accuracy, self), Break (Petrify, one), Blind (Darkness, one)
  - Black Lv 8: Flare (~100 power non-elemental, all), Stop (Paralysis, all), Kill (instant death, one), Warp (banish, all)
- Saber buff stacking: stacks with Temper (from Phase 5); primary boss-fight damage strategy

### Assets

**Sprites**
- Knight overworld + battle sprites (promoted Warrior)
- Master overworld + battle sprites (promoted Monk)
- Ninja overworld + battle sprites (promoted Thief)
- Red Wizard overworld + battle sprites (promoted Red Mage)
- White Wizard overworld + battle sprites (promoted White Mage)
- Black Wizard overworld + battle sprites (promoted Black Mage)

**VFX**
- Class change transformation effect (per character)
- Lv 5–8 spell effects: Firaga, Thundaga, Blizzaga, Curaga, Holy, Flare, Life, Full-Life, Scourge, Death, Quake, Break, Stop
- Instant death effect (enemy vanish)

**Audio**
- Class change fanfare
- Lv 5+ spell cast SFX (Firaga, Thundaga, Blizzaga — louder/deeper than Lv 1–3 variants)
- Holy spell SFX
- Flare spell SFX
- Instant death SFX
- Life/Full-Life revive SFX

**UI**
- Class change cutscene overlay: old sprite → new sprite with fanfare

---

## Phase 11 — Overworld & Ship

Adds the full overworld map, the Ship vehicle, and Pravoka as the second town — proving the world scales beyond the Cornelia-to-Chaos-Shrine corridor.

- Full overworld map: single continuous tile map with ocean, land, rivers, mountains, desert
- Walking: land tiles only (default); overworld replaces the Phase 6 segment map
- Ship: unlocked by defeating Bikke's Pirates in Pravoka; ocean traversal, dock at ports
- Ship boarding/disembarking at port tiles
- Random encounters on overworld (lower rate than dungeons)
- Pravoka town: weapon/armor shops (Scimitar 200 Gil, Battle Axe 550 Gil, Iron Shield 100 Gil, Chain Mail 80 Gil), Lv 2 magic shops (250 Gil each), inn
- Bikke's Pirates boss: 9× Pirate (24 HP each) group fight in Pravoka; awards Ship
- Bikke NPC dialogue before and after fight

### Assets

**Sprites**
- Ship sprite (overworld)
- Bikke NPC sprite
- Pirate enemy sprite (×9 group)
- Pravoka townspeople (3 generic NPCs)

**Tilemaps**
- Full overworld map
- Pravoka town map + tileset (port town, docks)

**VFX**
- Ship sailing wake

**Audio**
- Overworld theme (full version, replacing Phase 6 segment)
- Ship sailing theme
- Pravoka town theme
- Ship board/disembark SFX

**UI**
- Vehicle boarding prompt

---

## Phase 12 — Canoe, Airship & Progression Gating

Adds the Canoe and Airship vehicles, the key item system, two more towns with tiered shops, and the progression gating chain — proving that key items, vehicles, and shop tiers scale the world.

- Canoe: river and lake traversal; obtained from Sage Lukahn after defeating Lich — Lich fight is in Phase 13, so Canoe is testable via debug trigger until then
- Airship: fly anywhere, land on grass tiles; obtained by using Levistone at desert — Levistone is in Phase 13 (Ice Cavern), so Airship is testable via debug trigger until then
- Airship takeoff/landing animations
- No encounters while on Airship
- Key item system: extends the view-only inventory from Phase 6 with event triggers — key items now activate when used at specific locations or given to specific NPCs
- Key items implemented (7): Lute (Phase 6), Crown, Crystal Eye, Jolt Tonic, Mystic Key, Canoe, Levistone
- Key item chain: Crown (Marsh Cave, Phase 13) → Astos fight → Crystal Eye → Matoya → Jolt Tonic → Elf Prince → Mystic Key; full chain playable once Phase 13 adds Marsh Cave
- Sealed doors: Mystic Key opens locked rooms in Cornelia Castle, Elfheim Castle, and other locations
- Cornelia Castle update: Mystic Key room containing Nitro Powder; canal opening deferred (no Mt. Duergar content)
- Elfheim town: weapon/armor shops (Mythril Sword 4,000 Gil, Iron Armor 800 Gil, Buckler 2,500 Gil, Great Helm 450 Gil), Lv 3–4 magic shops (1,000–2,500 Gil each), inn
- Crescent Lake town: weapon/armor shops (Mythril Axe 4,500 Gil, Mythril Mail 7,500 Gil, Mythril Shield 2,500 Gil, Mythril Helm 2,500 Gil, Mythril Hammer 2,500 Gil), Lv 5–6 magic shops (4,000–13,000 Gil each), inn

### Assets

**Sprites**
- Canoe sprite (overworld, on rivers)
- Airship sprite (overworld, with shadow)
- Sage Lukahn NPC sprite
- Matoya NPC sprite
- Elf Prince NPC sprite
- Elfheim townspeople (3 generic NPCs)
- Crescent Lake townspeople (3 generic NPCs)

**Tilemaps**
- Elfheim town map + tileset (forest village, castle)
- Crescent Lake town map + tileset (lakeside settlement)

**VFX**
- Airship takeoff/landing
- Sealed door unlock effect (Mystic Key)
- Canoe boarding

**Audio**
- Airship theme
- Elfheim town theme
- Crescent Lake town theme
- Canoe paddle SFX
- Airship engine hum SFX
- Airship takeoff SFX
- Airship landing SFX
- Key item acquired jingle (reuse from Phase 6)
- Sealed door unlock SFX

**UI**
- Key item detail screen (description, obtained location)
- World map indicator (optional: show visited locations)

---

## Phase 13 — Dungeon & Boss Expansion

Adds dungeons, bosses, enemies, and endgame equipment across the power curve. Also wires up the class change quest (Citadel of Trials → Bahamut) and vehicle acquisition triggers that were system-ready since Phases 10 and 12.

- Four dungeons spanning early through endgame:
  - Marsh Cave (3 floors): Crown treasure, Piscodemon boss (4× 84 HP)
  - Terra Cavern (5 floors): Star Ruby, Earth Rod puzzle, Vampire boss (280 HP, weak Fire/Dia), Lich boss (1,200 HP, weak Fire/Dia) — Earth Crystal restoration; defeating Lich grants Canoe (Phase 12 vehicle now obtainable)
  - Citadel of Trials (3 floors, teleporter puzzles): Rat's Tail treasure; Dragon Zombie boss (weak Fire/Dia, undead)
  - Chaos Shrine Past (4 floors): Lich rematch (2,800 HP, weak Holy), Chaos final boss (20,000 HP, 170 ATK, 100 DEF; self-heals with Curaga; casts Flare, Blaze, Tsunami, Earthquake)
- Class change quest: Rat's Tail (Citadel of Trials) → Bahamut on Cardia Islands → triggers class change system from Phase 10
- Lute functionality: used at Chaos Shrine to open the time portal to the Past floors
- Levistone in Ice Cavern (single-floor mini-dungeon or placed in Terra Cavern for scope) → Airship now obtainable
- Area-specific encounter tables for each dungeon
- Additional enemies (14 new, covering all enemy types):
  - Beast: Werewolf (68 HP), Ogre (100 HP), Nightmare (120 HP)
  - Undead: Shadow (50 HP), Vampire Lord (300 HP)
  - Elemental: Earth Elemental (228 HP), Fire Elemental (276 HP, weak Ice)
  - Giant: Minotaur (164 HP), Hill Gigas (240 HP), Ogre Mage (144 HP)
  - Dragon: Red Dragon (248 HP, weak Ice)
  - Mage-type: Piscodemon (boss), Mindflayer (128 HP), Medusa (68 HP, inflicts Stone)
- Late-game equipment (dungeon drops — items already in Phase 7/12 shops not re-listed):
  - Swords: Falchion, Werebane (Strong vs. Were), Defender (casts Blink), Sun Blade (Strong vs. Undead), Excalibur (Strong vs. all, Knight-only), Masamune (56 ATK, all classes)
  - Axes: Light Axe (casts Diara, Strong vs. Undead)
  - Staves: Mage's Staff, Spellbinder (casts Confuse)
  - Body: Flame Mail (resist Fire), Ice Armor (resist Ice), White Robe (resist Ice/Death), Black Robe (resist Fire, boost spell power)
  - Shields: Flame Shield (resist Fire), Ice Shield (resist Ice), Aegis Shield (resist elemental magic, Knight-only)
  - Helmets: Ribbon (prevents all status effects)
  - Gloves: Gauntlets (casts Thundara), Protect Ring (resist Death, all classes)
- Treasure chests in all dungeons containing Gil, equipment, and consumables
- Economy validation: enemies in Terra Cavern drop 200–900 Gil; Chaos Shrine Past enemies drop 2,000–4,000 Gil; Lv 7–8 spells cost 30,000–40,000 Gil

### Assets

**Sprites**
- Piscodemon sprite (×4 group boss)
- Vampire boss sprite
- Lich boss sprite
- Dragon Zombie sprite
- Chaos boss sprite
- Bahamut NPC sprite
- Nightmare sprite
- Medusa sprite
- Werewolf sprite
- Ogre sprite
- Shadow sprite
- Vampire Lord sprite
- Earth Elemental sprite
- Fire Elemental sprite
- Minotaur sprite
- Hill Gigas sprite
- Ogre Mage sprite
- Red Dragon sprite
- Mindflayer sprite

**Tilemaps**
- Marsh Cave tileset (dark stone, water, poison pools)
- Marsh Cave floors 1–3
- Terra Cavern tileset (earth tones, rock, lava edges)
- Terra Cavern floors 1–5 (including Vampire room and Lich boss floor)
- Citadel of Trials tileset (stone halls, teleporter pads, treasure rooms)
- Citadel of Trials floors 1–3
- Cardia Islands map segment (Bahamut's cave)
- Chaos Shrine Past tileset (warped stone, dark atmosphere, crystal motifs)
- Chaos Shrine Past floors 1–4 (Lich rematch room, Chaos throne room)

**VFX**
- Lich boss spell effects (elemental attacks)
- Chaos boss special attacks: Blaze (fire wave), Tsunami (water wave), Earthquake (screen shake + cracks)
- Chaos Curaga self-heal effect
- Time portal effect (Lute activation at Chaos Shrine)
- Earth Crystal restoration effect

**Audio**
- Marsh Cave dungeon theme
- Terra Cavern dungeon theme
- Citadel of Trials dungeon theme
- Bahamut theme/sting
- Chaos Shrine Past dungeon theme
- Final boss theme (Chaos — unique track)
- Lich boss encounter sting
- Chaos encounter sting
- Chaos special attack SFX (Blaze, Tsunami, Earthquake)
- Crystal restoration jingle
- Time portal SFX

**UI**
- Crystal restoration cutscene overlay

---

## Phase 14 — Side Systems & Quality of Life

Adds bestiary tracking, all boost options, auto-battle, battle speed control, the 15 Puzzle minigame, and the extras menu — completing the feature set.

- Bestiary: tracks every enemy encountered; displays sprite, name, stats, element/status info, EXP/Gil; accessible from title screen Extras menu; completion tracking (X / total encountered)
- Boost menu (Config): EXP multiplier ×1–×4, Gil multiplier ×1–×4, encounter toggle on/off
- Auto-battle: toggle that repeats previous round's commands automatically each turn
- Battle speed: adjustable slider (affects animation and turn resolution speed)
- Music Player (Extras menu): unlocks tracks as player progresses; both rearranged and NES versions selectable
- Art Gallery (Extras menu): unlocks illustrations at progression milestones
- 15 Puzzle minigame: accessible on the Ship; sliding tile puzzle; awards Gil on completion
- Font toggle (Config): Modernized vs. Classic pixelized typeface
- Soundtrack toggle (Config): Rearranged vs. Original NES
- Title screen Extras menu: Bestiary, Music Player, Art Gallery

### Assets

**Audio**
- 15 Puzzle theme
- 15 Puzzle tile slide SFX
- 15 Puzzle completion jingle
- Bestiary page flip SFX

**UI**
- Bestiary screen: enemy list, detail view (sprite, stats, weaknesses, drops)
- Bestiary completion counter
- Music Player screen: track list, play/stop, rearranged/NES toggle
- Art Gallery screen: thumbnail grid, full-screen view
- 15 Puzzle screen: tile grid, move counter, Gil reward display
- Boost menu: EXP/Gil multiplier sliders, encounter toggle, auto-battle toggle, battle speed slider
- Font toggle in Config
- Soundtrack toggle in Config
