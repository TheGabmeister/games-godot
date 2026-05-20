# Pokémon FireRed — Phased Implementation Plan

20 phases. Pokémon FireRed has an unusually high number of interlocking systems (17-type chart, 76 abilities, 386 species, breeding, Safari Zone, etc.) that justify the count.

---

## Phase 1 — Overworld & Tile Movement

The foundation: a walkable tile-based world with player movement, collision, and map transitions.

- Top-down 2D tile grid. Fixed camera centered on the player character.
- 4-directional movement on D-Pad. One tile per step. Walking animation (4-frame cycle per direction).
- Hold B to run (×2 walking speed). Running requires the Running Shoes flag — set to true by default in the debug level; gated behind an NPC event in the real game.
- Tile collision: solid tiles (walls, water, objects), walkable tiles (ground, paths), and special tiles (tall grass, ledges). Ledges allow one-way downward jumping.
- Map transitions: walking off a map edge or onto a door/cave entrance tile loads the connected map. Interior/exterior transitions use a fade.
- Location banner: briefly displays the area name when entering a new zone.
- Debug level: a small test town ("Debug Town") with ~20×20 tiles — a few buildings (interiors with doors), a fence perimeter, one route exit leading to a grassy area (~15×25), and a cave entrance to a small 10×10 cave room. Includes solid walls, ledges, tall grass patches, and water tiles (not yet traversable).

### Assets

**Sprites**
- Player character (Red) — walk cycle (4 frames × 4 directions), run cycle (4 frames × 4 directions), idle (4 directions)
- Player character (Leaf) — same set

**Tilemaps**
- Exterior tileset: grass, path, tall grass, water, ledge, trees, fence, building faces, route signs
- Interior tileset: floor, walls, doors, tables, shelves, rugs
- Cave tileset: rock floor, walls, stalagmites
- Debug Town map, Debug Route map, Debug Cave map

**Audio**
- Town BGM (placeholder)
- Route BGM (placeholder)
- Cave BGM (placeholder)
- Footstep SFX (walk, run)
- Door transition SFX
- Ledge jump SFX

---

## Phase 2 — Dialogue & Menu Framework

NPCs become interactive and the Start Menu provides the shell for all future screens.

- Text box at bottom of screen. Text renders character-by-character at configurable speed (Slow / Mid / Fast).
- A advances text. B fast-forwards to end of current block. Text boxes auto-close or wait for A depending on context.
- Yes/No choice prompts.
- NPC interaction: face NPC on A press, display dialogue. NPCs have idle facing directions; turn to face the player when spoken to.
- Sign/object examination on A press.
- Start Menu: opens a vertical list. Initially contains: POKéMON (placeholder), BAG (placeholder), [PLAYER NAME], SAVE (placeholder), OPTIONS. Placeholders show "Not yet available" text.
- Options screen: Text Speed (Slow/Mid/Fast), Battle Scene (On/Off), Battle Style (Shift/Set), Sound (Mono/Stereo), Button Mode (Normal/LR/L=A). Settings persist in memory (save to disk deferred to Phase 14).
- Trainer Card stub: shows player name, ID number, play time counter, money (¥0 for now).
- Debug level update: 3 NPCs added to Debug Town — one with multi-line dialogue, one with a Yes/No question, and a sign to read. One building interior with an NPC inside.

### Assets

**Sprites**
- NPC overworld sprites — 3 generic types (male, female, old man), idle + turn animations
- Sign/examine indicator sprite

**UI**
- Text box frame (9-slice)
- Start Menu frame and cursor
- Options screen layout
- Trainer Card layout
- Yes/No prompt box

**Audio**
- Menu open/close SFX
- Text blip SFX (per character)
- Cursor move SFX
- Confirm SFX
- Cancel SFX

---

## Phase 3 — Pokémon Data & Party System

The Pokémon data model is the backbone of every system that follows.

- Species data table: each of the 151 Kanto species defined with Pokédex number, name, types (1–2 from the 17-type set), base stats (HP/Atk/Def/SpA/SpD/Spe), growth rate group, catch rate, base EXP yield, EV yield, egg groups, egg cycles, gender ratio, ability pool (1–2), learnset (level-up moves), TM/HM compatibility, evolution conditions, Pokédex entry text, height, weight.
- Move data table: each of the 354 Gen III moves defined with name, type, power (0 for status moves), accuracy (0 = always hit), base PP, priority bracket (−6 to +5), effect ID (damage, status infliction, stat change, multi-turn, recoil, recovery, OHKO, self-KO, protection, etc.), target (single foe, all foes, self, ally, etc.), contact flag, and secondary effect chance.
- Individual Pokémon instance: species, nickname, level, current EXP, IVs (6 × 0–31, random), EVs (6 × 0–255, 510 cap), nature (1 of 25), ability (from species pool), gender, 4 move slots (move ID + current PP + max PP), held item slot (empty for now — items in Phase 8), friendship (0–255, starts at species base), OT name, OT ID, status condition, current HP.
- Stat calculation formulas (SPEC §1.6): HP formula and non-HP formula with base, IV, EV, level, nature.
- Party: array of up to 6 Pokémon. Party lead determines overworld ability effects and Repel threshold (deferred to later phases).
- Party menu (accessible from Start Menu → POKéMON): displays all party members with sprite, name, level, HP bar, status icon. Select a Pokémon to open sub-menu: Summary, Switch, Cancel.
- Summary screen: 3 pages. Page 1: Pokémon info (name, species, type, OT, ID, nature). Page 2: stats (HP, Atk, Def, SpA, SpD, Spe — calculated values, plus EV sparkle indicator). Page 3: moves (4 moves with type, PP, category icon).
- Representative data set (minimum for testing): 3 starters (Bulbasaur, Charmander, Squirtle) + their evolutions (9 total) + Pidgey/Pidgeotto/Pidgeot + Rattata/Raticate + Pikachu + Geodude + Abra + Magikarp + Caterpie = ~20 species with complete data.
- Debug level update: player starts with a pre-built party of 3: Charmander (Lv 5), Pidgey (Lv 3), Rattata (Lv 4). Party menu wired into Start Menu.

### Assets

**Sprites**
- Pokémon front sprites — ~20 species (representative set above)
- Pokémon back sprites — same ~20 species
- Pokémon party icons (32×32) — same ~20 species
- Type icons — 17 types

**UI**
- Party menu layout (6 slots with HP bars)
- Summary screen (3 pages with stat bars, type badges, move list)
- Nature indicator text
- Status condition icons (BRN, PSN, PAR, SLP, FRZ, TOX — used in later phases, defined here for the data model)

---

## Phase 4 — Turn-Based Battle Engine

The core combat system — action selection, damage calculation, turn resolution, and the battle HUD.

- Battle initiation: transition from overworld to battle scene (screen flash + slide-in).
- Battle HUD: player's Pokémon info box (bottom-right: name, level, gender, HP bar with numbers, EXP bar), opponent's info box (top-left: name, level, gender, HP bar without numbers). HP bar color: green >50%, yellow 21–50%, red ≤20%.
- Action menu: FIGHT / BAG / POKéMON / RUN (2×2 grid). BAG is non-functional (items in Phase 8). RUN triggers flee formula (SPEC §1.12).
- FIGHT sub-menu: list of 4 moves with PP counts and type on highlight.
- Turn resolution: both sides select actions. Priority order: switches/items before attacks (Phase 8/10); among attacks, move priority bracket (SPEC §1.2), then Speed stat, then random 50/50 tie-break.
- Damage formula (SPEC §1.3): `(((2×Level/5+2)×Power×A/D)/50+2) × STAB × Type1 × Type2 × Random/100`. Truncated integer division. Physical types use Atk/Def; Special types use SpA/SpD (SPEC §1.2 table). STAB = 1.5 if move type matches user's type. Type effectiveness per the 17-type chart (SPEC §1.5).
- Critical hits (SPEC §1.4): Stage 0 = 1/16 chance. 2× damage. Ignores attacker's negative stages and defender's positive stages.
- Accuracy check (SPEC §1.6): `HitChance = MoveAccuracy × AccuracyStage / EvasionStage`. Random in [0, 99] < HitChance → hit. Always-hit moves bypass check.
- PP deduction: −1 PP on move use. At 0 PP, move is unselectable. If all moves at 0 PP, use Struggle (typeless, 50 power, 1/4 recoil).
- Fainting: Pokémon at 0 HP faints. Player prompted to send next Pokémon. If all party members fainted, "whited out" → return to last Pokémon Center (Debug Town for now) with full heal, lose half money (¥0 for now).
- Switching: select from party → swap active Pokémon. Costs the player's action for that turn.
- Wild battle end conditions: opponent faints (victory), player flees, player whites out.
- Battle end: EXP gain placeholder (calculated in Phase 6). Return to overworld.
- Debug level update: a debug NPC in Debug Town triggers a wild battle against a random Pidgey/Rattata (Lv 3–5) for testing without needing the encounter system.

