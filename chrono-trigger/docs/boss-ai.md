# Chrono Trigger — Boss AI & Behavior

Referenced from [SPEC.md §9](../SPEC.md) and [docs/bestiary.md](bestiary.md). SNES original names used.

For each boss: attack list, AI logic, counter patterns, phase transitions, and special mechanics.

---

## ATB Speed Reference

| Boss | Speed |
|---|---:|
| Yakra | 9 |
| Dragon Tank Body | 8 |
| Guardian | 14 |
| Guardian Bits | 10 |
| Heckran | 10 |
| Zombor (both) | 8 |
| Masa & Mune (fused) | 10 |
| Nizbel / Nizbel II | 8–9 |
| Slash (sword phase) | 12 |
| Flea | 10 |
| Magus | 12 |
| Golem / Golem Twins | 16 |
| Giga Gaia Head | 10 |
| Giga Gaia Arms | 13–14 |
| Dalton / Dalton Plus | 10 |
| Queen Zeal (1st) | 12 |
| Queen Zeal (2nd face) | 12 |
| Lavos Core Center | 12 |
| Lavos Core Bits | 10 |

---

## 1. Yakra

**Cathedral, 600 AD** | HP 920

| Attack | Type | Element | Target | Power | Status |
|---|---|---|---|---|---|
| Scratch | Physical | None | single | low | — |
| Iron Orb | Physical | None | single | medium | — |
| Needle Spin | Physical | None | all | medium-high | — |

**AI:** Random selection from attacks. At low HP, favors Needle Spin. No phases.

**Counter:** If attacked from range, Yakra charges the whole party. Close-range attacks avoid this.

---

## 2. Dragon Tank (Head / Grinder / Body)

**Prison Tower, 1000 AD** | Head 600 HP, Grinder 208 HP, Body 266 HP

| Part | Attack | Type | Element | Target | Status |
|---|---|---|---|---|---|
| Head | Flame Thrower | Magical | Fire | single | — |
| Head | Heal | Support | — | all parts | repairs damage |
| Body | Missile | Physical | None | single | — |
| Body | Laser (counter) | Magical | None | attacker | — |
| Grinder | Grinder Attack | Physical | None | all | — |

**AI:** Head checks each turn if Body/Grinder took damage → heals them. Otherwise uses Flame Thrower. Body alternates Missile/Laser. Grinder charges then fires AoE.

**Counter:** Body counters physical hits with Laser.

**Kill order:** Head → Grinder → Body. Head immune to Lightning and Fire. Body has 160 Def (use magic).

---

## 3. Guardian + Bits

**Arris Dome, 2300 AD** | Guardian 1,200 HP, Bits 200 HP each

| Part | Attack | Type | Element | Target | Status |
|---|---|---|---|---|---|
| Guardian | Laser / Amplified Laser | Magical | None | single | — |
| Bits (×2) | Delta Force | Magical | Shadow | all | — |

**AI:** Guardian attacks with Laser on its turn. Counter logic is Bit-dependent.

**Counter:** Attacking Guardian while **both** Bits alive → Delta Force (all-party Shadow, ~70+ damage). One Bit alive → single-target Shadow. Attacking Bits does NOT trigger counter.

**Kill order:** Both Bits first, then Guardian.

---

## 4. R-Series (×6)

**Proto Dome, 2300 AD** | 150 HP each

| Attack | Type | Target | Status |
|---|---|---|---|
| Punch | Physical | single | — |
| Robot Toss | Physical | all (nearby) | — |
| Self-Destruct (last unit) | Magical | all | — |

**AI:** Random attacks. Last robot standing self-destructs for high AoE. Party of two only (no Robo). Use Cyclone on rows of three.

---

## 5. Heckran

**Heckran Cave, 1000 AD** | HP 2,100

| Attack | Type | Element | Target | Status |
|---|---|---|---|---|
| Claw Swipe | Physical | None | single | — |
| Water | Magical | Water | single | — |
| Water II | Magical | Water | all | — |

**AI:** Alternates between two modes on a timer (not HP-based):
- **Counter mode** ("Go ahead, try and attack me!") — physical/tech attacks trigger Water II counter (all-party ~80+). Only magic spells deal damage safely.
- **Vulnerable mode** — all attacks work, no counter.

**Counter:** Water II on any physical/tech during counter mode. Magic does NOT trigger counter.

---

## 6. Zombor (Upper / Lower)

**Zenan Bridge, 600 AD** | Upper 960 HP, Lower 800 HP

