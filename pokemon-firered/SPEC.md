# Pokémon FireRed — Gameplay Systems Spec

Pokémon FireRed Version, Game Boy Advance, 2004. Developed by Game Freak, published by Nintendo. A Generation III enhanced remake of the original Pokémon Red (1996). Engine: proprietary GBA C engine.

---

## 1. Core Gameplay Systems

### 1.1 Primary Gameplay Loop

1. Explore the overworld (routes, towns, caves, water).
2. Encounter wild Pokémon in tall grass, caves, or while surfing/fishing.
3. Battle and optionally capture wild Pokémon.
4. Train party Pokémon through battles to gain EXP and EVs.
5. Challenge Gym Leaders to earn Badges, unlocking new HM traversal abilities and traded-Pokémon obedience thresholds.
6. Progress through the story (defeat Team Rocket, collect 8 Badges).
7. Challenge the Elite Four and Champion to enter the Hall of Fame.
8. Post-game: complete the Sevii Islands questline, fill the Pokédex, breed, and rematch the upgraded Elite Four.

### 1.2 Battle System

Turn-based, 1v1 (single battles only in the main game; double battles exist in a few scripted trainer fights and the Battle Tower post-game equivalent is absent — FireRed has no Battle Frontier).

#### Turn Structure

Each turn, both sides independently select an action:

| Action | Priority |
|--------|----------|
| Flee (wild only) / Switch / Use Item | Always resolves before attacks |
| Use a move | Resolved by move priority bracket, then Speed stat |

After both actions are selected, they resolve in order. Trainer item use and switching always occur before any attack. When both sides attack, the move with higher priority goes first. If priority is equal, the faster Pokémon acts first. Speed ties are broken randomly (50/50).

#### Move Priority Brackets (Gen III)

| Priority | Moves |
|----------|-------|
| +5 | Helping Hand |
| +4 | Magic Coat, Snatch |
| +3 | Detect, Endure, Follow Me, Protect |
| +1 | ExtremeSpeed, Fake Out, Mach Punch, Quick Attack |
| 0 | All other moves, fleeing from wild battles |
| −1 | Vital Throw |
| −3 | Focus Punch |
| −4 | Revenge |
| −5 | Counter, Mirror Coat |
| −6 | Roar, Whirlwind |

#### Physical / Special Classification

There is **no per-move physical/special split** in Gen III. Instead, all moves of a given type are uniformly Physical or Special based solely on the type:

| Physical Types | Special Types |
|----------------|---------------|
| Normal, Fighting, Poison, Ground, Flying, Bug, Rock, Ghost, Steel | Fire, Water, Grass, Electric, Ice, Psychic, Dragon, Dark |

This means, e.g., Fire Punch uses Special Attack despite being a "punch" move, and Shadow Ball uses Attack despite being a ranged projectile.

### 1.3 Damage Formula

```
Damage = (((2 × Level / 5 + 2) × Power × A / D) / 50 × Burn × Screen × Targets × Weather × FF + 2)
         × Stockpile × Critical × DoubleDmg × Charge × HH × STAB × Type1 × Type2 × Random / 100
```

All intermediate divisions use **truncated integer division** (floor).

| Modifier | Value |
|----------|-------|
| **A / D** | Attacker's effective Atk or Sp.Atk / Defender's effective Def or Sp.Def (per §1.2 type table) |
| **STAB** | 1.5 if move type matches one of the user's types; 1 otherwise |
| **Type1, Type2** | Each 0 / 0.5 / 1 / 2 depending on type matchup vs. each of the target's types |
| **Critical** | 2 for a critical hit; 1 otherwise |
| **Burn** | 0.5 if attacker is burned, does not have Guts, and the move is physical; 1 otherwise |
| **Weather** | 1.5 for same-element boost (Rain → Water, Sun → Fire); 0.5 for opposite; 1 otherwise |
| **Screen** | 0.5 if Reflect (physical) or Light Screen (special) is active on the defender's side |
| **Random** | Integer uniformly distributed in [85, 100] |
| **Charge** | 2 if Charge is active and move is Electric-type |
| **HH** | 1.5 if Helping Hand is active on the attacker |
| **FF** | 1.5 if the attacker's Flash Fire Ability has been activated; 1 otherwise |
| **Stockpile** | 1, 2, or 3 for Spit Up depending on Stockpile count |
| **DoubleDmg** | 2 for Pursuit on a switching target, Stomp on a minimized target, etc. |

### 1.4 Critical Hits