### Assets

**Sprites**
- Battle scene background — grass field
- Pokémon battle positions (back sprite left, front sprite right) — using sprites from Phase 3
- Battle action cursor

**VFX**
- Battle transition (screen flash + wipe)
- HP bar drain animation
- Basic attack animation (generic hit flash — unique move animations deferred)
- Fainting animation (sprite sinks and fades)
- Critical hit screen flash

**UI**
- Battle HUD: player info box, opponent info box
- Action menu (FIGHT/BAG/POKéMON/RUN)
- Move selection overlay (4 moves + PP + type)
- "What will [Pokémon] do?" prompt
- Effectiveness text ("It's super effective!", etc.)
- Switch prompt on faint

**Audio**
- Wild battle BGM
- Battle victory fanfare
- Attack hit SFX
- Critical hit SFX
- HP bar drain SFX
- Low HP warning beep (loops when ≤20% HP)
- Pokémon cry SFX — ~20 species (representative set)
- Faint SFX

---

## Phase 5 — Wild Encounters & Catching

Walking through tall grass now triggers battles, and the player can catch wild Pokémon.

- Encounter system: each step on a tall grass / cave / surf tile rolls against the area's encounter rate (~4.5% per step for standard grass). On trigger, select a Pokémon from the area's 10-slot weighted encounter table (each slot has a species, level range, and encounter probability percentage).
- Catch system: BAG → Poké Balls pocket in battle. Throw ball → catch formula (SPEC §1.11). Modified catch rate `a`, shake probability `b`, four shake checks. Ball shake animation (0–3 shakes before break-out or catch). Caught Pokémon: nickname prompt → added to party (or sent to PC if party full — PC not yet built, so party of 6 max enforced; overflow message "Party full!" for now, PC in Phase 12).
- Ball types available for testing: Poké Ball (1×), Great Ball (1.5×), Ultra Ball (2×). Player starts with 10 of each in debug. Master Ball available as debug item (guaranteed catch).
- Status catch bonus: Sleep/Freeze = 2×, Paralysis/Poison/Burn = 1.5×, None = 1×. Status system not yet built (Phase 7); catch formula handles the modifier slot with 1× for now.
- Flee formula (SPEC §1.12): `EscapeOdds = (LeadSpeed × 128 / WildSpeed) + 30 × Attempts`. Run Away ability and Smoke Ball guarantee escape (ability/item systems in later phases).
- Repel system: Repel (100 steps), Super Repel (200 steps), Max Repel (250 steps). Suppresses encounters with wild Pokémon whose level < party lead's level. Step counter displayed on expiration ("Repel's effect wore off!"). Items not yet purchasable — debug inventory includes 5 of each.
- Pokédex registration: on catch or battle (seen vs. caught flags). Pokédex data stored per species. Full Pokédex UI deferred to Phase 15; basic "registered" message displayed on first catch.
- Encounter table for Debug Route: Pidgey (Lv 2–5, 40%), Rattata (Lv 2–4, 40%), Pikachu (Lv 3–5, 10%), Caterpie (Lv 3–5, 10%).
- Debug level update: Debug Route tall grass is now functional with encounters. Debug Cave has a cave encounter table: Geodude (Lv 7–9, 50%), Zubat (Lv 6–8, 50%). Add Zubat to species data.

### Assets

**Sprites**
- Poké Ball sprite (overworld item ball)
- Poké Ball, Great Ball, Ultra Ball, Master Ball — item icons
- Zubat front + back sprite (new species for cave testing)

**VFX**
- Ball throw arc animation
- Ball shake animation (1–3 shakes + click or break-out)
- Catch success sparkle
- Wild encounter screen flash (tall grass, cave, water variants)
- Pokémon appearance animation (wild Pokémon "sent out" from grass)

**UI**
- Ball selection in Bag → Poké Balls pocket
- Nickname prompt screen (keyboard entry)
- "Gotcha! [Pokémon] was caught!" text
- "Party full!" overflow message

**Audio**
- Ball throw SFX
- Ball shake SFX
- Ball click (catch success) SFX
- Ball break-out SFX
- Catch jingle
- Repel expiry SFX
- Pokémon cry — Zubat (new)

---

## Phase 6 — EXP, Leveling & Evolution

Pokémon grow stronger through battle, learn new moves, and evolve.

- EXP gain formula (SPEC §1.7): `EXP = a × b × L / 7 × e × t`. `a` = 1 wild / 1.5 trainer (trainers in Phase 10; use 1 for now). `b` = base EXP yield. `L` = defeated Pokémon's level. `e` = Lucky Egg (1 for now; item in Phase 8). `t` = trade bonus (1 for now; relevant when trading exists). Extends Phase 4 battle end: EXP awarded to battling Pokémon on opponent faint.
- EXP bar in battle HUD: fills after victory. If enough EXP to level up, bar fills, level-up triggers, bar resets and fills remainder.
- Level-up: stat recalculation using formulas from Phase 3. Stat increase display ("HP went up by 3!"). Check for new moves at the new level.
- Move learning: if the species learns a move at the new level, prompt to learn it. If <4 moves, learn automatically. If 4 moves, show all 4 + the new move, prompt which to forget or cancel learning.
- Six growth rate curves (SPEC §1.7): Erratic, Fast, Medium Fast, Medium Slow, Slow, Fluctuating. Each uses its formula to determine total EXP for a given level.
- Level-up evolution: when a Pokémon reaches its evolution level (e.g., Charmander Lv 16 → Charmeleon), trigger evolution sequence. Evolution animation (sprite morphs). Stat recalculation for new species base stats. New species may learn a move at level 1 of evolved form. Player can cancel evolution by pressing B.
- Stone evolution: system logic implemented. Selecting an evolution stone from Bag (Phase 8) on a compatible Pokémon triggers evolution. Stones not yet obtainable — 1 Fire Stone, 1 Water Stone, 1 Thunder Stone placed in debug inventory for testing.
- Friendship evolution: system logic implemented. Friendship tracking active per SPEC §4.7 gain/loss table. On level-up, if friendship ≥ 220 and species has a friendship evolution, trigger evolution. Testable by debug-setting friendship to 219, then leveling up.
- Trade evolution: system logic only — triggers on trade receipt. No trade system yet; untestable until connectivity exists. Noted as deferred.
- Debug level update: debug party Charmander changed to Lv 14 (2 levels from evolution) for quick evolution testing. Add Bulbasaur (Lv 15) and Squirtle (Lv 15) to party for evolution variety. Wild Pokémon levels raised to Lv 8–12 for meaningful EXP gain.

### Assets

**VFX**
- Evolution animation (white glow, sprite morph, sparkle burst)
- Level-up stat display overlay
- EXP bar fill animation (extends Phase 4 battle HUD)

**UI**
- Move learning prompt ("wants to learn [move]!")
- Move forget selection screen (4 current moves + new move, with type/power/PP)
- Evolution cancel prompt
- "Congratulations! Your [Pokémon] evolved into [species]!" text

**Audio**
- Level-up jingle
- Evolution BGM
- Evolution success jingle
- Move learn SFX
- New move confirmation SFX

---

**Vertical slice checkpoint — The player can walk around Debug Town and Debug Route, encounter wild Pokémon in tall grass and caves, battle them with the full damage formula (type effectiveness, STAB, crits), catch them with Poké Balls, gain EXP, level up, learn new moves, and evolve Pokémon. No items beyond balls and Repels, no trainers, no shops, no saving — progress is lost on exit. Status effects, abilities, weather, and held items are not yet functional.**