| Part | Attack | Type | Element | Target | Status |
|---|---|---|---|---|---|
| Upper | Claw Swipe | Physical | None | single | — |
| Upper | "Doom Doom Doom" Laser | Magical | Shadow | all | — |
| Upper | MP Buster (death trigger) | Magical | None | killer | drains all MP |
| Lower | Kick | Physical | None | single | — |
| Lower | Death Attack | Magical | Shadow | single | instant KO |

**Weaknesses:** Upper: Water, Shadow. Absorbs Fire, Lightning. Lower: Fire, Lightning. Absorbs Water, Shadow.

**AI:** Both halves act independently on separate ATB timers.

**Phase transitions:**
- **Upper dies** → fires MP Buster on the killing character (all MP → 0). Lower then starts using instant-death attacks.
- **Kill order:** Lower first to avoid both MP Buster and instant-death escalation.

---

## 7. Masa & Mune

### Phase 1 (Separated) — 1,000 HP each

| Attack | Type | Target | Status |
|---|---|---|---|
| Punch/Kick | Physical | single | — |
| Wind Slash | Magical | single | — |
| X-Strike (counter) | Physical | single | — |

**AI:** Attack independently. Defeating either ends Phase 1.

**Counter:** Attacking either twin → both coordinate X-Strike counter. Incapacitating one twin with status (Sleep, Chaos, Stop) prevents the counter.

### Phase 2 (Fused) — 3,600 HP

| Attack | Type | Target | Status |
|---|---|---|---|
| Double Hand Chop | Physical | single (nearest or lowest HP) | — |
| Hurricane | Magical | all | — |
| Vacuum Wave | Magical | all | high damage |

**AI:** Uses Double Hand Chop normally. Periodically starts **"Storing Tornado Energy"** charge sequence. If completed → Vacuum Wave (heavy AoE).

**Key mechanic:** Crono's **Slash** tech neutralizes the tornado energy ("Tornado Energy has been neutralized"). Any other attack during charge triggers a Lightning counter.

**Phase transition:** Below 50% HP → more aggressive, more frequent tornado charges, targets lowest-HP character.

---

## 8. Nizbel

**Reptite Lair, 65M BC** | HP 4,200 | Def 253 (base)

| Attack | Type | Element | Target | Status |
|---|---|---|---|---|
| Charge | Physical | None | single | — |
| Stomp | Physical | None | all | — |
| Electric Discharge | Magical | Lightning | all | restores Def to 253 |

**AI — defense cycle:**
1. Base state: Def 253 (physical attacks deal negligible damage).
2. Hit with Lightning → Def drops to ~0, Nizbel stunned for a few turns.
3. Party deals heavy physical damage during low-Def window.
4. After several turns, Nizbel uses Electric Discharge (Lightning AoE to party, Def resets to 253).
5. Repeat cycle.

---

## 9. Slash

### Phase 1 (Unarmed) — 3,300 HP

Basic jabs and combos + occasional Fire Strike (all). Immune to Water. No counters.

### Phase 2 (Slasher equipped) — 5,200 HP

| Attack | Type | Target | Status |
|---|---|---|---|
| Sword Strike | Physical | single | — |
| Aerial Slash ("Yes, Indeed!") | Physical | all | — |

**AI:** Scripted transition mid-fight (draws Slasher sword). Stats jump significantly. Below ~50% HP → counters attacks with powerful sword slash.

Drops the **Slasher** weapon for Crono.

---

## 10. Flea

**Magus's Castle, 600 AD** | HP 4,120

| Attack | Type | Target | Status |
|---|---|---|---|
| Blow Kiss | Magical | single | Sleep |
| Rainbow Storm | Magical | all | Poison |
| Waltz of the Wind | Magical | all | Chaos |
| Prism Beam | Magical | all | Blind |
| The Stare (counter) | Magical | all | — |
| Charm | Magical | Crono | forces Crono to attack allies |

**AI:** Opens with illusion (fake Flea). Real fight is status-heavy: Sleep, Poison, Chaos, Blind. Charm targets Crono specifically.

**Counter:** Below 50% HP → physical attacks trigger The Stare (heavy all-party damage).

---

## 11. Ozzie (Magus's Castle)

**Puzzle boss.** Ozzie is behind an ice barrier — direct attacks have no effect. Attack the **switches/levers** in the room to open a trap door. Ozzie casts Ice II while the player works the puzzle.

---

## 12. Magus

**Magus's Castle, 600 AD** | HP 6,666 | Def 178

