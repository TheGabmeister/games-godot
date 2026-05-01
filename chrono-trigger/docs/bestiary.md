# Chrono Trigger — Enemy & Boss Data Tables

Referenced from [SPEC.md §9](../SPEC.md). SNES original names used throughout.

**Data confidence:** Values marked `(*)` are cross-verified across 2+ sources. Values marked `(~)` came from a single source or had minor discrepancies — verify against ROM data ([Data Crystal](https://datacrystal.tcrf.net/wiki/Chrono_Trigger_(SNES)/List_of_Enemies)) before locking.

**Companion docs:** Boss AI patterns (attacks, phases, counters) are in [docs/boss-ai.md](boss-ai.md). Regular enemy behavior (paired mechanics, state changes, counters) is in the "Regular Enemy Behavior" section at the bottom of this file.

---

## Regular Enemies by Era

### 1000 AD

| Name | HP | EXP | G | TP | Weakness | Drop | Charm | Location |
|---|---:|---:|---:|---:|---|---|---|---|
| Beetle | 12(*) | 1 | 1 | 1 | — | — | — | Guardia Forest |
| Green Imp | 32(*) | 3 | 3 | 1 | — | Tonic | — | Guardia Forest |
| Roly | 24(*) | 2 | 2 | 1 | — | — | — | Guardia Forest |
| Blue Imp | 13(*) | 2 | 6 | 1 | — | Tonic | — | Truce Canyon |
| Roly Rider | 30(~) | 3 | 6 | 1 | — | — | — | Truce Canyon |
| Hetake | 14(~) | 2 | 5 | 1 | — | — | — | Guardia Forest |
| Blue Eaglet | 16(~) | 2 | 4 | 1 | — | — | — | Guardia Forest |
| Avian Chaos | 45(~) | 4 | 8 | 1 | — | — | — | Guardia Forest |
| Naga-ette | 60(*) | 6 | 10 | 1 | — | Tonic | — | Guardia Castle |
| Blue Shield | 24(*) | 3 | 5 | 1 | — | — | — | Prison |
| Decedent | 67(~) | 6 | 10 | 1 | Fire | — | — | Prison |
| Guard | 60(*) | 5 | 8 | 1 | — | Tonic | — | Prison |
| Omnicrone | 218(*) | 22 | 55 | 1 | — | — | — | Prison |
| Hench | 49(*) | 11 | 135 | 1 | — | — | — | Cathedral |

### 600 AD

| Name | HP | EXP | G | TP | Weakness | Drop | Charm | Location |
|---|---:|---:|---:|---:|---|---|---|---|
| Blue Imp | 13(*) | 2 | 6 | 1 | — | Tonic | — | Truce Canyon |
| Roly Rider | 30(~) | 3 | 6 | 1 | — | — | — | Truce Canyon |
| Green Imp | 32(*) | 3 | 3 | 1 | — | Tonic | — | Truce Canyon |
| Poly | 99(~) | 8 | 12 | 1 | — | — | — | Truce Canyon |
| Imp Ace | 54(~) | 5 | 10 | 1 | — | — | — | Truce Canyon |
| Diablos | 50(*) | 5 | 10 | 1 | — | — | — | Cathedral |
| Gnasher | 90(*) | 6 | 10 | 1 | — | — | — | Cathedral |
| Hench | 49(*) | 11 | 135 | 1 | — | — | — | Cathedral |
| Naga-ette | 60(*) | 6 | 10 | 1 | — | Tonic | — | Cathedral |
| Grimalkin | 120(~) | 10 | 15 | 1 | — | — | — | Cathedral |
| Viper | 100(~) | 8 | 10 | 1 | — | — | — | Denadoro Mts. |
| Bellbird | 97(~) | 8 | 10 | 1 | — | — | — | Denadoro Mts. |
| Ogan | 146(~) | 12 | 20 | 1 | Fire | — | — | Denadoro Mts. |
| Freelancer | 110(~) | 8 | 15 | 1 | — | — | — | Denadoro Mts. |
| Underling (Blue) | 110(~) | 10 | 12 | 1 | — | — | — | Zenan Bridge |
| Underling (Green) | 110(~) | 10 | 12 | 1 | — | — | — | Zenan Bridge |
| Outlaw | 182(*) | 12 | 20 | 1 | — | — | — | Magus's Castle |
| Juggler | 99(~) | 10 | 15 | 1 | all elements | — | — | Magus's Castle |
| Sorcerer | 220(~) | 14 | 20 | 1 | — | — | — | Magus's Castle |
| Groupie | 390(~) | 24 | 30 | 1 | — | — | — | Magus's Castle |
| Flunky | 195(~) | 14 | 20 | 1 | — | — | — | Magus's Castle |
| Deceased | 180(~) | 12 | 15 | 1 | Fire | — | — | Magus's Castle |

### 65,000,000 BC

Gold is 0 throughout Prehistory (no currency system).

| Name | HP | EXP | G | TP | Weakness | Drop | Charm | Location |
|---|---:|---:|---:|---:|---|---|---|---|
| Ion | 152(*) | 72(~) | 0 | 1 | — | — | Petal | Hunting Range |
| Anion | 152(~) | 72(~) | 0 | 1 | — | — | Feather | Hunting Range |
| Rain Frog | 100(~) | 60(~) | 0 | 1 | — | — | — | Hunting Range |
| Croaker | 100(~) | 60(~) | 0 | 1 | — | — | Fang ×2 | Hunting Range |
| Kilwala | 160(*) | 80(~) | 0 | 1 | — | — | Petal | Hunting Range |
| Amphibite | 100(*) | 50(~) | 0 | 1 | — | — | — | Mystic Mts. |
| Runner | 196(~) | 60(~) | 0 | 1 | — | — | — | Dactyl Nest |
| Shist | 250(~) | 70(~) | 0 | 1 | — | — | — | Forest Maze |
| Reptite (Green) | 92(*) | 72(~) | 0 | 1 | — | Petal | Magma Hand | Reptite Lair |
| Reptite (Purple) | 336(~) | 100(~) | 0 | 1 | — | — | — | Tyranno Lair |
| Evilweevil | 158(*) | 81(~) | 0 | 1 | — | — | Dreamstone Gun | Reptite Lair |
| Megasaur | 830(*) | 147(~) | 0 | 1 | — | Fang | Aeon Blade | Reptite Lair |
| Fly Trap | 316(*) | 86(~) | 0 | 1 | — | — | Dream Bow | Reptite Lair |
| Avian Rex | 1,300(~) | 150(~) | 0 | 2 | — | — | — | Tyranno Lair |
| Volcano | 436(~) | 100(~) | 0 | 1 | — | — | — | Tyranno Lair |
| Nu | 1,234(~) | 248(~) | 0 | 30 | — | Third Eye | Mop | Hunting Range (rare) |

### 12,000 BC

| Name | HP | EXP | G | TP | Weakness | Imm./Absorb | Drop | Charm | Location |
|---|---:|---:|---:|---:|---|---|---|---|---|
| Jinn Bottle | 97(~) | 50 | 50 | 1 | — | — | — | — | Enhasa / Kajar |
| Jinn | 450(~) | 100 | 100 | 2 | — | Absorb Fire | — | — | Ocean Palace |
| Barghest | 450(~) | 100 | 100 | 2 | — | Absorb Shadow | — | — | Ocean Palace |
| Scouter | 300(~) | 80 | 80 | 2 | Lightning | — | — | — | Ocean Palace |
| Red Scout | 300(~) | 80 | 80 | 2 | Fire | — | — | — | Ocean Palace |
| Blue Scout | 300(~) | 80 | 80 | 2 | Water | — | — | — | Ocean Palace |
| Thrasher | 666(~) | 120 | 100 | 2 | — | — | — | — | Ocean Palace |
| Lasher | 666(~) | 120 | 100 | 2 | — | — | — | — | Ocean Palace |
| Mage | 480(~) | 100 | 100 | 2 | — | — | — | — | Ocean Palace |
| Rubble | 515(*) | 1,000(*) | 0 | 100(*) | — | high evasion | — | — | Mt. Woe (flees) |
| Gargoyle | 260(*) | 80 | 50 | 2 | — | — | — | — | Mt. Woe |
| Stone Imp | 300(~) | 70 | 50 | 2 | — | — | — | — | Mt. Woe |
| Bantam Imp | 210(~) | 60 | 50 | 2 | — | — | — | — | Mt. Woe |
| Man Ape | 1,826(~) | 100 | 100 | 3 | — | — | — | — | Mt. Woe |
| Bomber Bird | 160(~) | 50 | 50 | 1 | — | — | — | — | Mt. Woe |

### 2300 AD

| Name | HP | EXP | G | TP | Weakness | Imm./Absorb | Drop | Charm | Location |
|---|---:|---:|---:|---:|---|---|---|---|---|
| Shadow | 1(*) | 10 | 0 | 1 | — | phys. immune | — | — | Site 16 |
| Crater | 80(*) | 8 | 10 | 1 | — | — | — | — | Site 16 |
| Meat Eater | 75(*) | 6 | 8 | 1 | — | — | — | — | Site 16 |
| Rat | 45(~) | 5 | 5 | 1 | — | — | — | — | Sewer Access |
| Nereid | 138(*) | 12 | 15 | 1 | — | — | — | — | Sewer Access |
| Egder | 160(*) | 15 | 20 | 1 | — | — | — | — | Sewer Access |
| Krawlie | 500(*) | 30 | 50 | 2 | — | — | — | — | Sewer Access |
| Octopod | 130(*) | 10 | 15 | 1 | — | — | — | — | Lab 32 |
| Mutant | 300(*) | 20 | 30 | 1 | — | — | — | — | Lab 32 |
| Bug | 89(*) | 8 | 10 | 1 | — | — | — | — | Factory |
| Acid | 10(*) | 33 | 20 | 1 | — | — | — | — | Factory |
| Alkaline | 9(*) | 33 | 20 | 1 | — | — | — | — | Factory |
| Proto 2 | 128(~) | 15 | 20 | 1 | — | — | — | — | Factory |
| Proto 3 | 256(~) | 25 | 30 | 1 | — | — | — | — | Factory |
| Proto 4 | 1,024(~) | 80 | 50 | 2 | — | — | — | — | Factory |
| Debuggest | 1,024(*) | 80 | 50 | 2 | — | — | — | — | Geno Dome |
| Dondrago | 800(~) | 40 | 50 | 2 | — | — | — | — | Sewer Access |
| Egg Ooze | 210(~) | 15 | 20 | 1 | — | — | — | — | Sewer Access |

---

## Boss Encounters (Story Order)

### Main story bosses

| # | Boss | HP | EXP | G | TP | Weakness | Imm./Absorb | Drop | Charm | Location | Special |
|---|---|---:|---:|---:|---:|---|---|---|---|---|---|
| 1 | **Yakra** | 920 | 50 | 600 | 5 | — | — | — | — | Cathedral 600 AD | Needle AoE |
| 2 | **Dragon Tank Head** | 600 | — | — | — | — | — | — | — | Prison 1000 AD | multi-part; kill Head first to stop healing |
| 2b | Dragon Tank Grinder | 208 | — | — | — | — | — | — | — | | physical AoE; invulnerable while Head lives |
| 2c | Dragon Tank Body | 266 | 40 | 500 | 5 | — | Absorb Lightning | — | — | | kill order: Head → Grinder → Body |
| 3 | **Guardian** | 1,200 | 300 | 1,000 | 5 | — | Imm Fire | — | — | Arris Dome 2300 AD | multi-part; 2 Bits (200 HP each) counter when Guardian hit — destroy Bits first |
| 4 | **R-Series** (×6) | 150 ea. | 80 | 100 | 3 | — | — | — | — | Proto Dome 2300 AD | 6 robots at once; Robo solo intro |
| 5 | **Heckran** | 2,100 | 250 | 1,500 | 10 | Water | Imm Physical | — | — | Heckran Cave 1000 AD | physical attacks do 1 damage; magic only; strong counter if you attack physically |
| 6 | **Zombor Upper** | 960 | — | — | — | Shadow, Water | Absorb Lightning, Fire | — | — | Zenan Bridge 600 AD | multi-part; opposite weaknesses top vs bottom |
| 6b | Zombor Lower | 800 | 350 | 1,500 | 10 | Lightning, Fire | Absorb Shadow, Water | — | — | | killing Lower ends fight; MP Buster |
| 7 | **Masa & Mune** (Phase 1) | 1,000 ea. | — | — | — | — | — | — | — | Denadoro Mts. 600 AD | two targets; fuse into Phase 2 |
| 7b | Masa & Mune (Fused) | 3,600 | 400 | 400 | 4 | — | — | — | — | | stores tornado → massive AoE |
| 8 | **Nizbel** | 4,200 | 500 | 0 | 10 | Lightning (lowers Def) | — | — | Third Eye | Reptite Lair 65M BC | Lightning drops defense; Def resets on discharge counter |
| 9 | **Slash** | 5,200 | 500 | 1,500 | 10 | — | — | — | — | Magus's Castle 600 AD | two-phase; Phase 2: draws Slasher sword, gains Speed |
| 10 | **Flea** | 4,120 | 500 | 1,000 | 10 | — | — | — | — | Magus's Castle 600 AD | opens with illusion; status ailments (Chaos, Poison) |
| 11 | **Ozzie** | N/A | 0 | 0 | 0 | — | — | — | — | Magus's Castle 600 AD | puzzle — hit mechanism behind ice wall; no real fight |
| 12 | **Magus** | 6,666 | 1,500 | 3,000 | 15 | cycles | Absorbs all except current weakness | — | MegaElixir | Magus's Castle 600 AD | **Barrier Change**: cycles Fire/Ice/Lightning/Shadow weakness (indicated by spell cast). Phase 2: charges Dark Matter AoE. Masamune bypasses barrier. |
| 13 | **Nizbel II** | 6,500 | 880 | 0 | 15 | Lightning (lowers Def) | — | — | Third Eye | Tyranno Lair 65M BC | like Nizbel but counters Lightning hit with Electric Discharge AoE |
| 14 | **Azala** | 2,700 | — | — | — | Lightning | — | — | — | Tyranno Lair 65M BC | multi-part with Black Tyranno |
| 14b | **Black Tyranno** | 10,500 | 1,800 | 0 | 25 | — | — | — | — | | charges fire breath over turns → massive Fire AoE |
| 15 | **Golem** | 7,000 | 1,000 | 1,000 | 35 | — | — | — | Magic Tab | Zeal Palace 12000 BC | **element copy** — mimics last element used against it; if given no element, runs away scared |
| 16 | **Mud Imp** | 1,200 | — | — | — | — | — | Elixir | — | Beast's Nest 12000 BC | multi-part with Blue Beast (5,000 HP; weak Fire; absorbs Water) and Red Beast (5,000 HP; weak Water; absorbs Fire). Kill Imp last or beasts revive. |
| 17 | **Giga Gaia Head** | 9,500 | 3,000 | 2,000 | 30 | — | — | — | Speed Tab | Mt. Woe 12000 BC | multi-part; 2 Arms (2,000 HP each) regenerate. Both arms up → Shadow+Fire AoE. |
| 18 | **Golem Twins** | 7,000 ea. | 2,000 | 2,000 | 40 | — | — | — | Magic Tab (each) | Ocean Palace 12000 BC | same element-copy as solo Golem |
| 19 | **Dalton** | 3,500 | 1,000 | 1,000 | 20 | — | — | — | Power Meal | Zeal Palace 12000 BC | Iron Orb counter on physical |
| 20 | **Dalton Plus** | 3,500 | 2,500 | 0 | 25 | — | — | — | Power Meal | Blackbird 12000 BC | summons Golem Boss (runs away); counter patterns |

### Sidequest bosses

| # | Boss | HP | EXP | G | TP | Weakness | Drop | Charm | Location | Special |
|---|---|---:|---:|---:|---:|---|---|---|---|---|
| 21 | **Rust Tyranno** | 25,000 | 3,800 | 2,000 | 40 | — | — | Red Mail | Giant's Claw 600 AD | fire-breath countdown → massive Fire AoE; high Def |
| 22 | **Retinite Upper** | 5,000 | — | — | — | Water (lowers Def) | — | — | Sunken Desert 600 AD | multi-part; hit with Water then physical |
| 22b | Retinite Lower | 4,800 | — | — | — | Water (lowers Def) | — | — | | same water mechanic |
| 22c | Retinite Core | 1,000 | 1,000 | 100 | 10 | — | Speed Tab | — | | kill Upper+Lower first; Core keeps boss alive |
| 23 | **Son of Sun** | 2,100 | 3,800 | 2,000 | 30 | — | — | Black Mail | Sun Temple 2300 AD | 5 Flames (1 HP each) orbit; only 1 correct Flame transfers damage; wrong = fire counter. Roulette Spin shuffles. Equip Red Vests/Mail. |
| 24 | **Atropos XR** | 6,000 | 0 | 0 | 0 | — | Ribbon (+3 Spd, +10 MDef to Robo) | — | Geno Dome 2300 AD | Robo solo fight |
| 25 | **Mother Brain** | 5,000 | 3,000 | 2,000 | 40 | — | — | — | Geno Dome 2300 AD | 3 Displays (1 HP each) heal her 1,000 HP/turn; kill Displays first (vulnerable to status) |
| 26 | **Yakra XIII** | 18,000 | 3,500 | 2,000 | 40 | — | — | White Mail | Guardia Castle 1000 AD | evolved Yakra descendant; Needle Spin |
| 27 | **Ozzie's Fort trio** | — | — | — | — | — | — | — | Ozzie's Fort 600 AD | Super Slash (4,000 HP; Charm: Slasher 2), Flea Plus (4,000 HP; Charm: Flea Vest), Ozzie (6,000 HP; Charm: Ozzie Pants joke) |

### Lavos Spawn encounters

| Boss | HP | Location | Special |
|---|---:|---|---|
| Lavos Spawn Head | 4,000 | Death Peak 2300 AD | attack Head only; Shell (10,000 HP) counters with Needle if hit |
| Elder Lavos Spawn Head | 10,000 | Black Omen | stronger; Shell (13,500 HP) same Needle counter |

### Black Omen bosses

| Boss | HP | Charm | Special |
|---|---:|---|---|
| Mega Mutant Top | 4,600 | — | multi-part; Bottom (3,850 HP) |
| Giga Mutant Top | 5,800 | — | multi-part; Bottom (4,950 HP). Top virtually immune to physical; use magic. MP drain counter. |
| Terra Mutant Top | 7,800 | — | multi-part; Bottom (20,000 HP). Top uses Life Shaver (HP → 1). Dark Matter heals Bottom but damages Top. |
| **Mammon Machine** | 18,000 | — | physical raises its Defense; magic raises its Attack. Periodically resets stored energy. Keep attacking through cycles. |
| **Queen Zeal (1st)** | 12,000 | MegaElixir | Hallation: all party HP → 1. Heal-heavy fight. |
| **Queen Zeal (2nd) — Face** | 28,000 | — | multi-part; Left Hand (20,000 HP; Charm: Prism Dress) counters with Life Shaver; Right Hand (20,000 HP; Charm: Prism Helm) counters with MP Buster. Target face. |

### Final Lavos fight (three phases)

**Phase 1 — Lavos Shell (1999 AD):** Before the true Shell fight, Lavos **mimics 9 previous bosses** in sequence (Dragon Tank, Guardian, Heckran, Zombor, Masa & Mune, Nizbel, Magus, Azala + Black Tyranno, Giga Gaia) — each with original stats and patterns. Then the real Shell fight begins.

| Part | HP | Notes |
|---|---:|---|
| Lavos Shell (real) | 10,000 | Head fires Rain of Destruction AoE; arms counterattack. Kill arms then head. |

**Phase 2 — Inner Lavos:**

| Part | HP | Notes |
|---|---:|---|
| Inner Lavos Body | 20,000 | destroy arms first |
| Left Arm | 12,000 | stronger arm |
| Right Arm | 8,000 | weaker arm |

**Phase 3 — Lavos Core:**

| Part | HP | Notes |
|---|---:|---|
| Center (Humanoid) | 10,000 | **DECOY** — not the real target. Gets revived by Right Bit. |
| Left Bit | 2,000 | heals Center 1,000 HP; absorbs all elements. Kill first. |
| **Right Bit** | **30,000** | **TRUE TARGET.** Can revive Center + Left Bit. Uses Grand Stone, Dreamless, Doors of Doom. Destroy this to win. |

---

## Implementation Notes

1. **Lavos Shell boss rush:** the 9-boss mimic sequence before the true Shell fight is essentially a gauntlet using existing boss AI.
2. **Barrier Change (Magus):** implement as a state machine cycling Fire → Water → Lightning → Shadow. His cast spell reveals the current weakness.
3. **Multi-part targeting:** Dragon Tank, Zombor, Giga Gaia, Retinite, Son of Sun, Lavos Core all require specific kill-order logic. Wrong target → counter or heal.
4. **Counter patterns to implement:** Heckran (counter physical), Lavos Spawn Shell (Needle counter), Queen Zeal Hands (Life Shaver / MP Buster), Dalton (Iron Orb on physical), Son of Sun (fire counter on wrong Flame).
5. **Charm vs Drop** are separate loot tables. Charm = Ayla's mid-battle steal. Drop = automatic post-battle reward.

---

## Regular Enemy Behavior

Most regular enemies are basic physical attackers. This section documents enemies with **interesting AI** — state changes, counter patterns, paired mechanics, or special attacks. Enemies not listed here use basic physical attacks only.

### Paired / Interactive Enemies

These enemies have behavior that changes based on whether a partner enemy is alive in the same fight.

| Enemy A | Enemy B | Interaction | Era |
|---|---|---|---|
| Juggler | Outlaw | Attacking Outlaw while Juggler alive triggers Fire Whirl Dual Tech counter (Fire AoE). Kill Juggler first. | 600 AD |
| Jinn | Ghul | Ghul shields Jinn from physical damage. Kill Ghul first. | 12,000 BC |
| Jinn | Barghest | If they get close to each other, they perform a combined ~120 damage AoE. | 12,000 BC |
| Cave Ape | Shist | Ape throws Shist at party as counter-attack when hit. Kill Shists first. | 65M BC |
| Reptite | Volcanite | Whoever hits Volcanite first determines target of ember shower — hit it before Reptite does to redirect damage at enemies. | 65M BC |
| Exterminator | Rat | Exterminator fires lasers at whatever moves — often kills its own Rats (friendly fire). | 2300 AD |
| Acid | Alkaline | Can fuse into an explosion. Attacking Alkaline while Acid alive may trigger counter. Kill Acids first. | 2300 AD |
| Narble | Ghaj | Narble counters magic with MP Buster (MP → 0). Ghaj counters physical with instant death. Use physical on Narble, magic on Ghaj. | Black Omen |
| Bellbird | Ogan | Bellbird wakes sleeping Ogans on the overworld. In battle, Bellbird may counter-ring to inflict Chaos. | 600 AD |

### State-Change / Transformation Enemies

| Enemy | Mechanic | Era |
|---|---|---|
| Ogan | Armed (high DEF) → hit with Fire → hammer destroyed → Disarmed (low DEF) | 600 AD |
| Shist | Hit once → transforms into Pahoehoe → hit again → erupts (Fire AoE) | 65M BC |
| Bomber Bird | On death → spawns Stone Imp at full HP | 12,000 BC |
| Gold Eaglet | After 2 hits → transforms into Red Eaglet (weaker) | 65M BC |
| Juggler | Swaps physical/magical immunity with each hit type | 600 AD |

### Counter / Self-Destruct Enemies

| Enemy | Trigger | Counter | Era |
|---|---|---|---|
| Tubster | any attack | hard physical hit back (every time) | Black Omen |
| Narble | magic attack | MP Buster (caster's MP → 0) | Black Omen |
| Ghaj | physical attack | instant death on attacker | Black Omen |
| Roly Bomber | death or timer | self-destruct AoE | 600 AD |
| Laser Guard | non-fatal damage | self-destruct AoE; can chain to other Laser Guards | 2300 AD |
| Green Imp | being hit | Jump Kick counter | 600 AD |

### Status-Inflicting Enemies

| Enemy | Attack | Status | Era |
|---|---|---|---|
| Naga-ette | Nagamour (Slow Kiss) | Slow | 600 AD |
| Cybot | La La La | Chaos (all party) | Black Omen |
| Cybot | Iron Sphere | halves target's current HP | Black Omen |
| Cave Bat | Sonic Wave | Sleep | 1000 AD |
| Fly Trap | Pollen | Poison | 65M BC |
| Bellbird | Ring Bell (counter) | Chaos | 600 AD |
| Rubble | Lock (battle start) | Lock (disables Techs + Items); then flees after ~3 turns | 12,000 BC |
| Gargoyle | HP-to-1 attack | reduces target HP to 1 | 12,000 BC |
| Nu | Head-Butt | reduces target HP to 1 | various |

### Physical-Immune Enemies (magic only)

| Enemy | Notes | Era |
|---|---|---|
| Shadow | immune to all physical; must use magic/Techs | 2300 AD |
| Acid | DEF 255; physical immune; use magic | 2300 AD |

### MP/HP Drain Enemies

| Enemy | Attack | Effect | Era |
|---|---|---|---|
| Jinn Bottle | Absorb / Drain | drains MP and HP from target | 1000 AD |
| Cave Bat | Blood Suck | drains HP | 1000 AD |

### Enemies with Notable Elemental Mechanics

| Enemy | Mechanic | Era |
|---|---|---|
| Megasaur | Lightning lowers defense (mini-Nizbel mechanic) | 65M BC |
| Scouter / Red Scout / Blue Scout | counter with elemental AoE if hit with wrong element; use matching weakness | 12,000 BC |
| Tubster | weak to Fire; use Fire to kill efficiently despite counter | Black Omen |

### Charm-Farming Targets

| Enemy | Charm Item | Location | Notes |
|---|---|---|---|
| Tubster | Power Tab | Black Omen | respawns if you leave and re-enter room |
| Flyclops | Gold Stud | Black Omen | 75% MP cost reduction |
| Nu | Mop (joke) / Third Eye | Hunting Range / various | appears during rain |
| Rubble | — (high EXP/TP only) | Mt. Woe | 1,000 EXP + 100 TP on kill; flees fast |

## Sources

- [StrategyWiki — Enemies](https://strategywiki.org/wiki/Chrono_Trigger/Enemies) / [Bosses](https://strategywiki.org/wiki/Chrono_Trigger/Bosses)
- [GameFAQs — Bestiary by DC](https://gamefaqs.gamespot.com/snes/563538-chrono-trigger/faqs/10202)
- [GameFAQs — Enemy List by Dangerous_K](https://gamefaqs.gamespot.com/snes/563538-chrono-trigger/faqs/8110)
- [GameFAQs — Boss FAQ by Ranma](https://gamefaqs.gamespot.com/ps/562913-chrono-trigger/faqs/13464)
- [Data Crystal — ROM-extracted enemy list](https://datacrystal.tcrf.net/wiki/Chrono_Trigger_(SNES)/List_of_Enemies)
- [Chrono Wiki — List of Enemies](https://chrono.fandom.com/wiki/List_of_Chrono_Trigger_enemies)
- [Caves of Narshe — Enemies](https://www.cavesofnarshe.com/ct/enemies.php)
- [Chrono Compendium — Monsters](https://www.chronocompendium.com/Term/Monsters_(Chrono_Trigger).html)
- [chronotrigger.wiki.gg — Enemies](https://chronotrigger.wiki.gg/wiki/Enemies)
- [GirkDently's Enemy AI Script Guide (GameFAQs)](https://gamefaqs.gamespot.com/snes/563538-chrono-trigger/faqs/78740)
- [Shinrin's Bestiary (GameFAQs)](https://gamefaqs.gamespot.com/ds/950181-chrono-trigger/faqs/55029)
- [Chrono Compendium — Monster Techs](https://www.chronocompendium.com/Term/Monster_Techs.html)
- [Data Crystal — Enemy AI Documentation](https://datacrystal.tcrf.net/wiki/Chrono_Trigger_(SNES)/Enemy_AI_Documentation)
- [RPG Shrines — Enemy Attacks](http://shrines.rpgclassics.com/snes/ct/eattacks.shtml)