---

## Phase 7 — Status Effects & Stat Stages

Battles gain strategic depth through status conditions, volatile effects, and stat manipulation.

- Non-volatile status conditions (SPEC §1.8): Burn (1/8 HP/turn, physical damage halved), Poison (1/8 HP/turn, 1 HP per 4 overworld steps), Bad Poison/Toxic (1/16 scaling, resets on switch), Paralysis (25% speed, 25% full paralysis), Sleep (2–5 turns, wake and act same turn), Freeze (20% thaw/turn, thaw on Fire hit or Flame Wheel/Sacred Fire). Only one non-volatile status at a time; attempt to inflict a second fails.
- Type immunities to status: Fire immune to Burn (from Fire moves), Poison/Steel immune to Poison, Electric immune to Paralysis, Ice immune to Freeze.
- Volatile statuses (SPEC §1.8): Confusion (1/3 self-hit, 1–4 turns, 40-power typeless physical self-damage), Flinch (skip action, requires moving second), Infatuation (50% action failure, opposite gender), Trapped (cannot switch; damage traps deal 1/16/turn), Leech Seed (1/8 HP drain to planter, Grass immune), Encore (lock last move 2–6 turns), Taunt (no status moves 2 turns), Curse-Ghost (1/4 HP/turn).
- Stat stages (SPEC §1.6): −6 to +6 for Atk, Def, SpA, SpD, Spe, Accuracy, Evasion. Multipliers: 2/(2+stage) for negatives, (2+stage)/2 for positives. Moves like Swords Dance (+2 Atk), Growl (−1 Atk), Agility (+2 Spe). Stat stage changes display in battle text. Stages reset on switch-out.
- Status condition display: icon next to Pokémon name in battle HUD and party menu.
- End-of-turn processing order: weather damage (deferred to Phase 11), status damage (Burn, Poison, Toxic, Leech Seed, Trapped, Curse), held item effects (Phase 8).
- Side conditions: Light Screen (halves Special damage to user's side for 5 turns), Reflect (halves Physical damage to user's side for 5 turns). Wires the Screen modifier slot in the Phase 4 damage formula. Safeguard (blocks status moves for 5 turns), Mist (blocks stat reductions for 5 turns).
- Extends Phase 5 catch formula: status bonus now functional (Sleep/Freeze = 2×, PAR/PSN/BRN = 1.5×).
- Debug level update: representative status moves added to test species movesets — Thunder Wave (PAR), Will-O-Wisp (BRN), Toxic (TOX), Sleep Powder (SLP), Confuse Ray (Confusion), Swords Dance (+2 Atk), Growl (−1 Atk). Add Reflect and Light Screen to Geodude's moveset for screen testing.

### Assets

**VFX**
- Burn animation (flames on Pokémon)
- Poison animation (purple bubbles)
- Paralysis animation (yellow sparks)
- Sleep animation (Zzz)
- Freeze animation (ice block overlay)
- Confusion animation (spinning birds)
- Stat raise animation (arrow up + sparkle)
- Stat drop animation (arrow down + dim)

**UI**
- Status condition icons in battle HUD (BRN, PSN, PAR, SLP, FRZ) — extends Phase 4 info boxes
- Status condition icons in party menu — extends Phase 3

**Audio**
- Status infliction SFX (per status type)
- Status damage tick SFX (Burn, Poison)
- Full paralysis SFX ("fully paralyzed!")
- Wake up SFX
- Thaw SFX

---

## Phase 8 — Inventory & Item System

The Bag becomes functional with full item management and held item effects.

- 5-pocket Bag (SPEC §6.1): Items, Key Items, Poké Balls, TMs & HMs, Berries. Navigate between pockets with L/R. Scroll item list, select to Use/Give/Toss.
- Item use from Bag in overworld: healing items (Potion +20 HP through Full Restore, status cures, Revive, Max Revive — all values per SPEC §6.2). PP items: Ether (+10 PP one move), Max Ether (full PP one move), Elixir (+10 PP all moves), Max Elixir (full PP all moves).
- Item use in battle: extends Phase 4 BAG action. Healing items, status cures, Revive. Battle items: X Attack (+1 Atk stage), X Defend (+1 Def), X Speed (+1 Spe), X Special (+1 SpA), X Accuracy (+1 Acc), Dire Hit (+1 crit stage), Guard Spec. (prevents stat reduction 5 turns). Using an item consumes the player's turn.
- Held items: assign from party menu (Give/Take). Held item effects that activate in battle: Leftovers (1/16 HP/turn), Shell Bell (1/8 damage dealt healed), Choice Band (1.5× Atk, locked to one move), Scope Lens (+1 crit stage), King's Rock (10% flinch), Quick Claw (20% move first), Focus Band (10% survive KO at 1 HP), Bright Powder (−10% opponent accuracy), Macho Brace (2× EV gain, 0.5× Speed in battle), Lucky Egg (1.5× EXP — extends Phase 6 formula), Soothe Bell (1.5× friendship gains — extends Phase 6 friendship), Amulet Coin (2× prize money — wired in Phase 10), Smoke Ball (guaranteed flee), EXP Share (holder gets 50% EXP — extends Phase 6), Sitrus Berry (restore 30 HP at <50%), Lum Berry (cure any status once). Consumed berries/items disappear after use.
- Vitamins: HP Up, Protein, Iron, Calcium, Zinc, Carbos — each grants +10 EVs to respective stat, max 100 EVs per stat from vitamins. Rare Candy: +1 level.
- Item pickup: item balls on the ground (interact to add to Bag). Hidden items (invisible, found with Itemfinder key item — Itemfinder logic: buzzes when near a hidden item, gives direction).
- Evolution stones: Fire Stone, Water Stone, Thunder Stone, Leaf Stone, Moon Stone. Use on compatible Pokémon from Bag to trigger evolution (extends Phase 6 stone evolution).
- Key Items pocket: stores non-discardable story items. Poké Flute, Silph Scope, Bicycle, etc. — data entries defined, acquisition deferred to Phase 16+.
- Select button registers a key item for quick use (extends Phase 1 controls).
- Debug level update: debug Bag pre-loaded with 20 Potions, 10 Super Potions, 5 Full Heals, 5 Revives, 3 each of X Attack/X Speed, 1 each evolution stone, 5 Leftovers, 5 Sitrus Berries. An item ball on Debug Route containing a Rare Candy.

### Assets

**Sprites**
- Item icons for all items listed above (~50 icons)
- Overworld item ball sprite (Poké Ball on ground)
- Hidden item sparkle (Itemfinder response)

**UI**
- Bag screen: 5-pocket tabs, scrollable item list, item description panel
- Use/Give/Toss sub-menu
- Held item indicator on party summary (extends Phase 3)
- "Used [Item]!" battle text
- Item quantity display

**Audio**
- Item use SFX (healing, status cure, vitamin, battle item)
- Item pickup SFX
- Berry consumed SFX
- Itemfinder ping SFX

---

## Phase 9 — Shops & Town Services

The player can now buy, sell, heal, and manage money.

- Poké Mart: NPC shopkeeper triggers buy/sell screen. Buy screen: scrollable item list with prices, quantity selector, purchase confirmation, money deduction. Sell screen: scrollable Bag contents with sell prices (50% of buy price), quantity selector, sell confirmation, money added.
- Currency: Pokémon Dollars (¥). Max wallet ¥999,999. Starting money: ¥3,000 (debug). Displayed on Trainer Card (extends Phase 2) and buy/sell screens.
- Mart inventories vary by location (SPEC §8.2). Debug Town mart stocks: Poké Ball (¥200), Great Ball (¥600), Potion (¥300), Super Potion (¥700), Antidote (¥100), Parlyz Heal (¥200), Repel (¥350), Escape Rope (¥550).
- Premier Ball bonus: buy 10+ Poké Balls → receive 1 free Premier Ball.
- Pokémon Center: nurse NPC interaction triggers heal sequence — "We'll restore your Pokémon to full health" → jingle plays → party fully healed (HP, PP, status cured). Serves as the respawn point on white-out (extends Phase 4 faint logic).
- Pokémon Center is the white-out return point. Last-visited Center is tracked.
- Treasure items: Nugget (sell ¥5,000), Big Pearl (¥3,750), Star Piece (¥4,900), Big Mushroom (¥2,500). Found in the field; sell-only.
- Debug level update: add a Poké Mart NPC and a Pokémon Center nurse to Debug Town. Center has a PC terminal (non-functional — PC in Phase 12). One Nugget hidden on Debug Route.