| Attack | Type | Element | Target | Status |
|---|---|---|---|---|
| Lightning II | Magical | Lightning | all | — |
| Ice II | Magical | Water | all | — |
| Fire II | Magical | Fire | all | — |
| Dark Bomb | Magical | Shadow | single | — |
| Dark Matter | Magical | Shadow | all | ~200–230 damage |

**AI — Phase 1 (Barrier):**
- Active barrier absorbs ALL elements except his current weakness.
- Every hit (except Masamune) triggers **Barrier Change** → random new weakness.
- Magus casts a spell matching his current weakness to signal it: Lightning II = weak to Lightning, Fire II = weak to Fire, Ice II = weak to Water, Dark Bomb = weak to Shadow.
- Def 178 makes physical attacks weak.

**AI — Phase 2 (Dark Matter):**
- At a damage threshold, Magus drops the barrier. "Magus risks casting a spell…"
- Charges Dark Matter (~200–230 all-party). Barrier does not return after.
- Physical Def drops significantly.

**Key mechanic:** Frog's **Masamune** does NOT trigger Barrier Change and lowers Magus's Magic Defense. Frog is the ideal Phase 1 attacker.

---

## 13. Nizbel II

**Tyranno Lair, 65M BC** | HP 6,500 | Def 253

Same defense cycle as Nizbel, but Nizbel II does **NOT become stunned** after Lightning. Continues attacking even while defense is lowered. Higher damage output.

---

## 14. Azala + Black Tyranno

**Tyranno Lair, 65M BC** | Azala 2,700 HP, Tyranno 10,500 HP

| Part | Attack | Type | Element | Target | Status |
|---|---|---|---|---|---|
| Azala | Psychokinesis | Magical | None | single | — |
| Azala | Telepathy | Magical | None | single | Sleep |
| Tyranno | Tyranno Flame | Magical | Fire | all | ~300+ damage |
| Tyranno | Chomp | Physical | None | single | HP drain |
| Tyranno | Roar | Physical | None | all | Sap |

**AI — Phase 1 (Azala alive):** Tyranno has near-invulnerable defense. Azala casts Psychokinesis and Sleep.

**AI — Phase 2 (Azala dead):** Tyranno defense drops. Begins **5-turn countdown** with Roar each turn. At 0 → Tyranno Flame (Fire, all, 300+). Then Chomp cycle. Repeats.

**Kill Azala first.** Fire-absorbing equipment (Red Mail) trivializes Tyranno Flame.

---

## 15. Golem

**Zeal Palace, 12,000 BC** | HP 7,000 | Speed 16

| Attack | Type | Target | Status |
|---|---|---|---|
| Copied spell | Magical (matches last element used) | all | — |
| Iron Orb | Physical | single | halves HP |

**AI — element copy:** Copies the element of the last attack used. On its next turn, casts that element back. If hit with physical (non-elemental), uses Iron Orb (halves HP). Rapidly alternating different elements resets its copied element each time, preventing it from ever acting.

Optional fight. Hypnowave can put it to Sleep.

---

## 16. Mud Imp + Blue Beast + Red Beast

**Beast's Nest, 12,000 BC** | Imp 1,200 HP, Beasts ~5,000 HP each

**AI:** Imp heals beasts and debuffs party. Blue Beast weak to Fire (absorbs Water). Red Beast weak to Water (absorbs Fire). All three alive → coordinate Earthquake or Cross Charge combos.

**Kill Imp first** to stop healing (use magic — 150 Def vs physical). Hypnowave trivializes the beasts.

---

## 17. Giga Gaia (Head + Arms)

**Mt. Woe, 12,000 BC** | Head 9,500 HP, Arms 2,000 HP each (1,000 on revive)

**AI:**
- **Both arms alive** → devastating triple tech AoE (Fire or Shadow).
- **One arm alive** → double tech that halves a character's HP.
- **No arms** → Head does nothing but countdown to revive both arms at 1,000 HP each.
- Right Arm heals the Head. Left Arm is the physical attacker.

**Kill order:** Right Arm (stops healing) → Left Arm (stops combos) → Head during countdown window.

---

## 18. Golem Twins

**Ocean Palace, 12,000 BC** | 7,000 HP each | Speed 16

Same element-copy mechanic as single Golem, independently per twin. Alternating elements disrupts both. AoE spells hit both simultaneously.

---

## 19. Dalton / Dalton Plus