| Stage | Probability | Triggered By |
|-------|-------------|-------------|
| 0 | 1/16 (6.25%) | Default |
| 1 | 1/8 (12.5%) | High-crit moves (Slash, Crabhammer, Razor Leaf, Karate Chop, etc.) |
| 2 | 1/4 (25%) | Focus Energy (+2), Scope Lens (+1) + high-crit move |
| 3 | 1/3 (33.3%) | Stick (Farfetch'd, +2) or Lucky Punch (Chansey, +2) + high-crit move |
| 4+ | 1/2 (50%) | Maximum achievable rate |

Critical hits in Gen III:
- Deal **2× damage**.
- Ignore the attacker's negative stat stages and the defender's positive stat stages.
- Ignore Reflect / Light Screen.
- Pokémon with Battle Armor or Shell Armor are immune to critical hits.

### 1.5 Type Effectiveness Chart (Gen III — 17 Types, No Fairy)

Super effective (2×), not very effective (0.5×), immune (0×):

| Attacking → | Super Effective Against | Not Very Effective Against | No Effect On |
|-------------|----------------------|--------------------------|-------------|
| Normal | — | Rock, Steel | Ghost |
| Fire | Grass, Ice, Bug, Steel | Fire, Water, Rock, Dragon | — |
| Water | Fire, Ground, Rock | Water, Grass, Dragon | — |
| Electric | Water, Flying | Electric, Grass, Dragon | Ground |
| Grass | Water, Ground, Rock | Fire, Grass, Poison, Flying, Bug, Dragon, Steel | — |
| Ice | Grass, Ground, Flying, Dragon | Fire, Water, Ice, Steel | — |
| Fighting | Normal, Ice, Rock, Dark, Steel | Poison, Flying, Psychic, Bug | Ghost |
| Poison | Grass | Poison, Ground, Rock, Ghost | Steel |
| Ground | Fire, Electric, Poison, Rock, Steel | Grass, Bug | Flying |
| Flying | Grass, Fighting, Bug | Electric, Rock, Steel | — |
| Psychic | Fighting, Poison | Psychic, Steel | Dark |
| Bug | Grass, Psychic, Dark | Fire, Fighting, Poison, Flying, Ghost, Steel | — |
| Rock | Fire, Ice, Flying, Bug | Fighting, Ground, Steel | — |
| Ghost | Psychic, Ghost | Dark, Steel | Normal |
| Dragon | Dragon | Steel | — |
| Dark | Psychic, Ghost | Fighting, Dark, Steel | — |
| Steel | Ice, Rock | Fire, Water, Electric, Steel | — |

Dual-type Pokémon multiply both type matchups: a move that is super effective against both types deals **4× damage**; super effective against one and not very effective against the other deals neutral **1× damage**.

### 1.6 Stat System

Six stats: **HP, Attack, Defense, Special Attack (Sp.Atk), Special Defense (Sp.Def), Speed**.

#### Stat Calculation

**HP:**
```
HP = floor((2 × Base + IV + floor(EV / 4)) × Level / 100) + Level + 10
```

**Other stats:**
```
Stat = floor((floor((2 × Base + IV + floor(EV / 4)) × Level / 100) + 5) × Nature)
```

Shedinja always has exactly 1 HP regardless of the formula.

#### Individual Values (IVs)
- Range: **0–31** per stat.
- Determined at encounter/egg generation; permanent and hidden.

#### Effort Values (EVs)
- Range: **0–255** per stat, **510 total** across all six stats.
- Gained by defeating specific Pokémon species (each species yields 1–3 EVs in specific stats).
- Vitamins grant **+10 EVs** per use, capped at **100 EVs** per stat from vitamins alone.
- The Macho Brace doubles EV gain from battles.
- Effective EV contribution: `floor(EV / 4)`, so 252 is the practical per-stat maximum (252/4 = 63 stat points; 255 wastes 3 EVs).

#### Natures

25 natures. 20 modify stats (×1.1 to one, ×0.9 to another); 5 are neutral. Natures never affect HP.

| +Atk | +Def | +Sp.Atk | +Sp.Def | +Spd |
|------|------|---------|---------|------|
| Lonely (−Def) | Bold (−Atk) | Modest (−Atk) | Calm (−Atk) | Timid (−Atk) |
| Adamant (−Sp.Atk) | Impish (−Sp.Atk) | Mild (−Def) | Gentle (−Def) | Hasty (−Def) |
| Naughty (−Sp.Def) | Lax (−Sp.Def) | Rash (−Sp.Def) | Careful (−Sp.Atk) | Jolly (−Sp.Atk) |
| Brave (−Spd) | Relaxed (−Spd) | Quiet (−Spd) | Sassy (−Spd) | Naive (−Sp.Def) |

Neutral: Hardy, Docile, Bashful, Quirky, Serious.

#### Battle Stat Stages

In-battle modifiers from moves like Swords Dance, Growl, etc. Range: −6 to +6.

| Stage | Multiplier |
|-------|-----------|
| −6 | 2/8 (25%) |
| −5 | 2/7 (≈28.6%) |
| −4 | 2/6 (≈33.3%) |
| −3 | 2/5 (40%) |
| −2 | 2/4 (50%) |
| −1 | 2/3 (≈66.7%) |
| 0 | 2/2 (100%) |
| +1 | 3/2 (150%) |
| +2 | 4/2 (200%) |
| +3 | 5/2 (250%) |
| +4 | 6/2 (300%) |
| +5 | 7/2 (350%) |
| +6 | 8/2 (400%) |

Accuracy and Evasion use a separate stage system with the same −6 to +6 range, but different multipliers (3/3, 4/3, 5/3, 6/3, 7/3, 8/3, 9/3 for stages 0 through +6; inverted for negative stages).

#### Accuracy Check

```
HitChance = MoveAccuracy × (AccuracyStage / EvasionStage) × AbilityModifiers
```

A random integer in [0, 99] is generated; the move hits if the random number is less than `HitChance`, capped at 100. Moves with no listed accuracy (e.g., Swift, Aerial Ace) bypass the check entirely and always hit. Abilities like Compound Eyes (×1.3 accuracy), Hustle (×0.8 accuracy for physical moves), and Sand Veil (×0.8 hit chance in Sandstorm) apply as modifiers.

### 1.7 Experience and Leveling

Level range: **1–100** (hatched Pokémon start at level 5 in Gen III).

Six experience growth rates determine total EXP required to reach level 100:

| Growth Rate | Total EXP to Lv 100 | Example Pokémon |
|-------------|---------------------|-----------------|
| Erratic | 600,000 | (No Kanto natives; Hoenn Pokémon like Zigzagoon, Seedot) |
| Fast | 800,000 | Clefairy, Vulpix, Jigglypuff, Chansey |
| Medium Fast | 1,000,000 | Bulbasaur, Charmander, Squirtle, Pidgey, Pikachu |
| Medium Slow | 1,059,860 | Nidoran♂/♀, Abra, Geodude, Machop |
| Slow | 1,250,000 | Dratini, Larvitar, most Legendaries |
| Fluctuating | 1,640,000 | (No Kanto natives; Hoenn Pokémon like Gulpin, Makuhita) |

#### EXP Gain Formula

```
EXP = a × b × L / 7 × e × t
```

| Variable | Value |
|----------|-------|
| **a** | 1.5 if the defeated Pokémon is trainer-owned; 1 if wild |
| **b** | Base EXP yield of the defeated Pokémon's species |
| **L** | Level of the defeated Pokémon |
| **e** | 1.5 if the gaining Pokémon holds a Lucky Egg; 1 otherwise |
| **t** | 1.5 if the gaining Pokémon was received in a trade; 1 if original trainer |

**EXP Share** (held item): The holder receives 50% of the EXP, and the battling Pokémon still receives full EXP. Both shares are subject to their own Lucky Egg and trade multipliers independently.

### 1.8 Status Conditions

#### Non-Volatile (persist outside battle, one at a time)

| Status | Effect | Duration | Immunity |
|--------|--------|----------|----------|
| **Burn (BRN)** | Lose 1/8 max HP per turn; damage from physical-type moves halved (per §1.2 type classification, not per-move) | Until cured | Fire-type Pokémon (from Fire moves); Ability: Water Veil |
| **Poison (PSN)** | Lose 1/8 max HP per turn; in the overworld, lose 1 HP per 4 steps | Until cured | Poison-type, Steel-type; Ability: Immunity |
| **Bad Poison (TOX)** | Damage starts at 1/16 max HP, increases by 1/16 each turn; resets to 1/16 on switch-in | Until cured | Same as Poison |
| **Paralysis (PAR)** | Speed reduced to 25%; 25% chance of full paralysis (can't move) | Until cured | Electric-type (Gen III+); Ability: Limber |
| **Sleep (SLP)** | Cannot use moves (except Sleep Talk, Snore) | 2–5 turns (random); counter decrements on move attempt; wake and act same turn | Ability: Insomnia, Vital Spirit |
| **Freeze (FRZ)** | Cannot move | 20% thaw chance per turn; thaws immediately when hit by a Fire move or using Flame Wheel/Sacred Fire | Ice-type; Ability: Magma Armor |

#### Volatile (cleared on switch-out)

| Status | Effect |
|--------|--------|
| **Confusion** | 1-in-3 chance of hitting self for 1–4 turns. Self-damage uses a typeless 40-power physical move against own Defense |
| **Infatuation** | 50% chance of being unable to act each turn. Requires opposite gender. Cured by switching or Mental Herb |
| **Flinch** | Prevents action for one turn. Only caused by certain moves (e.g., Fake Out, Rock Slide, Air Slash); target must act after the attacker |
| **Trapped** | Cannot switch (Wrap, Bind, Mean Look, Spider Web). Damage-trapping moves deal 1/16 max HP per turn |
| **Leech Seed** | Lose 1/8 max HP per turn; amount healed to the Seed planter. Grass-types are immune |
| **Curse (Ghost)** | Lose 1/4 max HP per turn |
| **Encore** | Locked into the last move used for 2–6 turns |
| **Taunt** | Cannot use status moves for 2 turns |

### 1.9 Weather

Weather lasts **5 turns** when summoned by a move, or indefinitely when summoned by an Ability.

| Weather | Move | Ability | Effects |
|---------|------|---------|---------|
| **Rain** | Rain Dance | Drizzle (Kyogre — not available in FRLG) | Water moves ×1.5; Fire moves ×0.5; Thunder never misses; SolarBeam power halved; Moonlight/Synthesis/Morning Sun heal 1/4 |
| **Harsh Sunlight** | Sunny Day | Drought (Groudon — not available in FRLG) | Fire moves ×1.5; Water moves ×0.5; SolarBeam skips charge turn; Thunder accuracy drops to 50%; Moonlight/Synthesis/Morning Sun heal 2/3 |
| **Sandstorm** | Sandstorm | Sand Stream (Tyranitar — available post-game) | Deals 1/16 max HP per turn to all Pokémon except Rock, Ground, and Steel types |
| **Hail** | Hail | — | Deals 1/16 max HP per turn to all Pokémon except Ice types |

Abilities that interact with weather: Swift Swim (×2 Speed in Rain), Chlorophyll (×2 Speed in Sun), Sand Veil (+20% evasion in Sandstorm), Rain Dish (1/16 HP recovery in Rain), Forecast (Castform type change).

### 1.10 Abilities

Introduced in Gen III. Each Pokémon species has 1 or 2 possible Abilities; an individual has exactly one, determined at encounter/hatch. There are **76 Abilities** in Gen III. Abilities cannot be changed.

Notable battle Abilities:

| Ability | Effect |
|---------|--------|
| Intimidate | Lowers foe's Attack by 1 stage on switch-in |
| Levitate | Immune to Ground-type moves |
| Huge Power / Pure Power | Doubles Attack stat |
| Speed Boost | Raises Speed by 1 stage each turn |
| Thick Fat | Halves damage from Fire and Ice moves |
| Sturdy | Immune to OHKO moves (Horn Drill, Fissure, etc.) — does not prevent fainting from regular damage in Gen III |
| Trace | Copies the opponent's Ability |
| Flash Fire | Immune to Fire moves; boosts own Fire moves by 1.5× when hit |
| Natural Cure | Cures status on switch-out |

Notable overworld Abilities:

| Ability | Overworld Effect |
|---------|-----------------|
| Flame Body / Magma Armor | Halves egg hatch step count (§12.4) |
| Illuminate / Arena Trap | Increases wild encounter rate |
| Stench / White Smoke | Decreases wild encounter rate |
| Pickup | Has a chance to find items after battle |
| Synchronize | 50% chance wild Pokémon shares the user's Nature |

### 1.11 Catching Pokémon

#### Catch Rate Formula (Gen III)

Modified catch rate:
```
a = (3 × HPmax − 2 × HPcurrent) / (3 × HPmax) × CatchRate × BallMod × StatusMod
```

If `a ≥ 255`, the Pokémon is caught. Otherwise, compute shake probability:
```
b = 1048560 / sqrt(sqrt(16711680 / a))
```

Four shake checks are performed. Each check generates a random number in [0, 65535]; the check passes if the random number is less than `b`. The Pokémon is caught if all four checks succeed.

#### Ball Modifiers

| Ball | Modifier | Condition |
|------|----------|-----------|
| Poké Ball | 1× | — |
| Great Ball | 1.5× | — |
| Ultra Ball | 2× | — |
| Master Ball | ∞ (guaranteed) | — |
| Safari Ball | 1.5× | Safari Zone only |
| Net Ball | 3× | Target is Bug or Water type |
| Dive Ball | 3.5× | Encounter while surfing or fishing |
| Nest Ball | (41 − Level) / 10 (min 1×) | — |
| Repeat Ball | 3× | Target species already registered in Pokédex |
| Timer Ball | (turns + 10) / 10 (max 4×) | Increases each turn |
| Luxury Ball | 1× | Doubles friendship gain rate |
| Premier Ball | 1× | Cosmetic only |

#### Status Bonuses

| Status | Modifier |
|--------|----------|
| Sleep, Freeze | 2× |
| Paralysis, Poison, Burn | 1.5× |
| None | 1× |

Species catch rates range from 3 (Mewtwo, Legendary Birds) to 255 (Magikarp, Caterpie).

### 1.12 Fleeing Wild Battles

```
EscapeOdds = (PartyLeadSpeed × 128 / WildSpeed) + 30 × EscapeAttempts
```

If `EscapeOdds ≥ 256`, fleeing always succeeds. Otherwise, a random number in [0, 255] is generated; flee succeeds if the random number is less than `EscapeOdds`. Each failed attempt increments the counter, making subsequent attempts more likely. Smoke Ball guarantees escape. Run Away ability guarantees escape.

### 1.13 PP (Power Points)

Each move has a base PP value (typically 5–40). A move can only be used while it has remaining PP. PP is restored by visiting a Pokémon Center, using Ether (restores 10 PP to one move), Max Ether (fully restores one move), Elixir (restores 10 PP to all moves), or Max Elixir (fully restores all moves). Leppa Berry restores 10 PP when PP reaches 0.

**PP Up**: Raises a move's max PP by 20% of its base PP. Can be used up to 3 times per move, for a maximum of 160% base PP. **PP Max** raises it to 160% in one use.

When a Pokémon runs out of PP on all moves, it uses **Struggle** — a typeless, 50-power physical move that deals 1/4 of the damage dealt as recoil to the user.

---

## 2. Controls & Input

Game Boy Advance — 10 inputs: D-Pad (4 directions), A, B, L, R, Start, Select.

### 2.1 Overworld

| Input | Action |
|-------|--------|
| D-Pad | Move character (4-directional, tile-based movement) |
| A | Interact (talk to NPC, examine object, confirm prompt) |
| B | Cancel / hold to run (requires Running Shoes, obtained early in Pewter City) |
| Start | Open main menu |
| Select | Use registered item (registered via the menu) |
| L | Help system (contextual tips) |
| R | — |

### 2.2 Battle

| Input | Action |
|-------|--------|
| D-Pad | Navigate menu options (Fight / Bag / Pokémon / Run) |
| A | Confirm selection |
| B | Back / cancel |
| L | — |
| R | — |

### 2.3 Menu / Text

| Input | Action |
|-------|--------|
| D-Pad | Navigate menu items |
| A | Confirm / advance text |
| B | Cancel / close menu / speed up text |
| Start | — |

### 2.4 Bicycle

The Bicycle is toggled via the Select button (when registered) or the Bag. Movement speed on the Bicycle is approximately **2× walking speed**. The Bicycle cannot be used indoors or in certain areas.

### 2.5 Fishing

Fishing uses the Old Rod, Good Rod, or Super Rod as a registered item. Press A when prompted ("Oh! A bite!") to initiate the encounter. Timing is not a factor — just press A when the prompt appears.

---

## 3. World Structure

### 3.1 Kanto Region — Main Game

The world consists of interconnected towns, cities, routes, and dungeons. Movement is tile-based on a 2D overhead grid. The map is divided into:

- **10 Towns/Cities**: Pallet Town, Viridian City, Pewter City, Cerulean City, Vermilion City, Lavender Town, Celadon City, Fuchsia City, Saffron City, Cinnabar Island
- **2 League areas**: Indigo Plateau, Victory Road
- **25 Routes**: Routes 1–25 plus Sea Routes connecting Cinnabar and the mainland
- **Major dungeons**: Mt. Moon, Rock Tunnel, Pokémon Tower, Silph Co., Seafoam Islands, Pokémon Mansion, Victory Road, Cerulean Cave (post-game)

### 3.2 Progression Gating

Progression is gated by HM moves (which require Badges to use in the overworld) and key items:

| Gate | Requirement | Unlocks Access To |
|------|------------|-------------------|
| Route 2 (Diglett's Cave side) | HM01 Cut (Cascade Badge) | Connects Vermilion ↔ Pewter |
| Rock Tunnel | HM05 Flash (Boulder Badge) | Lavender Town |
| Route 11 → Route 12 | Poké Flute (from Pokémon Tower) | Snorlax blocking routes |
| Cycling Road (Routes 16–18) | Bicycle | Celadon → Fuchsia shortcut |
| Saffron City | Defeat Team Rocket in Celadon hideout | Access from any guard gate (give guards drinks) |
| Seafoam Islands / Cinnabar | HM03 Surf (Soul Badge) | Water routes |
| Victory Road | HM04 Strength (Rainbow Badge) | Push boulders |
| Cerulean Cave | Beat the Elite Four | Mewtwo's dungeon |

### 3.3 HM Moves and Badge Requirements

| HM | Move | Badge Required | Overworld Use |
|----|------|---------------|---------------|
| HM01 | Cut | Cascade Badge (Misty) | Cut down small trees |
| HM02 | Fly | Thunder Badge (Lt. Surge) | Fly to visited towns |
| HM03 | Surf | Soul Badge (Koga) | Travel across water |
| HM04 | Strength | Rainbow Badge (Erika) | Push boulders |
| HM05 | Flash | Boulder Badge (Brock) | Illuminate dark caves |
| HM06 | Rock Smash | Marsh Badge (Sabrina) | Break cracked rocks |
| HM07 | Waterfall | Volcano Badge (Blaine) | Climb waterfalls |

### 3.4 Sevii Islands — Post-Game

Seven accessible islands (of nine total) south of Kanto, accessed in two phases:

**Phase 1 — After beating Blaine (7th Gym):**
- Celio on One Island gives the **Tri-Pass** granting access to Islands 1–3.
- Mandatory quest: retrieve the Ruby for Celio's Network Machine.
- Notable locations: Mt. Ember (Moltres), Berry Forest (Three Island).

**Phase 2 — After entering the Hall of Fame + obtaining the National Pokédex (requires ≥60 Pokédex entries):**
- Celio gives the **Rainbow Pass** granting access to Islands 4–7.
- Quest: retrieve the Sapphire for the Network Machine (enables trading with Ruby/Sapphire/Emerald).
- Notable locations: Icefall Cave (Four Island), Lost Cave (Five Island), Pattern Bush (Six Island), Trainer Tower and Tanoby Ruins/Unown (Seven Island).

### 3.5 Wild Encounter System

Encounters trigger via:
- **Walking in tall grass**: Each step has a probability of triggering a battle (approximately 8.5 per 187.5 steps ≈ ~4.5% per step in standard grass).
- **Surfing**: Similar step-based encounters on water tiles.
- **Fishing**: Rod-based trigger (Old Rod: Magikarp only; Good Rod: wider pool; Super Rod: best pool).
- **Cave walking**: Every step on cave floor tiles.

Each area has a **10-slot encounter table** for walking/surfing, with each slot having a weighted probability and a Pokémon/level range. Fishing has separate 5-slot tables per rod type.

**Repel**: Prevents encounters with wild Pokémon whose level is lower than the party lead's level. Three tiers: Repel (100 steps), Super Repel (200 steps), Max Repel (250 steps).

**Cleanse Tag**: Held item that reduces encounter rate by 2/3 when the holder is the party lead.

### 3.6 Time System

FireRed has **no real-time clock**. There is no day/night cycle, no time-based events, and no berry growing (berries regenerate via step counter in Berry Forest — see §9.2).

---

## 4. Playable Characters / Pokémon

### 4.1 Player Character

Choose one of two characters at the start: a male protagonist (default name: Red) or a female protagonist (default name: Leaf). The unchosen character does not appear. The rival (default name: Blue) is named by the player.

### 4.2 Starter Pokémon

Chosen from Professor Oak's lab at the start:

| Pokémon | Type | Base Stat Total | Evolution |
|---------|------|----------------|-----------|
| Bulbasaur | Grass/Poison | 318 | → Ivysaur (Lv 16) → Venusaur (Lv 32) |
| Charmander | Fire | 309 | → Charmeleon (Lv 16) → Charizard (Lv 36) |
| Squirtle | Water | 314 | → Wartortle (Lv 16) → Blastoise (Lv 36) |

The rival always picks the starter with a type advantage over the player's choice.

### 4.3 Pokédex

- **Kanto Pokédex**: 151 entries (#001 Bulbasaur – #151 Mew). 150 required for completion (Mew excluded).
- **National Pokédex**: 386 entries. Unlocked after entering the Hall of Fame with ≥60 Kanto Pokédex entries. Enables encountering Johto and Hoenn Pokémon on the Sevii Islands.

### 4.4 Legendary & Mythical Pokémon

| Pokémon | Type | Location | Catch Rate | Level |
|---------|------|----------|------------|-------|
| Articuno | Ice/Flying | Seafoam Islands | 3 | 50 |
| Zapdos | Electric/Flying | Power Plant | 3 | 50 |
| Moltres | Fire/Flying | Mt. Ember (One Island) | 3 | 50 |
| Mewtwo | Psychic | Cerulean Cave (post-game) | 3 | 70 |
| One of Raikou/Entei/Suicune | Various | Roaming Kanto (post-game, based on starter) | 3 | 50 |
| Deoxys | Psychic | Birth Island (event-only) | 3 | 30 |
| Ho-Oh / Lugia | Various | Navel Rock (event-only) | 3 | 70 |

The roaming beast depends on starter: Bulbasaur → Entei, Charmander → Suicune, Squirtle → Raikou.

**Roaming encounter mechanics**: The beast occupies a random route and moves to an adjacent route each time the player changes areas. It appears as a random wild encounter on its current route. In battle, it flees after one turn (before the player can act if slower). Damage dealt and status conditions persist between encounters. If KO'd, it is gone permanently. Mean Look / Spider Web prevent fleeing; Sleep and Freeze prevent its flee action. The roamer's IVs are generated when it first begins roaming, not at each encounter. A roaming Pokémon's location can be tracked via the Pokédex's Area function after the first encounter.

### 4.5 Party System

- Maximum party size: **6 Pokémon**.
- Pokémon Storage: **Bill's PC** — 14 boxes × 30 slots = **420 storage slots**.
- Party order matters: the lead Pokémon is sent into battle first, its Ability has overworld effects (§1.10), and its level determines Repel effectiveness.

### 4.6 Evolution Methods

| Method | Examples |
|--------|---------|
| **Level-up** | Most Pokémon (e.g., Charmander → Charmeleon at Lv 16) |
| **Stone** | Fire Stone (Vulpix → Ninetales), Water Stone (Poliwhirl → Poliwrath), Thunder Stone (Pikachu → Raichu), Leaf Stone (Gloom → Vileplume), Moon Stone (Clefairy → Clefable) |
| **Trade** | Kadabra → Alakazam, Machoke → Machamp, Graveler → Golem, Haunter → Gengar |
| **Trade with item** | Poliwhirl + King's Rock → Politoed, Slowpoke + King's Rock → Slowking, Onix + Metal Coat → Steelix, Scyther + Metal Coat → Scizor, Seadra + Dragon Scale → Kingdra, Clamperl + DeepSeaTooth → Huntail, Clamperl + DeepSeaScale → Gorebyss |
| **Friendship (≥220)** | Golbat → Crobat, Chansey → Blissey, Eevee → Espeon (day) / Umbreon (night) — **Note**: Since FRLG has no clock, Espeon/Umbreon cannot evolve in FRLG; must trade to Ruby/Sapphire/Emerald |

### 4.7 Friendship

Range: **0–255**. Base friendship is species-specific (typically 70). Evolution threshold: **220**.

| Action | Change |
|--------|--------|
| Level up | +2 (0–99), +2 (100–199), +1 (200–255) |
| Walk 256 steps | +1 (0–199), +0 (200+) |
| Vitamin | +2 / +1 / +0 (by friendship tier) |
| EV berry | +2 / +2 / +1 |
| Faint | −1 |
| Bitter medicine (Revival Herb, etc.) | −5 to −10 |
| Daisy Oak massage (Pallet Town) | +3 / +3 / +3 |

**Soothe Bell**: Boosts all positive friendship changes by 50%.

Friendship checker: Daisy Oak in Pallet Town provides a qualitative description.

---

## 5. Story & Progression

### 5.1 Main Story Structure

The game follows a linear progression with 8 Gym Badges leading to the Pokémon League:

1. **Pallet Town** — Receive starter Pokémon and Pokédex from Professor Oak.
2. **Pewter City** — Gym 1: Brock (Rock). Earn Boulder Badge.
3. **Cerulean City** — Gym 2: Misty (Water). Earn Cascade Badge.
4. **Vermilion City** — Board the S.S. Anne; Gym 3: Lt. Surge (Electric). Earn Thunder Badge.
5. **Lavender Town** — Pokémon Tower storyline (Team Rocket, Silph Scope required).
6. **Celadon City** — Gym 4: Erika (Grass). Earn Rainbow Badge. Raid Team Rocket's Game Corner hideout.
7. **Saffron City** — Clear Silph Co. headquarters (defeat Giovanni). Gym 6: Sabrina (Psychic). Earn Marsh Badge.
8. **Fuchsia City** — Gym 5: Koga (Poison). Earn Soul Badge. Safari Zone access.
9. **Cinnabar Island** — Gym 7: Blaine (Fire). Earn Volcano Badge. Sevii Islands Phase 1 unlocks.
10. **Viridian City** — Gym 8: Giovanni (Ground). Earn Earth Badge.
11. **Indigo Plateau** — Victory Road → Elite Four → Champion.

Koga and Sabrina's Gyms (5th/6th) can be tackled in either order.

### 5.2 Gym Leaders

| # | Leader | City | Type | Team | TM Reward |
|---|--------|------|------|------|-----------|
| 1 | Brock | Pewter City | Rock | Geodude (12), Onix (14) | TM39 Rock Tomb |
| 2 | Misty | Cerulean City | Water | Staryu (18), Starmie (21) | TM03 Water Pulse |
| 3 | Lt. Surge | Vermilion City | Electric | Voltorb (21), Pikachu (18), Raichu (24) | TM34 Shock Wave |
| 4 | Erika | Celadon City | Grass | Victreebel (29), Tangela (24), Vileplume (29) | TM19 Giga Drain |
| 5 | Koga | Fuchsia City | Poison | Koffing (37), Koffing (37), Muk (39), Weezing (43) | TM06 Toxic |
| 6 | Sabrina | Saffron City | Psychic | Kadabra (38), Mr. Mime (37), Venomoth (38), Alakazam (43) | TM04 Calm Mind |
| 7 | Blaine | Cinnabar Island | Fire | Growlithe (42), Ponyta (40), Rapidash (42), Arcanine (47) | TM38 Fire Blast |
| 8 | Giovanni | Viridian City | Ground | Rhyhorn (45), Dugtrio (42), Nidoqueen (44), Nidoking (45), Rhydon (50) | TM26 Earthquake |

### 5.3 Elite Four & Champion

Fought consecutively without access to a Pokémon Center between battles:

| Member | Type Focus | Team |
|--------|-----------|------|
| **Lorelei** | Ice | Dewgong (52), Cloyster (51), Slowbro (52), Jynx (54), Lapras (54) |
| **Bruno** | Fighting | Onix (51), Hitmonchan (53), Hitmonlee (53), Onix (54), Machamp (56) |
| **Agatha** | Ghost/Poison | Gengar (54), Golbat (54), Haunter (53), Arbok (56), Gengar (58) |
| **Lance** | Dragon | Gyarados (56), Dragonair (54), Dragonair (54), Aerodactyl (58), Dragonite (60) |

**Champion Blue** — Team varies by player's starter:

| If Player Chose | Blue's Team |
|----------------|-------------|
| Bulbasaur | Pidgeot (59), Alakazam (57), Rhydon (59), Exeggutor (59), Gyarados (61), Charizard (63) |
| Charmander | Pidgeot (59), Alakazam (57), Rhydon (59), Arcanine (59), Exeggutor (61), Blastoise (63) |
| Squirtle | Pidgeot (59), Alakazam (57), Rhydon (59), Gyarados (59), Arcanine (61), Venusaur (63) |

Blue always has Pidgeot, Alakazam, and Rhydon regardless of starter.

### 5.4 Obedience Levels for Traded Pokémon

| Badges Obtained | Max Obedient Level |
|-----------------|-------------------|
| 0 | 10 |
| 1 (Boulder) | 20 |
| 2 (Cascade) | 30 |
| 3 (Thunder) | 40 |
| 4 (Rainbow) | 50 |
| 5 (Soul) | 60 |
| 6 (Marsh) | 70 |
| 7 (Volcano) | 80 |
| 8 (Earth) | All levels |

Self-caught Pokémon always obey. Disobedient Pokémon may: ignore commands, use a random move, do nothing ("loafing around"), or fall asleep.

### 5.5 Post-Game Content

- **Cerulean Cave**: Mewtwo at Lv 70.
- **Elite Four rematch**: Upgraded teams (~10 levels higher, expanded rosters, wider type coverage).
- **Sevii Islands 4–7**: New areas, Johto Pokémon encounters, Team Rocket remnant storyline.
- **Roaming Legendary Beast**: Based on starter choice (§4.4).
- **National Pokédex completion**: Requires trading with LeafGreen, Ruby, Sapphire, Emerald, and Colosseum/XD.

---

## 6. Items & Equipment

### 6.1 Item Categories

Items are stored in a multi-pocket Bag:

| Pocket | Contents |
|--------|----------|
| Items | General consumables, mail |
| Key Items | Story-critical items (cannot be sold/discarded) |
| Poké Balls | All ball types |
| TMs & HMs | Technical and Hidden Machines |
| Berries | All berry types |

### 6.2 Healing Items

| Item | Effect | Buy Price | Sell Price |
|------|--------|-----------|------------|
| Potion | Restore 20 HP | ¥300 | ¥150 |
| Super Potion | Restore 50 HP | ¥700 | ¥350 |
| Hyper Potion | Restore 200 HP | ¥1,200 | ¥600 |
| Max Potion | Restore all HP | ¥2,500 | ¥1,250 |
| Full Restore | Restore all HP + cure status | ¥3,000 | ¥1,500 |
| Revive | Revive fainted Pokémon to 50% HP | ¥1,500 | ¥750 |
| Max Revive | Revive fainted Pokémon to 100% HP | — (found only) | ¥2,000 |
| Antidote | Cure Poison | ¥100 | ¥50 |
| Burn Heal | Cure Burn | ¥250 | ¥125 |
| Ice Heal | Cure Freeze | ¥250 | ¥125 |
| Awakening | Cure Sleep | ¥250 | ¥125 |
| Parlyz Heal | Cure Paralysis | ¥200 | ¥100 |
| Full Heal | Cure any status | ¥600 | ¥300 |
| Lemonade | Restore 80 HP | ¥350 | ¥175 |
| Soda Pop | Restore 60 HP | ¥300 | ¥150 |
| Fresh Water | Restore 50 HP | ¥200 | ¥100 |
| Moo Moo Milk | Restore 100 HP | ¥500 | ¥250 |

### 6.3 Vitamins

| Vitamin | EV Boosted | Buy Price |
|---------|-----------|-----------|
| HP Up | HP | ¥9,800 |
| Protein | Attack | ¥9,800 |
| Iron | Defense | ¥9,800 |
| Calcium | Sp. Atk | ¥9,800 |
| Zinc | Sp. Def | ¥9,800 |
| Carbos | Speed | ¥9,800 |
| Rare Candy | Raises level by 1 | — (found only) |

### 6.4 Battle Items (Used from Bag in Battle)

| Item | Effect | Buy Price |
|------|--------|-----------|
| X Attack | +1 Attack stage | ¥500 |
| X Defend | +1 Defense stage | ¥550 |
| X Speed | +1 Speed stage | ¥350 |
| X Special | +1 Sp. Atk stage | ¥350 |
| X Accuracy | +1 Accuracy stage | ¥950 |
| Dire Hit | +1 critical hit stage | ¥650 |
| Guard Spec. | Prevents stat reduction for 5 turns | ¥700 |

### 6.5 Held Items (Key Examples)

| Item | Effect |
|------|--------|
| Leftovers | Recover 1/16 max HP per turn |
| Shell Bell | Recover 1/8 of damage dealt |
| Choice Band | Attack ×1.5, locked into one move |
| Scope Lens | +1 critical hit stage |
| King's Rock | 10% flinch chance on damaging moves |
| Quick Claw | 20% chance to move first |
| Focus Band | 10% chance to survive a KO at 1 HP |
| Bright Powder | −10% opponent accuracy |
| Macho Brace | Doubles EV gain, halves Speed in battle |
| Lucky Egg | ×1.5 EXP gained |
| Soothe Bell | ×1.5 friendship gain (see §4.7) |
| Amulet Coin | Doubles prize money (must participate in battle) |
| Smoke Ball | Guarantees escape from wild battles |
| EXP Share | Holder receives 50% of battle EXP without participating |
| Sitrus Berry | Restores 30 HP when HP drops below 50% |
| Lum Berry | Cures any status condition once |

### 6.6 Key Items

| Item | Purpose | Source |
|------|---------|--------|
| Town Map | View Kanto map | Rival's sister (Pallet Town) |
| Bicycle | ×2 movement speed | Bike Voucher → Cerulean Bike Shop |
| Old Rod / Good Rod / Super Rod | Fishing (progressively better encounter pools) | Various NPCs |
| Silph Scope | See Ghost-type Pokémon in Pokémon Tower | Celadon Game Corner Hideout |
| Poké Flute | Wake sleeping Snorlax | Mr. Fuji (Pokémon Tower) |
| Itemfinder | Detect hidden items nearby | Route 11 aide |
| VS Seeker | Rematch previously battled trainers (requires 100 steps to recharge) | Vermilion City |
| Teachy TV | Tutorial device | Route 3 |
| Fame Checker | Collects info on notable characters | Celadon City |
| Tri-Pass | Access to Sevii Islands 1–3 | Celio (One Island) |
| Rainbow Pass | Access to Sevii Islands 4–7 | Celio (One Island, post-game) |
| Ruby / Sapphire | Network Machine gems for Gen III trading | Sevii Islands quests |

### 6.7 TMs (Technical Machines)

50 single-use TMs. Gym Leaders award TMs upon defeat. Others are found, purchased, or won as prizes. Key TMs:

| TM | Move | Source |
|----|------|--------|
| TM01 | Focus Punch | Silph Co. |
| TM13 | Ice Beam | Game Corner (4,000 coins) |
| TM24 | Thunderbolt | Game Corner (4,000 coins) |
| TM26 | Earthquake | Giovanni (Gym 8) |
| TM29 | Psychic | Saffron City |
| TM35 | Flamethrower | Game Corner (4,000 coins) |
| TM36 | Sludge Bomb | Team Rocket Warehouse |
| TM38 | Fire Blast | Blaine (Gym 7) |
| TM44 | Rest | S.S. Anne |

### 6.8 Move Tutors

16 one-time move tutors scattered across Kanto and the Sevii Islands:

| Move | Location |
|------|----------|
| Mega Punch / Mega Kick | Mt. Moon entrance (Cerulean side) |
| Seismic Toss | Pewter Museum (back entrance) |
| Counter | Celadon Dept. Store |
| Softboiled | Celadon City (pond) |
| Rock Slide | Rock Tunnel |
| Mimic | Saffron City (Copycat's house) |
| Thunder Wave | Silph Co. |
| Substitute | Fuchsia City |
| Dream Eater | Viridian City |
| Metronome | Cinnabar Lab |
| Double-Edge | Victory Road |
| Explosion | One Island |
| Body Slam | Four Island |
| Swords Dance | Seven Island |

Plus the **elemental move tutor** on Two Island (teaches Blast Burn, Hydro Cannon, or Frenzy Plant to fully evolved starters with max friendship).

---

## 7. Enemies & Opponents

### 7.1 Trainer Classes

Trainers are fixed encounters on routes and in dungeons. Once defeated, they do not re-battle unless the **VS Seeker** is used (and they are outdoors). Trainer classes include: Bug Catcher, Youngster, Lass, Hiker, Swimmer, Ace Trainer (Cooltrainer), Psychic, Black Belt, Fisherman, Bird Keeper, Rocket Grunt, Scientist, and more.

### 7.2 Team Rocket

The antagonist organization, encountered at:
- Mt. Moon (early grunt encounters)
- Nugget Bridge (Cerulean City)
- Celadon Game Corner (underground hideout — first Giovanni fight)
- Pokémon Tower (Lavender Town)
- Silph Co. (Saffron City — second Giovanni fight)
- Sevii Islands (post-game — Team Rocket Warehouse on Five Island)

Giovanni serves as both Team Rocket's leader and the 8th Gym Leader.

### 7.3 Rival Battles

Blue is fought at multiple story points with escalating teams:
1. Professor Oak's Lab (starter only, Lv 5)
2. Route 22 (two Pokémon)
3. Cerulean City
4. S.S. Anne
5. Pokémon Tower
6. Silph Co.
7. Route 22 (pre-Victory Road)
8. Champion battle (full team of 6)

### 7.4 Trainer AI

Trainer AI operates on a scoring system with multiple flags that vary by trainer class:

| AI Level | Behavior |
|----------|----------|
| 0 | Avoids blatantly useless moves (e.g., stat-boosting at +6) |
| 1 | Basic damage-type awareness |
| 2 | Considers whether moves will KO |
| 3 | Prioritizes status moves on the first turn |
| 4 | Weighs secondary move effects |
| 8 | Factors in HP percentages for healing/switching decisions |

Gym Leaders and Elite Four members use higher AI levels. Regular trainers vary.

---

## 8. Economy

### 8.1 Currency

**Pokémon Dollars (¥)** — earned from trainer battles (amount = base payout × highest-level Pokémon on losing team / scaling factor). Amulet Coin doubles payout. Maximum wallet: **¥999,999**.

### 8.2 Poké Mart Inventory by Progression

Mart inventory expands as the player earns more badges:

| City | Notable Stock |
|------|---------------|
| Viridian City | Poké Ball (¥200), Potion (¥300), Antidote (¥100) |
| Pewter City | Poké Ball, Potion, Escape Rope (¥550), Repel (¥350) |
| Cerulean City | Super Potion (¥700), Great Ball (¥600), Repel |
| Vermilion City | Super Potion, Great Ball, Super Repel (¥500) |
| Lavender Town | Great Ball, Super Potion, Revive (¥1,500) |
| Celadon Dept. Store | Full inventory including TMs, evolution stones, stat items, vitamins |
| Fuchsia City | Ultra Ball (¥1,200), Hyper Potion, Max Repel (¥700) |
| Cinnabar / Saffron | Ultra Ball, Hyper Potion, Full Heal |
| Indigo Plateau | Ultra Ball, Full Restore, Max Potion, Revive |

### 8.3 Celadon Department Store

A multi-floor store with the broadest inventory in the game:
- **2F**: TMs (varied selection)
- **3F**: TV Game merchandise
- **4F**: Evolution Stones (Fire Stone, Water Stone, Thunder Stone, Leaf Stone — ¥2,100 each)
- **5F**: Vitamins (¥9,800 each), stat-boosting battle items
- **Rooftop**: Vending machines (Fresh Water ¥200, Soda Pop ¥300, Lemonade ¥350)

### 8.4 Poké Ball Pricing

| Ball | Price |
|------|-------|
| Poké Ball | ¥200 |
| Great Ball | ¥600 |
| Ultra Ball | ¥1,200 |
| (Buy 10+ Poké Balls → 1 free Premier Ball) | — |

### 8.5 Income Sources

| Source | Amount |
|--------|--------|
| Trainer battles | Varies (base payout × level multiplier) |
| VS Seeker rematches | Repeatable trainer income |
| Pay Day move | Scatter coins equal to 2× user's level per use |
| Amulet Coin / Luck Incense | Doubles battle prize money |
| Selling items | 50% of buy price |
| Nugget (¥5,000), Big Pearl (¥3,750), Star Piece (¥4,900), Big Mushroom (¥2,500) | Sell-only treasures |
| Pickup Ability | Random item finds after battle |

---

## 9. Minigames & Side Systems

### 9.1 Safari Zone

Located in Fuchsia City. Admission: **¥500** per visit.

- **30 Safari Balls** provided; no regular Poké Balls allowed.
- **500-step limit** per visit (not 600 — counter is 500 steps).
- No battling — instead, each turn offers: **Throw Ball**, **Throw Bait**, **Throw Rock**, or **Run**.

| Action | Catch Rate Effect | Flee Rate Effect |
|--------|------------------|-----------------|
| Throw Ball | Attempts catch | — |
| Throw Bait | Decreases catch rate | Decreases flee rate |
| Throw Rock | Increases catch rate | Increases flee rate |

Bait/Rock effects modify internal counters that persist across turns. The Safari Zone contains Pokémon unavailable elsewhere: Kangaskhan, Tauros, Chansey, Scyther/Pinsir (version-exclusive), Dratini (Super Rod).

The Safari Zone Warden gives **HM04 Strength** in exchange for the Gold Teeth found in the Safari Zone.

### 9.2 Berry Forest

Located on Three Island (Sevii Islands). The only renewable source of berries in FRLG. Since the game has no real-time clock, **berries regenerate every ~1,500 steps** after being collected.

Berry rarity tiers:
- **Common (60%)**: Razz, Nanab, Chesto, Pecha, Rawst
- **Uncommon (30%)**: Bluk, Wepear, Oran, Cheri, Aspear, Persim, Pinap
- **Rare (10%)**: Lum Berry and others

### 9.3 Celadon Game Corner

Slot machine gambling in Celadon City. Requires the **Coin Case** (obtained from the Game Corner patron in the restaurant).

- **Coins**: Buy at ¥1,000 for 50 coins or ¥10,000 for 500 coins (exchange rate: ¥20 per coin).
- **Slots**: Bet 1–3 coins per spin. 1 coin = center row only; 2 coins = all 3 rows; 3 coins = 3 rows + diagonals.
- **Jackpot**: Triple 7s = 300 coins.
- Hidden coins can be found on the Game Corner floor using the Itemfinder.

#### Prize Exchange (FireRed)

**Pokémon Prizes:**

| Pokémon | Level | Cost |
|---------|-------|------|
| Abra | 9 | 180 coins |
| Clefairy | 8 | 500 coins |
| Dratini | 18 | 2,800 coins |
| Scyther | 25 | 5,500 coins |
| Porygon | 26 | 9,999 coins |

**TM Prizes:**

| TM | Move | Cost |
|----|------|------|
| TM13 | Ice Beam | 4,000 coins |
| TM23 | Iron Tail | 3,500 coins |
| TM24 | Thunderbolt | 4,000 coins |
| TM35 | Flamethrower | 4,000 coins |

LeafGreen has a different Pokémon prize pool (Pinsir instead of Scyther; different levels and costs).

### 9.4 Berry Crush

Multiplayer minigame on Two Island. Requires the **Powder Jar** (obtained from a man in Cerulean City) and a link cable / wireless adapter with 2–5 players. Players crush berries together by pressing A in rhythm to produce Berry Powder, which can be exchanged for medicine items.

### 9.5 Pokédex Completion

Professor Oak's aides on various routes give rewards for reaching Pokédex milestones (number of species caught):

| Pokémon Caught | Reward | Location |
|----------------|--------|----------|
| 10 | HM05 Flash | Route 2 |
| 20 | Itemfinder | Route 11 |
| 30 | Amulet Coin | Route 2 (requires Cut) |
| 40 | EXP Share | Route 15 |

### 9.6 In-Game Trades

Several NPCs offer fixed trades throughout the game. Traded Pokémon arrive with a set OT, nickname, and nature. They gain the 1.5× EXP bonus but are subject to obedience level caps (§5.4). Notable trades include:

| Location | You Give | You Receive |
|----------|----------|-------------|
| Route 2 | Abra | Mr. Mime |
| Cerulean City | Poliwhirl | Jynx |
| Vermilion City | Spearow | Farfetch'd |
| Route 18 | Golduck | Lickitung |
| Cinnabar Lab | Raichu | Electrode |
| Cinnabar Lab | Venonat | Tangela |
| Cinnabar Lab | Ponyta | Seel |

### 9.7 Trainer Tower

Located on Seven Island (post-game). A challenge tower with Single, Double, Mixed, and Knockout battle formats. Players race to the top as fast as possible; records are saved. Contains pre-set trainer teams rather than random opponents.

---

## 10. UI & HUD

### 10.1 Overworld HUD

The overworld has **no persistent HUD**. The screen shows the game world only. Information is accessed via:
- **Start Menu**: Pokédex, Pokémon (party), Bag, [Player Name], Save, Options
- **Text boxes**: Appear at the bottom of the screen for dialogue, system messages, and item pickups
- **Location banner**: Appears briefly when entering a new area (town name or route number)

### 10.2 Battle HUD

| Element | Position | Contents |
|---------|----------|----------|
| Player's Pokémon info | Bottom-right | Name, Level, Gender icon, HP bar (green/yellow/red), HP numbers (current/max), EXP bar, status condition icon |
| Opponent's Pokémon info | Top-left | Name, Level, Gender icon, HP bar (no numbers for wild; no numbers for trainers), status condition icon |
| Action menu | Bottom | FIGHT / BAG / POKéMON / RUN (4-quadrant layout) |
| Move selection | Bottom | 4 moves listed with PP (current/max); move type shown on selection |
| Pokémon sprites | Center | Player's Pokémon (back sprite, bottom-left); opponent (front sprite, top-right) |

HP bar color thresholds:
- **Green**: >50% HP
- **Yellow**: 21–50% HP
- **Red**: ≤20% HP (flashing with audio beep)

### 10.3 Menu Screens

**Start Menu** (7 options, expandable):
1. **Pokédex** — Browse seen/caught Pokémon; filter by Habitat, type, alphabetical, weight, or height
2. **Pokémon** — View party; reorder by dragging; view Summary (stats, moves, ribbons, condition); use field moves
3. **Bag** — 5-pocket inventory (§6.1); sort, use, give, or toss items
4. **[Player Name]** — Trainer Card showing: name, ID, playtime, money, Pokédex count, badges earned
5. **Save** — Single save slot; overwrites previous save with confirmation prompt
6. **Options** — Text speed (Slow/Mid/Fast), Battle Scene (on/off), Battle Style (Shift/Set), Sound (Mono/Stereo), Button Mode (Normal/LR/L=A)
7. **Help** — Contextual assistance via the Teachy TV / Help system

### 10.4 In-Battle Indicators

- **Effectiveness text**: "It's super effective!", "It's not very effective...", "It doesn't affect [Pokémon]..."
- **Critical hit text**: "A critical hit!"
- **Status infliction**: "[Pokémon] was poisoned!", "[Pokémon] fell asleep!", etc.
- **Stat changes**: "[Pokémon]'s Attack rose!", "[Pokémon]'s Defense fell!"
- **Weather text**: "Rain continues to fall.", "The sandstorm rages.", etc.
- **Ability activation**: "[Pokémon]'s Intimidate!" (shown on switch-in)

---

## 11. Engine & Presentation Systems

### 11.1 Save System

- **Single save file** per cartridge.
- Save data stored on the cartridge's flash memory (128 KB).
- Saving takes approximately 3–5 seconds with a progress indicator.
- Soft reset: **A + B + Start + Select** simultaneously returns to the title screen without saving.
- Starting a new game while a save exists requires explicit confirmation to overwrite.

### 11.2 Dialogue System

- NPC dialogue is displayed in a text box at the bottom of the screen.
- Text speed is configurable (Slow / Mid / Fast) in Options.
- Pressing B fast-forwards text.
- Some dialogues offer Yes/No choices.
- Key story moments feature full-screen event sequences.

### 11.3 Camera

Fixed, top-down perspective. The camera is always centered on the player character in the overworld. No rotation, zoom, or free camera. Interiors and caves use the same perspective with different tilesets.

### 11.4 Audio System

- Background music changes per area/route/battle type.
- Battle music: Wild battle theme, Trainer battle theme, Gym Leader theme, Elite Four theme, Champion theme, Legendary theme.
- Low HP beep: A rapid beeping tone plays when the active Pokémon's HP bar is red (≤20%).
- Pokémon cries: Each species has a unique synthesized cry played on encounter, sending into battle, fainting, and in the Pokédex.
- Sound modes: Mono or Stereo (selectable in Options).

### 11.5 Battle Style Options

- **Shift** (default): After KOing an opponent's Pokémon, the player is prompted to switch before the next Pokémon is sent out.
- **Set**: No switch prompt after KOs — behaves like competitive play.

### 11.6 Difficulty

No selectable difficulty. The game has a fixed difficulty curve. The only player-controlled difficulty modifier is Battle Style (Shift vs. Set, §11.5).

### 11.7 Trading & Connectivity

- **Link Cable**: Trade and battle with another GBA player.
- **Wireless Adapter** (bundled with FRLG): Wireless trading, battling, Berry Crush, and Union Room functionality.
- **Trading restrictions**: Cannot trade with Ruby/Sapphire/Emerald until the Network Machine on One Island is completed (requires Ruby and Sapphire gems from Sevii Islands, post-game).
- **Pal Park** (Gen IV): One-way transfer to Diamond/Pearl/Platinum via dual-slot DS.

---

## 12. Breeding

Available post-game only. The **Day Care** is on Four Island (Sevii Islands).

### 12.1 Compatibility Rules

- Two Pokémon can breed if they share at least one **Egg Group** and have opposite genders.
- **Ditto** breeds with any Pokémon that can breed, regardless of gender or Egg Group.
- Pokémon in the **No Eggs Discovered** group (most Legendaries, baby Pokémon) cannot breed.
- Genderless Pokémon can only breed with Ditto.

### 12.2 Egg Groups (15 Total)

Monster, Water 1, Water 2, Water 3, Bug, Flying, Field, Fairy, Grass, Human-Like, Mineral, Amorphous, Dragon, Ditto, No Eggs Discovered.

### 12.3 Egg Production

- The Day Care Man steps into the yard when an egg is ready.
- Egg chance per 256 steps depends on compatibility:

| Compatibility | Chance per 256 Steps |
|---------------|---------------------|
| Same species, different OT | 69.3% |
| Same species, same OT | 49.5% |
| Different species, different OT | 49.5% |
| Different species, same OT | 19.8% |

### 12.4 Hatching

- Each species has an **egg cycle count** (e.g., Magikarp = 5 cycles, Dratini = 40 cycles).
- **1 egg cycle = 256 steps** in Gen III.
- Pokémon with **Flame Body** or **Magma Armor** in the party halve the required egg cycles.
- Hatched Pokémon are **Lv 5** in Gen III.

### 12.5 Inheritance

- **Species**: Offspring is the base form of the mother's evolutionary line (or the non-Ditto parent's line if Ditto is used).
- **IVs**: 3 IVs are inherited from parents (one parent contributes 2, the other contributes 1); 3 are random.
- **Moves**: The offspring knows level-up moves it would have at Lv 5, plus any moves both parents know that the baby can learn by level-up, plus TM/HM moves the father knows that are compatible with the offspring, plus Egg Moves from the father's Egg Move list.
- **Nature**: Random (no Everstone inheritance in Gen III FRLG — this was added in Emerald).
- **Ability**: Random from the species' available abilities (no inheritance mechanic in Gen III).

### 12.6 Day Care Leveling

Pokémon left in the Day Care gain **1 EXP per step** the player takes. They do not gain EVs. Moves are replaced in order (oldest move overwritten first) as the Pokémon levels up. The Day Care does not trigger evolution.

---

## 13. Open Questions / Unverified

1. **Exact Safari Zone catch/flee formulas**: The internal counters modified by Bait and Rock are well-documented in decompilation projects, but the exact per-species anomalies (e.g., Chansey's inverted bait response) vary between sources.
2. **Trainer prize money formula**: Base payout values per trainer class are documented in the ROM, but the exact scaling formula (base × level of last Pokémon sent out) has minor source discrepancies.
3. **Slot machine RNG**: Whether the Game Corner slots use true RNG or a biased pseudo-RNG favoring the house is debated; decompilation suggests a per-machine "luck" value exists.
4. **Roaming beast IV bug**: In Gen III, a known bug causes roaming Pokémon to retain only their HP IV correctly; the other 5 IVs are regenerated (and tend to be very low) each time the roamer is encountered. Whether FireRed specifically exhibits this behavior or only Ruby/Sapphire is disputed.

---

## 14. References

### Wikis & Databases
- [Bulbapedia — Damage](https://bulbapedia.bulbagarden.net/wiki/Damage)
- [Bulbapedia — Stat](https://bulbapedia.bulbagarden.net/wiki/Stat)
- [Bulbapedia — Catch Rate](https://bulbapedia.bulbagarden.net/wiki/Catch_rate)
- [Bulbapedia — Critical Hit](https://bulbapedia.bulbagarden.net/wiki/Critical_hit)
- [Bulbapedia — Status Condition](https://bulbapedia.bulbagarden.net/wiki/Status_condition)
- [Bulbapedia — Priority](https://bulbapedia.bulbagarden.net/wiki/Priority)
- [Bulbapedia — Weather](https://bulbapedia.bulbagarden.net/wiki/Weather)
- [Bulbapedia — Pokémon Breeding](https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_breeding)
- [Bulbapedia — Friendship](https://bulbapedia.bulbagarden.net/wiki/Friendship)
- [Bulbapedia — Effort Values](https://bulbapedia.bulbagarden.net/wiki/Effort_values)
- [Bulbapedia — Celadon Game Corner](https://bulbapedia.bulbagarden.net/wiki/Celadon_Game_Corner)
- [Bulbapedia — Sevii Islands](https://bulbapedia.bulbagarden.net/wiki/Sevii_Islands)
- [Pokémon Database — FireRed/LeafGreen Gym Leaders & Elite Four](https://pokemondb.net/firered-leafgreen/gymleaders-elitefour)
- [Serebii — FireRed/LeafGreen TMs & HMs](https://www.serebii.net/fireredleafgreen/tmhm.shtml)
- [Serebii — FireRed/LeafGreen Berry Crush](https://www.serebii.net/fireredleafgreen/berrycrush.shtml)

### Strategy Guides
- [StrategyWiki — Pokémon FireRed and LeafGreen](https://strategywiki.org/wiki/Pok%C3%A9mon_FireRed_and_LeafGreen)
- [PsyPokes — RSE/FRLG Battle Chart](https://www.psypokes.com/rsefrlg/battlechart.php)
- [PsyPokes — RSE/FRLG Breeding Guide](https://www.psypokes.com/rsefrlg/breeding.php)
- [PsyPokes — RSE/FRLG Abilities List](https://www.psypokes.com/rsefrlg/abilities.php)

### Community Guides
- [Game8 — Pokémon FireRed and LeafGreen Guides](https://game8.co/games/Pokemon-FireRed-LeafGreen)
- [GameFAQs — Pokémon FireRed Version](https://gamefaqs.gamespot.com/gba/918915-pokemon-firered-version)
- [Smogon — Move Priority](https://www.smogon.com/bw/articles/priority)
- [The Cave of Dragonflies — Gen III/IV Catch Rate Calculator](https://www.dragonflycave.com/calculators/gen-iii-iv-catch-rate/)

### Decompilation
- [pret/pokefirered (GitHub)](https://github.com/pret/pokefirered) — Community-maintained C decompilation of the FireRed ROM; authoritative source for formula verification.