### Assets

**Sprites**
- Mart shopkeeper NPC sprite
- Nurse NPC sprite
- Poké Mart counter/shelves tilemap addition
- Pokémon Center interior tilemap (counter, healing machine, PC terminal)

**VFX**
- Pokémon Center heal animation (balls on tray glow)

**UI**
- Buy screen (item list, price, quantity, total, player money)
- Sell screen (Bag items, sell price, quantity, total)
- Money display (¥ symbol + amount)

**Audio**
- Shop BGM
- Buy/sell SFX (register cha-ching)
- Pokémon Center heal jingle
- "Thank you! Come again!" SFX/jingle

---

## Phase 10 — Trainer Battles & AI

Fixed NPC trainers challenge the player, creating the game's primary income and difficulty progression.

- Trainer encounter: NPCs with a "trainer" flag. When player enters line-of-sight (1–5 tiles ahead, depending on class), trainer walks toward player, exclamation mark appears, pre-battle dialogue triggers, then battle starts.
- Trainer battle differences from wild: no fleeing, no catching. Opponent sends replacement Pokémon on faint. Battle ends when all of one side's Pokémon faint.
- Prize money on victory: `base payout × level of trainer's last Pokémon`. Amulet Coin doubles this (extends Phase 8 held item).
- Trainer defeated flag: each trainer has a unique flag. Once defeated, they do not re-trigger. Their overworld sprite remains but they give post-battle dialogue instead.
- VS Seeker (key item): use in overworld to scan for re-battlable trainers. Trainers within range who can rematch get an "!" indicator. Requires 100 steps to recharge. Only works outdoors.
- Trainer AI (SPEC §7.4): scoring system with flags per trainer. Level 0: avoids useless moves. Level 1: damage-type awareness. Level 2: KO consideration. Level 3: status priority turn 1. Level 4: secondary effect weighting. Level 8: HP-percentage-based decisions. Each trainer has an assigned AI level.
- Rival Blue: first battle at Lv 5 (starter with type advantage over player's choice). Debug trigger: NPC in Debug Town initiates rival battle with a Lv 5 Squirtle (assumes player has Charmander).
- Trainer battle HUD: extends Phase 4 — opponent's remaining Pokémon shown as ball icons (full/fainted/status). Trainer sprite displayed before battle alongside name and class.
- Trainer class sprites: Bug Catcher, Youngster, Lass, Hiker, Rocket Grunt — 5 representative classes for testing.
- EXP gain in trainer battles: `a` = 1.5 (extends Phase 6 formula).
- Battle Style option (SPEC §11.5): in Shift mode, player is prompted to switch after KOing an opponent's Pokémon ("Trainer is about to send out [Pokémon]. Will you switch?"). Set mode skips this prompt. Option configured in Phase 2 Options screen.
- Double battles (SPEC §1.2): a few scripted trainer fights use 2v2 format. Both sides field 2 Pokémon simultaneously. Targeting: most moves target one foe (player selects which), spread moves hit both foes at 0.5× damage. Helping Hand boosts partner's move power. Turn order resolves all 4 actions by priority/speed. Doubles-specific mechanics: move target validation, partner interaction (no hitting your own partner except spread moves), faint replacement mid-turn. Triggered by specific trainer flags; no wild double battles.
- Debug level update: 3 trainers placed on Debug Route — Bug Catcher (Lv 6 Caterpie, AI 0), Youngster (Lv 7 Rattata, AI 1), Lass (Lv 8 Pidgey + Lv 8 Pikachu, AI 2). Rival NPC in Debug Town.

### Assets

**Sprites**
- Trainer class overworld sprites (5 classes) — idle + walk
- Trainer class battle portraits (5 classes) — full-body art for pre-battle display
- Rival Blue — overworld sprite + battle portrait
- Exclamation mark indicator
- VS Seeker item icon
- Trainer Pokémon ball icons (in HUD: healthy / fainted / status)

**UI**
- Trainer pre-battle splash (trainer sprite + name + class)
- Trainer Pokémon remaining indicators (extends Phase 4 battle HUD)
- Shift-mode switch prompt
- Prize money display ("Got ¥[amount] for winning!")
- VS Seeker recharge indicator

**Audio**
- Trainer battle BGM (distinct from wild battle)
- Trainer encounter SFX (exclamation + walk-up)
- Victory fanfare (trainer variant)
- Rival encounter BGM
- VS Seeker use SFX

---

## Phase 11 — Abilities & Weather

Every Pokémon gains a passive ability, and weather transforms the battlefield.

- Ability system: each Pokémon instance has one ability from its species' pool (1–2 options, selected at generation). Ability displayed on Summary screen (extends Phase 3).
- Battle abilities — on-switch-in: Intimidate (−1 Atk to foe), Trace (copy foe's ability), Drought/Drizzle (set weather permanently — relevant for imported Groudon/Kyogre). On-damage-received: Flash Fire (immune to Fire, 1.5× own Fire moves), Levitate (immune to Ground), Thick Fat (0.5× Fire/Ice damage), Water Absorb/Volt Absorb (immune, heal 1/4 HP), Sturdy (immune to OHKO moves). Passive: Speed Boost (+1 Spe/turn), Huge Power/Pure Power (2× Atk), Guts (1.5× Atk when statused, ignore Burn penalty), Natural Cure (cure status on switch-out), Battle Armor/Shell Armor (immune to crits). Full 76 abilities implemented per SPEC §1.10.
- Overworld abilities: Pickup (chance to find items post-battle), Synchronize (50% chance wild Pokémon matches user's nature — extends Phase 5 encounter), Illuminate/Arena Trap (increase encounter rate), Stench/White Smoke (decrease encounter rate), Flame Body/Magma Armor (halve egg cycles — relevant in Phase 18), Static (50% chance wild Pokémon is Electric), Magnet Pull (50% chance wild Pokémon is Steel).
- Weather system (SPEC §1.9): 4 types — Rain, Harsh Sunlight, Sandstorm, Hail. Duration: 5 turns from moves (Rain Dance, Sunny Day, Sandstorm, Hail), permanent from abilities. Active weather displayed in battle text each turn.
- Weather effects: Rain (Water ×1.5, Fire ×0.5, Thunder always hits, SolarBeam halved), Sun (Fire ×1.5, Water ×0.5, SolarBeam skips charge, Thunder 50% accuracy), Sandstorm (1/16 HP/turn to non-Rock/Ground/Steel), Hail (1/16 HP/turn to non-Ice). Extends Phase 4 damage formula: Weather modifier slot now active.
- Weather-ability interactions: Swift Swim (×2 Spe in Rain), Chlorophyll (×2 Spe in Sun), Sand Veil (+20% evasion in Sandstorm), Rain Dish (1/16 HP/turn in Rain), Forecast (Castform type change — Castform data added if not present).
- Ability activation messages in battle: "[Pokémon]'s Intimidate!", "[Pokémon]'s Flash Fire raised the power of its Fire-type moves!", etc.
- Debug level update: modify test species to have abilities (Pikachu: Static, Pidgey: Keen Eye, Geodude: Sturdy). Add a trainer on Debug Route with a weather-setting move (Hiker with Geodude that knows Sandstorm, AI 3).

### Assets

**VFX**
- Rain weather overlay (falling rain drops on battle scene)
- Sunlight weather overlay (bright lens flare)
- Sandstorm weather overlay (swirling sand particles)
- Hail weather overlay (falling ice chunks)
- Ability activation flash (brief highlight on Pokémon)

**UI**
- Ability name on Summary screen (extends Phase 3)
- Weather indicator text in battle

**Audio**
- Rain ambience loop
- Sandstorm ambience loop
- Hail ambience loop
- Harsh sunlight ambience loop
- Weather damage SFX
- Ability activation SFX

---

## Phase 12 — PC Storage & Move Management

Overflow Pokémon go to Bill's PC, and moves can be taught from TMs, HMs, and tutors.

- Bill's PC: accessed from PC terminals in Pokémon Centers. 14 boxes × 30 slots = 420 storage capacity. Box names editable. Operations: Deposit (party → box), Withdraw (box → party), Move (rearrange within/between boxes), Release (permanently delete with confirmation). View Pokémon summary from box. Manage held items on boxed Pokémon.
- When party is full and a Pokémon is caught, the new Pokémon is automatically sent to the current box. Message: "[Pokémon] was sent to [Box Name]!"
- Extends Phase 5: party-full overflow now routes to PC instead of blocking catch.
- TM teaching: TMs stored in the TMs & HMs Bag pocket. Use a TM on a compatible Pokémon → move learning prompt (same UI as Phase 6 level-up learning). TMs are single-use and consumed. 50 TMs defined in item data; a few placed in debug for testing (TM01 Focus Punch, TM13 Ice Beam, TM24 Thunderbolt, TM35 Flamethrower).
- HM teaching: HMs stored in TMs & HMs pocket. Same learning UI as TMs, but HMs are not consumed. HM moves cannot be forgotten via normal means. 7 HMs defined (Cut, Fly, Surf, Strength, Flash, Rock Smash, Waterfall). Overworld effects deferred to Phase 13.
- Move Deleter: a special NPC who can remove any move, including HM moves. One placed in Debug Town for testing.
- Move Tutor: NPC who teaches a specific move once. Same learning UI. 16 tutor moves defined (SPEC §6.8). One test tutor placed in Debug Town (teaches Seismic Toss).
- Debug level update: PC terminal in Debug Town Pokémon Center now functional. 3 Pokémon pre-placed in Box 1 for testing (Magikarp Lv 5, Abra Lv 10, Pikachu Lv 15). Move Deleter and Move Tutor NPCs added.

### Assets

**Sprites**
- Bill's PC terminal sprite (overworld, already present in Center tilemap from Phase 9)
- TM/HM disc item icons (generic disc + type-colored variants)

**UI**
- PC Box screen: 30-slot grid per box, box name, navigation arrows between boxes
- Deposit/Withdraw/Move/Release sub-menu
- Box Pokémon preview (mini summary: species, level, held item icon)
- TM/HM pocket UI (list with move name, type, and compatible indicator)
- Move Deleter confirmation ("forget [move]?")

**Audio**
- PC boot-up SFX
- PC box switch SFX
- Pokémon deposited/withdrawn SFX
- Pokémon released SFX (+ confirmation jingle)
- TM use SFX

---

## Phase 13 — Field Moves & Traversal

HMs transform the overworld: cut trees, surf water, fly between towns, push boulders, and ride the Bicycle.

- HM field moves (SPEC §3.3): select a Pokémon with the HM move from the party menu in the overworld → use the field move. Each requires a Badge (badge system in Phase 16; all HMs usable via debug flag for now — "badge gating wired to debug toggle; real badge checks in Phase 16").
  - **Cut**: removes small tree obstacles. Tree tile becomes walkable.
  - **Fly**: opens town selection screen (visited towns only). Teleports player to the selected town's entrance. Fade out/in transition.
  - **Surf**: enter water tiles. Switches to surfing movement mode (player sprite on Pokémon silhouette). Water encounters use separate surf encounter tables. Exit surf by stepping onto land.
  - **Strength**: push movable boulders one tile in the direction pushed. Boulders block paths until pushed. Activation persists until leaving the map.
  - **Flash**: illuminates dark caves (cave fully lit after use; dark caves render only a small radius around the player without Flash).
  - **Rock Smash**: breaks cracked rock obstacles. May trigger a wild encounter from the rock.
  - **Waterfall**: climb waterfall tiles while surfing. Approach waterfall tile → prompt → ascend.
- Bicycle: key item (registered to Select). Toggles between walking and cycling. ×2 movement speed. Cannot use indoors or in certain areas. Cycling sprites for player character.
- Fishing: Old Rod, Good Rod, Super Rod — key items used at water tile edges. Press A at water → "Oh! A bite!" prompt → press A again → encounter from rod-specific table. Old Rod: mostly Magikarp. Good Rod: wider pool. Super Rod: best species. Rod encounter tables defined per area.
- Obstacle tiles: small trees (Cut), cracked rocks (Rock Smash), movable boulders (Strength), dark cave overlay (Flash), water tiles (Surf), waterfall tiles (Waterfall). All obstacle types added to tile system.
- Debug level update: add a small tree blocking a path on Debug Route (requires Cut). Add water tiles with a surfable pond on Debug Route (requires Surf). Add a boulder puzzle room in Debug Cave (requires Strength). Add dark cave overlay to Debug Cave (requires Flash). Add a small waterfall in Debug Cave. Give debug party Pokémon the necessary HM moves (Charmander: Cut, Squirtle: Surf + Waterfall, Geodude: Strength + Rock Smash, Pidgey: Fly). Add fishing spots at Debug Route pond. Give player Old Rod key item.

### Assets

**Sprites**
- Player character — cycling sprites (4 directions, 4-frame cycle)
- Player character — surfing sprites (on Pokémon silhouette, 4 directions)
- Fishing pose sprite (player at water edge)
- Movable boulder sprite
- Small tree obstacle sprite
- Cracked rock obstacle sprite

**Tilemaps**
- Waterfall tile (animated)
- Dark cave overlay (circle of light, expands on Flash)

**VFX**
- Cut slash animation
- Boulder push animation
- Rock Smash break animation
- Flash illumination expansion
- Fly take-off / landing animation
- Fishing bobber animation
- "Oh! A bite!" indicator

**UI**
- Fly destination selection screen (town list)
- HM use confirmation prompt ("Use [move]?")
- Field move selection from party menu (extends Phase 3 party sub-menu)

**Audio**
- Cut SFX
- Surf water movement SFX (looping)
- Fly take-off SFX + landing SFX
- Strength boulder push SFX
- Flash activation SFX
- Rock Smash SFX
- Waterfall climb SFX
- Fishing cast SFX + bite SFX + reel SFX
- Bicycle BGM (replaces area BGM while cycling)

---

## Phase 14 — Save System & Title Screen

Progress persists across sessions with save/load, and the game gets its proper entry point.

- Save data model: party (6 Pokémon with all instance data), PC boxes (14 × 30 slots), Bag contents (all 5 pockets), player position (map ID, tile coordinates, facing direction), player name, rival name, player gender, money, play time, Pokédex data (seen/caught flags per species), trainer defeated flags, story progression flags, badge flags (8), options settings, last-visited Pokémon Center, active Repel steps remaining, registered key item.
- Save from Start Menu: single save slot. "Would you like to save?" → Yes/No. Progress indicator during write. "Saved the game!" confirmation. Overwrite warning if save exists.
- Title screen: game logo, "Press Start" prompt. Start opens menu: New Game / Continue (if save exists). New Game warns if overwrite.
- New Game flow: intro sequence (Professor Oak explains Pokémon world), gender selection (Red / Leaf), player name entry, rival name entry, Oak's Lab scene, starter selection (Bulbasaur / Charmander / Squirtle — 3 Poké Balls on a table), rival picks type-advantage starter, first rival battle (Lv 5 vs. Lv 5). After battle, player exits lab into Pallet Town with starter in party.
- Continue: loads save data, player appears at saved position.
- Soft reset: A+B+Start+Select simultaneously returns to title screen without saving.
- Name entry screen: keyboard layout for entering player name, rival name, and Pokémon nicknames (extends Phase 5 nickname prompt). Max 7 characters for player/rival, 10 for Pokémon.
- Play time counter: tracks hours:minutes from New Game. Displayed on Trainer Card (extends Phase 2).
- Debug level: accessible via a debug option on the title screen (hidden — hold Select on "New Game"). Skips intro, loads Debug Town with preset party and items.

### Assets

**Sprites**
- Title screen logo artwork
- Professor Oak sprite (intro sequence)
- Oak's Lab interior tilemap
- 3 Poké Balls on table (starter selection)
- Starter Pokémon overworld sprites (Bulbasaur, Charmander, Squirtle for the lab scene)

**UI**
- Title screen layout (logo, "Press Start", menu)
- Name entry keyboard screen
- Gender selection screen
- Starter selection UI (3 Poké Balls with species reveal)
- Save progress indicator
- Save confirmation dialog
- Overwrite warning dialog

**Audio**
- Title screen BGM
- Intro/Oak's speech BGM
- Pallet Town BGM
- Starter selection jingle
- Save SFX

---

## Phase 15 — Pokédex & Progression UI

Tracking screens for the player's collection, badges, and map.

- Pokédex screen (from Start Menu → POKéDEX): numbered list of all 151 Kanto entries. Each entry shows: seen (silhouette + number), caught (full sprite + name), or unknown (number only). Select an entry for detail page: species name, type(s), height, weight, Pokédex text description, Area (which routes/locations this species appears — based on encounter tables), Cry button (plays cry SFX).
- Pokédex search/filter: by type, by name (alphabetical), by habitat area, by weight, by height. Sort ascending/descending.
- National Pokédex: 386 entries. Unlocked post-game (flag set when entering Hall of Fame with ≥60 caught). Species data for Gen II/III Pokémon loaded from data tables defined in Phase 3 (full roster in Phase 20).
- Pokédex aide milestones (SPEC §9.5): NPC aides on routes give rewards at thresholds — 10 caught → HM05 Flash, 20 caught → Itemfinder, 30 caught → Amulet Coin, 40 caught → EXP Share. Aide NPC interaction checks Pokédex count and awards item. Aides placed in Phase 19 content; system logic built here.
- Trainer Card (extends Phase 2): name, ID number, play time, money, Pokédex seen/caught counts, badges earned (8 slots — empty for now). Back of card shows badge case.
- Badge case: 8 badge slots displayed as a grid. Empty slots are silhouettes. Earned badges show their icon and name. Integrated into Trainer Card back.
- Town Map (key item): displays Kanto region overview with labeled towns and routes. Player's current location marked. Accessed from Bag (Key Items) or via registered Select button. Panning/scrolling for the full map.
- Fame Checker (key item): collects info blurbs about notable NPCs (Gym Leaders, Elite Four, etc.) from various sources (NPCs, signs, items). Data entries populated in Phase 19 content.
- Debug level update: Pokédex wired into Start Menu. Debug Pokédex has ~20 species seen/caught from testing. Town Map shows Debug Town and Debug Route. 8 empty badge slots visible.

### Assets

**Sprites**
- Pokédex species sprites (small thumbnails — reuse front sprites from Phase 3, scaled down)
- Badge icons — 8 badges (Boulder, Cascade, Thunder, Rainbow, Soul, Marsh, Volcano, Earth)
- Town Map — Kanto region overview artwork

**UI**
- Pokédex list screen (numbered list with seen/caught indicators)
- Pokédex detail screen (sprite, type, height/weight, description, area, cry)
- Pokédex search/filter panel
- Trainer Card front (name, ID, time, money, Pokédex count)
- Trainer Card back (badge case — 8 slots)
- Town Map screen (scrollable map with location labels)
- Fame Checker screen (NPC portraits + blurb list)

**Audio**
- Pokédex open/close SFX
- Pokédex entry registered jingle
- Pokédex rating jingle (when professor evaluates)
- Badge acquired jingle (used in Phase 16)

---

## Phase 16 — Gym System & Badges

The 8 Gym Leaders, their puzzles, and the badge progression system that gates the game.

- Gym interior maps: each of the 8 gyms has a unique puzzle and layout. Brock's gym (no puzzle, straight path). Misty's gym (simple trainer gauntlet). Lt. Surge's gym (trash can switch puzzle — find 2 correct cans in sequence). Erika's gym (cut-tree maze). Koga's gym (invisible wall maze). Sabrina's gym (teleport pad maze). Blaine's gym (quiz door locks — answer trivia to proceed). Giovanni's gym (spin tile puzzle).
- Gym Leader battles: each leader uses the teams from SPEC §5.2 with correct species, levels, and movesets. Higher AI levels (Level 4–8). TM reward item given after victory. Leader pre-battle and post-battle dialogue.
- Badge acquisition: badge flag set on Gym Leader defeat. Badge icon appears in badge case (extends Phase 15). Badge effects:
  - Obedience thresholds activated (SPEC §5.4): 0 badges = Lv 10, 1 = Lv 20, ..., 8 = all levels. Applies to traded Pokémon only.
  - HM field move gating: extends Phase 13 — debug toggle replaced with real badge checks. Cut requires Cascade Badge, Fly requires Thunder Badge, etc. (SPEC §3.3).
- Obedience system (SPEC §5.4): traded Pokémon above the badge threshold may: ignore commands (use random move), do nothing ("loafing around"), or fall asleep. Probability of disobedience increases with level gap.
- Gym trainers: each gym contains 2–5 trainers before the leader. Gym trainers use the gym's specialty type and have moderate AI levels.
- Badge-gated mart inventory: extends Phase 9 — mart stock expands as badges are earned.
- Gym guide NPC: each gym has an NPC at the entrance who gives advice about the leader's type.
- Gym maps are standalone (not yet placed in the Kanto overworld — accessible via debug warp for testing). Real placement in Phase 19.

### Assets

**Tilemaps**
- 8 Gym interior maps with puzzle elements (trash cans, teleport pads, invisible walls, quiz doors, spin tiles, cut trees)

**Sprites**
- Gym Leader overworld sprites — 8 leaders (Brock, Misty, Lt. Surge, Erika, Koga, Sabrina, Blaine, Giovanni)
- Gym Leader battle portraits — 8 leaders
- Gym Trainer overworld sprites (reuse trainer classes from Phase 10 + new types: Gentleman, Beauty, Juggler, Psychic)
- Gym puzzle elements: trash cans, teleport pads, switch indicators, quiz door locks

**VFX**
- Badge acquisition animation (badge icon zooms in)
- Teleport pad warp animation
- Spin tile slide animation

**UI**
- Badge earned popup ("You got the [Badge Name]!")
- TM received popup
- Quiz prompt screen (Blaine's gym)
- Obedience failure text ("It won't obey!", "[Pokémon] is loafing around!", etc.)

**Audio**
- Gym BGM
- Gym Leader battle BGM
- Badge acquired fanfare (from Phase 15)
- Gym puzzle SFX (teleport, switch, spin)

---

## Phase 17 — Safari Zone & Game Corner

Two distinct minigame systems that diverge from standard battle and overworld mechanics.

- **Safari Zone** (SPEC §9.1): located in Fuchsia City. Entry fee ¥500. Player receives 30 Safari Balls. 500-step counter. Separate battle mode: no moves, no regular balls. Actions: Throw Ball (uses catch formula with Safari Ball 1.5× modifier), Throw Bait (decrease catch rate counter, decrease flee rate counter), Throw Rock (increase catch rate, increase flee rate), Run. Wild Pokémon may flee each turn based on flee counter. Internal catch/flee counters persist across turns and are modified by bait/rock. When out of balls or steps, player warps to entrance. 4 distinct zones with unique encounter tables (Kangaskhan, Tauros, Chansey, Scyther, Dratini — species data added). Gold Teeth item found in Zone 4 → trade to Safari Zone Warden for HM04 Strength.
- Safari Zone encounter tables: Zone 1 (Nidoran♂/♀, Doduo, Venonat), Zone 2 (Exeggcute, Rhyhorn, Parasect), Zone 3 (Kangaskhan, Tauros, Chansey), Zone 4 (Scyther, Dratini via Super Rod). New species data added for all Safari-exclusive Pokémon.
- **Game Corner** (SPEC §9.3): Celadon City slot machine minigame. Coin Case key item required. Buy coins: 50 for ¥1,000 or 500 for ¥10,000. Slot machine: bet 1–3 coins per spin. 3 reels with symbols (7, BAR, Cherry, Replay, Pikachu, etc.). 1 coin = center row, 2 coins = all 3 rows, 3 coins = rows + diagonals. Triple 7s = 300 coins jackpot. Prize exchange NPC: Pokémon prizes (Abra 180c, Clefairy 500c, Dratini 2800c, Scyther 5500c, Porygon 9999c) and TM prizes (Ice Beam 4000c, Iron Tail 3500c, Thunderbolt 4000c, Flamethrower 4000c). Hidden coins findable on Game Corner floor via Itemfinder.
- **Berry Crush** (SPEC §9.4): multiplayer-only minigame on Two Island (requires link cable / wireless adapter with 2–5 players). Out of scope for single-player recreation. Powder Jar key item defined in data but non-functional.
- Both systems standalone — accessible via debug warp NPCs in Debug Town. Safari Zone requires ¥500 (or debug free entry). Game Corner requires Coin Case (placed in debug Key Items).
- Debug level update: 2 new debug warp NPCs in Debug Town — "Safari Zone Warp" and "Game Corner Warp." Each loads the respective minigame map.

### Assets

**Tilemaps**
- Safari Zone — 4 zone maps with unique terrain (ponds, tall grass, rocky areas)
- Safari Zone entrance gate interior
- Game Corner interior (slot machine rows, prize exchange counter)

**Sprites**
- Safari Zone exclusive Pokémon front/back sprites (~10 new species: Kangaskhan, Tauros, Chansey, Scyther, Doduo, Exeggcute, Rhyhorn, Parasect, Venonat, Nidoran♂/♀)
- Slot machine reel symbols (7, BAR, Cherry, Replay, Pikachu, Poké Ball)
- Game Corner NPC sprites (prize clerk, coin seller, patrons)
- Safari Zone warden NPC sprite
- Gold Teeth item sprite

**VFX**
- Safari Ball throw animation (variant of catch animation from Phase 5)
- Bait throw animation
- Rock throw animation
- Slot machine reel spin animation
- Jackpot flash animation

**UI**
- Safari Zone HUD (Safari Balls remaining, steps remaining)
- Safari action menu (Ball / Bait / Rock / Run)
- Slot machine play screen (3 reels, bet indicator, coin count)
- Coin purchase screen
- Prize exchange screen (Pokémon tab, TM tab)
- Coin Case display

**Audio**
- Safari Zone BGM
- Safari Ball throw SFX
- Bait/Rock throw SFX
- Wild Pokémon flee SFX
- Game Corner BGM (slot machine ambient)
- Reel spin SFX
- Reel stop SFX
- Jackpot jingle
- Coin get SFX
- Prize exchange SFX

---

## Phase 18 — Breeding System

Post-game Pokémon breeding on Four Island with egg groups, inheritance, and hatching.

- Day Care: NPC pair on Four Island. Deposit up to 2 Pokémon. Day Care leveling: deposited Pokémon gain 1 EXP per step player takes. Moves replaced in FIFO order on level-up. Day Care does not trigger evolution.
- Compatibility check (SPEC §12.1): two deposited Pokémon can breed if they share an Egg Group and have opposite genders, OR if one is Ditto. No Eggs Discovered group cannot breed. Genderless Pokémon breed only with Ditto.
- 15 Egg Groups defined (SPEC §12.2): Monster, Water 1/2/3, Bug, Flying, Field, Fairy, Grass, Human-Like, Mineral, Amorphous, Dragon, Ditto, No Eggs Discovered. All 151+ species assigned to groups.
- Egg production (SPEC §12.3): per 256 steps, check compatibility tier and roll. Same species + different OT = 69.3%, same species + same OT = 49.5%, different species + different OT = 49.5%, different species + same OT = 19.8%. Day Care Man steps into the yard when an egg is ready.
- Egg instance: species (mother's base form or non-Ditto parent's base form), moves (level-up moves at Lv 5 + shared parent level-up moves + father's compatible TM moves + father's egg moves), IVs (3 inherited from parents: one contributes 2, the other 1; 3 random), nature (random — no Everstone mechanic in FRLG), ability (random from species pool), friendship (base friendship for species).
- Hatching (SPEC §12.4): egg has egg cycles (species-specific, e.g., Magikarp = 5, Dratini = 40). 1 cycle = 256 steps. Flame Body / Magma Armor in party halves cycles. Egg hatches into Lv 5 Pokémon. Hatching animation.
- Egg in party: occupies a party slot. Shows as "Egg" with no species info. Summary shows "It looks like it will take a long time to hatch" / "It appears to move occasionally" / "It's making sounds! It's about to hatch!" based on remaining cycles.
- Debug level update: a "Day Care Warp" NPC in Debug Town loads a test Day Care map. Pre-deposit two compatible Pokémon (Pikachu ♂ + Pikachu ♀) for immediate breeding test. Debug step counter accelerator (hold L to count steps ×10 speed) for hatching testing.

### Assets

**Tilemaps**
- Day Care exterior (small building with fenced yard)
- Day Care interior (counter, NPC pair)

**Sprites**
- Day Care Man NPC sprite (overworld — idle in yard when egg ready, inside when not)
- Day Care Lady NPC sprite (interior counter)
- Egg sprite (party icon, overworld item)
- Egg hatching sprite sequence

**VFX**
- Egg hatching animation (egg cracks, light burst, Pokémon emerges)

**UI**
- Day Care deposit/withdraw screen
- Egg summary text (hatch progress messages)
- "The Day Care Man has an Egg for you!" prompt
- "Your Egg hatched!" celebration screen

**Audio**
- Day Care BGM
- Egg received jingle
- Egg hatching BGM
- Hatching success jingle

---

## Phase 19 — Content: Kanto Region & Main Story

All systems are built. This phase populates the full Kanto map, story events, routes, trainers, and encounters.

- **Full Kanto map**: 10 towns/cities (Pallet Town, Viridian City, Pewter City, Cerulean City, Vermilion City, Lavender Town, Celadon City, Fuchsia City, Saffron City, Cinnabar Island), Indigo Plateau, Victory Road. 25 routes with terrain variety (grass, water, caves, bridges). All interiors (houses, buildings, Pokémon Centers, Poké Marts).
- **Major dungeons**: Mt. Moon (multi-floor, Team Rocket grunts, fossil choice), Rock Tunnel (dark cave), Pokémon Tower (ghost encounters — Silph Scope reveal mechanic, Marowak ghost battle), S.S. Anne (interior with trainers, Captain gives HM01 Cut), Silph Co. (11-floor building, card key doors, warp tiles, Giovanni boss battle), Power Plant (linear dungeon, Zapdos Lv 50 static encounter at end), Seafoam Islands (boulder/water puzzle, Articuno Lv 50 static encounter at bottom), Pokémon Mansion (switch-activated doors, journals), Victory Road (boulder puzzles, strong trainers).
- **Legendary bird static encounters**: Articuno (Seafoam Islands, Lv 50), Zapdos (Power Plant, Lv 50). Unique overworld sprites, interact to trigger battle, catch rate 3, legendary battle BGM, do not respawn if KO'd. Moltres is on Mt. Ember (Sevii Islands) — placed in Phase 20.
- **Story events** placed in progression order (SPEC §5.1): Oak's Lab starter scene (from Phase 14), Route 1 tutorial, Viridian City → Oak's Parcel → Pokédex, Rival battles at Route 22/Cerulean/S.S. Anne/Pokémon Tower/Silph Co./Route 22, Team Rocket encounters (Mt. Moon, Nugget Bridge, Celadon hideout, Pokémon Tower, Silph Co.), Snorlax roadblocks (Route 12 + Route 16, wake with Poké Flute), Celadon guard drinks (Fresh Water/Soda Pop/Lemonade to unlock Saffron gates), Bill's PC intro event (Route 25).
- **All trainers placed**: every route, cave, and building gets its trainer roster with class, team, AI level, line-of-sight range, pre/post-battle dialogue. ~300+ trainers total (not enumerated individually — each route/area populated per original game data).
- **Wild encounter tables**: all routes, caves, and water areas populated with species, levels, and probabilities per the 10-slot encounter table format. Fishing encounter tables (Old/Good/Super Rod) per area.
- **8 Gyms placed** in their cities: extends Phase 16 — gym maps connected to city maps via doors. Gym guides, trainers, and leaders accessible in normal game flow. Badge gating now fully wired (extends Phase 13).
- **Key item placements**: Bike Voucher (Vermilion Fan Club), Bicycle (Cerulean Bike Shop), Old Rod (Vermilion), Good Rod (Fuchsia), Super Rod (Route 12), Silph Scope (Celadon hideout), Poké Flute (Mr. Fuji after Pokémon Tower), VS Seeker (Vermilion), Teachy TV (Route 3 guide), Fame Checker (Celadon), all HMs at their SPEC locations.
- **Pokédex aide NPCs** placed at Routes 2, 11, 15 (extends Phase 15 milestone system).
- **In-game trade NPCs** placed (SPEC §9.6): Route 2 Abra↔Mr. Mime, Cerulean Poliwhirl↔Jynx, Vermilion Spearow↔Farfetch'd, Route 18 Golduck↔Lickitung, Cinnabar Lab trades.
- **Move tutor NPCs** placed at their SPEC §6.8 locations.
- **Celadon Department Store**: multi-floor shop with evolution stones, vitamins, TMs, battle items, vending machines (extends Phase 9 shop system).

### Assets

**Tilemaps**
- Complete Kanto overworld tilemap (all towns, cities, routes)
- All interior maps (~100+: houses, Pokémon Centers, Marts, gyms, dungeons, labs)
- All dungeon maps (Mt. Moon, Rock Tunnel, Pokémon Tower, S.S. Anne, Silph Co., Power Plant, Seafoam Islands, Pokémon Mansion, Victory Road)

**Sprites**
- All remaining NPC overworld sprites (story NPCs, generic townsfolk, key characters: Professor Oak, Bill, Mr. Fuji, Giovanni, Elite Four, etc.)
- All remaining trainer class overworld sprites and battle portraits
- Snorlax roadblock overworld sprite
- Team Rocket Grunt overworld sprite (if not already from Phase 10)
- Legendary Pokémon overworld sprites (Articuno, Zapdos — static encounter sprites)
- Articuno and Zapdos front/back battle sprites + party icons
- Key item sprites (Bike Voucher, Silph Scope, Poké Flute, etc.)

**Audio**
- Town/City BGMs for all 10 towns (Pallet Town from Phase 14; 9 new)
- Route BGMs (3–4 variants for early/mid/late routes)
- Dungeon BGMs (Mt. Moon, Pokémon Tower, Silph Co., Seafoam, etc.)
- S.S. Anne BGM
- Team Rocket encounter BGM
- Legendary encounter BGM (shared with Phase 20 legendaries)
- Articuno cry SFX, Zapdos cry SFX
- Story event jingles (item get, key moment stings)

---

## Phase 20 — Content: Endgame & Post-Game

The final push: Elite Four, post-game Sevii Islands, Legendaries, roaming beasts, and the full 386-species roster.

- **Elite Four gauntlet** (SPEC §5.3): Indigo Plateau lobby → 4 consecutive battles (Lorelei, Bruno, Agatha, Lance) + Champion Blue, no Pokémon Center access between them. Teams per spec with correct species, levels, movesets, and held items. Champion's team varies by player's starter. On victory → Hall of Fame screen (party displayed with timestamps). Credits sequence. Return to Pallet Town.
- **Post-game Elite Four rematch**: extends Phase 10 trainer system — Elite Four and Champion have upgraded teams (~10 levels higher, expanded rosters with wider type coverage, additional held items). Triggered after obtaining National Pokédex.
- **Cerulean Cave**: unlocked post-game (guard NPC removed after Hall of Fame). Multi-floor dungeon with high-level wild encounters and Mewtwo at Lv 70 (static encounter — unique battle with Legendary BGM).
- **Moltres**: Mt. Ember on One Island, Lv 50. Static encounter — same system as Articuno/Zapdos from Phase 19. Catch rate 3.
- **Roaming Legendary Beast** (SPEC §4.4): after entering Hall of Fame, one beast begins roaming based on starter (Bulbasaur → Entei, Charmander → Suicune, Squirtle → Raikou). Roaming mechanics: occupies a random route, moves on area transition, appears as random encounter on its route, flees after one turn, HP/status persist between encounters, KO = gone permanently, trackable via Pokédex Area function.
- **Sevii Islands** (SPEC §3.4): Islands 1–3 accessible after Blaine (Tri-Pass from Celio). Islands 4–7 accessible post-game with National Pokédex (Rainbow Pass). Notable content: Mt. Ember (Moltres + Team Rocket grunts guarding Ruby gem), Berry Forest on Three Island (step-based berry regeneration per SPEC §9.2), Icefall Cave (Four Island), Day Care building on Four Island (connects to Phase 18 breeding system), Lost Cave (Five Island), Pattern Bush (Six Island), Team Rocket Warehouse (Five Island — Sapphire gem quest), Tanoby Ruins (Seven Island — Unown encounters).
- **Trainer Tower** (SPEC §9.7): Seven Island post-game. 4 battle formats: Single, Double, Mixed (alternating single/double), and Knockout (consecutive battles, no healing). Players race to the top floor; completion time is recorded and saved. Pre-set trainer teams (not random). Rewards for fast completions.
- **Berry Forest mechanics** (SPEC §9.2): berries regenerate every ~1,500 steps. Common (60%): Razz, Nanab, Chesto, Pecha, Rawst. Uncommon (30%): Bluk, Wepear, Oran, Cheri, Aspear, Persim, Pinap. Rare (10%): Lum Berry.
- **Network Machine quest**: retrieve Ruby from Mt. Ember → give to Celio → retrieve Sapphire from Rocket Warehouse (Five Island) → give to Celio → Network Machine complete (enables cross-game trading flavor text).
- **Full Pokémon roster**: all 386 National Pokédex species with complete data (base stats, movesets, abilities, egg groups, evolution chains, Pokédex entries). Extends Phase 3 species data from ~20 to 386. Johto/Hoenn Pokémon appear in Sevii Islands encounter tables and via evolution/breeding of Kanto Pokémon.
- **Pokédex completion evaluation**: Professor Oak rates the Pokédex (10/20/30/.../150 thresholds). Completing the Kanto Pokédex (150 caught, excluding Mew) earns a congratulations from Oak and a diploma.

### Assets

**Tilemaps**
- Indigo Plateau (lobby, 4 Elite Four chambers, Champion room, Hall of Fame room)
- Cerulean Cave (multi-floor)
- Sevii Islands — 7 island maps with towns, routes, caves, and interiors (One Island through Seven Island)
- Mt. Ember exterior + interior
- Berry Forest
- Icefall Cave
- Lost Cave
- Team Rocket Warehouse
- Tanoby Ruins (7 chambers)
- Trainer Tower (multi-floor)

**Sprites**
- Elite Four battle portraits (Lorelei, Bruno, Agatha, Lance)
- Champion Blue battle portrait (variant — post-game champion attire)
- Legendary Pokémon overworld sprites — Moltres, Mewtwo (static encounter sprites; Articuno and Zapdos in Phase 19)
- Moltres and Mewtwo front/back battle sprites + party icons
- Roaming beast sprites (Raikou, Entei, Suicune — front/back battle sprites + party icons)
- Unown sprites (28 forms: A–Z, ! , ?)
- Remaining Pokémon front/back sprites to complete the 386 National Pokédex (~350 new sprites)
- Remaining Pokémon party icons (~350 new)
- Remaining Pokémon cries (~350 new)
- Sevii Islands NPC sprites (Celio, islanders, Rocket admins)
- Berry sprites (15 berry types)

**VFX**
- Hall of Fame Pokémon display animation
- Credits scroll
- Legendary encounter screen flash (unique variant — shared with Phase 19 legendaries)
- Berry pickup sparkle

**UI**
- Hall of Fame screen (party Pokémon with level, time, and date)
- Credits sequence
- National Pokédex unlock notification
- Pokédex completion diploma
- Berry Forest berry location indicators

**Audio**
- Elite Four battle BGM
- Champion battle BGM
- Hall of Fame BGM
- Credits BGM
- Moltres cry SFX, Mewtwo cry SFX, Raikou/Entei/Suicune cry SFX
- Sevii Islands town BGMs (2–3 variants)
- Sevii Islands route BGM
- Mt. Ember / Icefall Cave / Lost Cave BGMs
- Team Rocket Warehouse BGM
- Trainer Tower BGM
- Roaming beast encounter SFX (unique cry on encounter start)
- Remaining Pokémon cries (~350)