**Dalton (Zeal Palace):** HP 3,500. Counters every attack with Iron Orb (halves attacker's HP). Death trigger: Burrrp (~150 all-party).

**Dalton Plus (Blackbird):** HP 3,500. Fixed 5-round pattern (Fireball ×2 → Slash → repeat). Counters physical with Iron Orb. Counters elemental magic with opposite element. Lightning → Iron Orb only.

---

## 20. Lavos Spawn

**Death Peak, 2300 AD** | Head 4,000 HP, Shell 10,000 HP (Def 253)

**AI:** Head uses Needle Attack (all), Blanket Bomb (Fire, all), Blizzard (Water, all + Chaos), Lavos's Sigh (all + Sleep). Shell is passive.

**Counter:** Any attack on the Shell → Needle counter (very high damage + Sleep). **Never attack the Shell.**

---

## 21. Rust Tyranno

**Giant's Claw, 600 AD** | HP 25,000

Same countdown mechanic as Black Tyranno without Azala. 5-turn countdown with Roar (Sap) → Tyranno Flame (Fire, all, 300+) → Chomp cycle → repeat. Fire-absorbing equipment trivializes it.

---

## 22. Retinite (Upper / Lower / Core)

**Sunken Desert, 600 AD** | Upper 5,000 HP, Lower 4,800 HP, Core 1,000 HP

**AI:** All parts start with high evasion + element immunity. Hitting each part with **Water** removes immunity (must apply per-part). Upper/Lower drain HP from Core to self-heal.

**Key mechanic:** If Core dies, Upper/Lower defense increases with each hit. Keep Core alive (heal it with non-Water magic if needed). Kill Upper first (drains Core more), then Lower.

---

## 23. Son of Sun + Flames

**Sun Temple, 2300 AD** | Son of Sun ~2,400 HP (indirect), Flames 1 HP each (×5)

**Puzzle boss.** 5 Flames orbit. Only 1 is "correct" — attacking it deals ~200 damage to the Son of Sun (ding sound). Wrong Flame → Fire counter on attacker. Direct attack on Son of Sun → Flare (devastating Fire AoE). Roulette Shuffle periodically reassigns the correct Flame.

Fire-absorbing equipment (Red Mail) negates all damage, trivializing the fight. ~10–12 correct hits to win.

---

## 24. Atropos XR

**Geno Dome, 2300 AD** | HP 6,000 | Robo solo fight

Semi-fixed rotation: Rocket Punch → Cure Beam (self-heal) → Laser Spin → Robo Tackle (halves HP) → Cure Beam → Uzzi Punch → Area Bomb spam. Near death → Self-Destruct.

Keep Robo HP high for the Self-Destruct on death. Reward: permanent +3 Speed / +10 M.Def to Robo.

---

## 25. Mother Brain + Displays

**Geno Dome, 2300 AD** | Mother Brain 5,000 HP, Displays 1 HP each (×3)

**AI — Displays alive:** Each Display heals Mother Brain ~1,000 HP/turn. Mother Brain uses weak Shadow Laser.

**AI — Displays dead (berserk):** Mother Brain unleashes heavy all-party attacks. DPS race.

**Key mechanic:** Hypnowave can put Displays to Sleep, stopping healing without triggering berserk. Then safely damage Mother Brain.

---

## 26. Yakra XIII

**Guardia Castle, 1000 AD** | HP 18,000

Stronger Yakra. Claw Swipe, Needle Spin, Needle Spray (150+), Chaos Attack (all, Chaos). Below 50% HP → adds Needle Spray. **Death trigger:** mandatory ~200+ all-party attack. Keep party HP high.

---

## 27. Ozzie's Fort Trio

**Ozzie's Fort, 600 AD** | Super Slash 4,000 HP, Flea Plus 4,000 HP, Great Ozzie 6,000 HP

**Counter:** Attacking Ozzie while Slash + Flea alive → Shadow Triple Tech (devastating all-party).

**Kill order:** Slash first (disables Triple Tech, Charm: Slasher 2) → Flea may flee (Charm: Flea Vest) → Ozzie alone is defenseless (Charm: Ozzie Pants).

---

## 28. Black Omen Bosses

### Mega Mutant (Upper 4,600 + Lower 3,850 HP)
Upper: Tentacle (HP drain), Mutant Gas (Poison/Sleep). Lower: Chaotic Zone (Chaos). No counters, random selection.

### Giga Mutant (Upper 5,800 + Lower 4,950 HP)
Upper: Blanket Bomb, Shining Bit (AoE). **Counter: Upper absorbs MP from attacker.** Lower: Life Shaver (HP → 1).

### Terra Mutant (Upper 7,800 + Lower 20,000 HP)
Upper drains ~1,000 HP from Lower each turn to fuel attacks (Energy Spheres, Halation). Lower absorbs all magic + extreme physical Def. **Ignore Lower — kill Upper only.**

### Mammon Machine (18,000 HP)
**Adaptive defense:** physical hits raise its Def; magic hits raise its Attack. Uses Life Shaver, Energy Drain (MP), Point Flare. Counter-attack accessories bypass the stat-increase mechanic. DPS check — kill before it scales out of control.

### Queen Zeal — 1st Form (12,000 HP)
Spams **Hallation** (all party HP → 1) repeatedly. Energy Ball for direct damage. Cannot actually KO anyone in this form (HP to 1 but not 0). Transitions directly to 2nd form with no heal opportunity.

### Queen Zeal — 2nd Form (Face 20,000 + Hands 28,000 HP each)
Face: Hallation, Hexagon Mist (Water AoE), Dark Gear, Skygate. **Left Hand counter:** Life Shaver (HP → 1). **Right Hand counter:** MP Buster (MP → 0). **Never attack the hands** — kill the Face only. Charm: Left Hand = Prism Dress, Right Hand = Prism Helm.

---

## 29. Lavos Shell

### Mimic Gauntlet (9 bosses in order)
Lavos morphs to replicate each boss with original stats and AI:
1. Dragon Tank → 2. Guardian + Bits → 3. Heckran → 4. Zombor → 5. Masa & Mune (Fused) → 6. Nizbel → 7. Magus → 8. Azala + Black Tyranno → 9. Giga Gaia

Significantly easier than originals due to higher party levels. Use same strategies.

### True Shell (10,000 HP)
Destruction Rain (~200+ all), Needle Spin (all), Earthquake (all), Chaos Zone (Chaos all), Lavos Needle (extreme). Continuous assault, no counters, no phases.

---

## 30. Inner Lavos (Body + Arms)

**Body 20,000 HP, Left Arm 12,000 HP, Right Arm 8,000 HP**

| Phase | Condition | Behavior |
|---|---|---|
| 1 | both arms alive | Body: Doors of Doom (all). Arms: physical + Stop status |
| 2 | one arm dead | surviving arm casts Protective Seal (strips party buffs + status immunity) |
| 3 | both arms dead | Body casts Obstacle (drops own Def). Then: Shadow Slay (Poison all) → Flame Battle (Fire single) → **Shadow Doom Blaze** (extreme Shadow all) |

**Kill both arms as close together as possible** to minimize Protective Seal exposure. Phase 3 is the DPS window (lowered Def) but also the most dangerous (Shadow Doom Blaze).

---

## 31. Lavos Core (Center / Left Bit / Right Bit)

**Center 10,000 HP | Left Bit 2,000 HP | Right Bit 30,000 HP (TRUE TARGET)**

| Part | Role | Key attacks |
|---|---|---|
| Center (Humanoid) | **Decoy.** Heavy attacks but not the real target. | Dreamless (~600 Shadow all), Grand Stone (~500 physical all), Evil Star (halves HP), Time Warp (resets HP/MP to start-of-battle values) |
| Left Bit | Strips status protections. Heals Center 1,000 HP. Absorbs all elements. | Status Strip |
| Right Bit | **True Lavos.** Revives Center + Left Bit via Active Life. | Active Life (full revive of Center + Left) |

**AI cycle:**
1. Center attacks with devastating spells. Left Bit strips protections.
2. Kill Center → Right Bit's defense drops (DPS window).
3. Attack Right Bit heavily during window.
4. Right Bit uses Active Life → revives Center + Left at full HP.
5. Repeat until Right Bit's 30,000 HP is depleted.

**Destroying Right Bit wins the game.** Dreamless and Grand Stone are the most dangerous attacks in the game — keep HP above 600 at all times.

---

## Sources

- [GirkDently Enemy AI Script Guide (GameFAQs)](https://gamefaqs.gamespot.com/snes/563538-chrono-trigger/faqs/78740)
- [Data Crystal — Enemy AI Documentation](https://datacrystal.tcrf.net/wiki/Chrono_Trigger_(SNES)/Enemy_AI_Documentation)
- [StrategyWiki — Bosses](https://strategywiki.org/wiki/Chrono_Trigger/Bosses)
- [Chrono Wiki — List of Bosses](https://chrono.fandom.com/wiki/List_of_Chrono_Trigger's_bosses)
- [Chrono Compendium — Monsters](https://www.chronocompendium.com/Term/Monsters_(Chrono_Trigger).html)
- [Caves of Narshe — Walkthrough](https://www.cavesofnarshe.com/ct/walkthrough.php)
- [Chrono Trigger Jets of Time Wiki — Boss Data](https://wiki.ctjot.com/doku.php?id=bosses)
