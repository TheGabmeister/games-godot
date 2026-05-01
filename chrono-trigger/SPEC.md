# Chrono Trigger — Godot Recreation Spec

A systems-focused Godot implementation inspired by Square's 1995 SNES JRPG *Chrono Trigger*. The goal is to build **scalable game architecture** — not to recreate the full game. We implement enough of the original's content (a representative slice of characters, techs, enemies, areas, and story) to validate that our systems and architecture can scale to the scope of the complete game.

This document stays at the spec level: features, systems, characters, items, enemies, story structure. It describes the *full* original design surface as a reference; actual implementation will be selective. No code, no Godot node trees, no implementation choices. Those come later.

---

## 1. Design Goals & Non-Goals

### Goals
- Build a **scalable architecture** for a Chrono Trigger–style JRPG in Godot, proving the systems work at representative scale.
- Faithful reproduction of the **Active Time Battle (ATB)** system, including field-to-battle continuity (no separate battle screen).
- A **representative subset** of playable characters, Single / Dual / Triple Techs, enemies, and areas — enough to stress-test every major system.
- Core progression systems: time-era travel, storyline gating, New Game+, and branching endings — implemented end-to-end even if content is partial.
- An economy and item system rich enough to support meaningful build choices (accessories, charm-only gear, elemental armor).
- Data-driven design so that scaling from the subset to full content is an authoring task, not an engineering one.

### Non-Goals
- Recreating all of the original game's content (full map set, full bestiary, full quest line). We implement only enough to validate architecture.
- 1:1 pixel-art reproduction of SNES sprites, tilesets, or animations.
- Reproduction of the original soundtrack (Yasunori Mitsuda's score is not redistributable).
- DS-port-only content (Lost Sanctum, Dimensional Vortex, Magus dual/triple techs). Treat as stretch goals.
- Online multiplayer.

---

## 2. Core Gameplay Systems

### 2.1 Battle System (Active Time Battle)

- **No separate battle screen.** Encounters trigger on the field; characters and enemies keep their world positions when combat starts. Most enemies are visible (no hidden random encounters).
- **ATB gauges.** Every combatant has a hidden gauge that fills in real time. When full, that combatant may act.
- **Speed stat** scales individual gauge fill rate. **Haste** roughly doubles it; **Slow** roughly halves it.
- **Battle Speed** is a global option (1–8 in the SNES original) that scales the wall-clock tick rate without changing relative order.
- **Wait vs. Active mode.** A user-selectable preference:
  - **Active**: enemy gauges keep filling while you navigate any menu.
  - **Wait**: enemy/ally gauges pause while you are inside a Tech, Item, or target-selection submenu (top-level menu does not pause).
- **Turn order is emergent**, not scripted. Whoever fills first acts first. Multiple ready actors queue in fill order.
- **Party of three** active members in any battle. Roster of seven recruitable characters; swapping happens at the End of Time.
- **Targeting and shapes.** Techs have geometric AoE shapes that interact with on-field positions: single-target, line, cone, circle-around-self, circle-around-target. Pre-positioning the party before triggering a fight, and waiting for enemies to cluster, are core tactical levers.
- **Escape.** Not a menu command — player holds **L+R** simultaneously. An escape value accumulates over time; bosses and story fights are flagged un-runnable. Enemies can still hit the party while it flees.
- **Counter.** Some enemies counter every attack; some counter only on specific damage types (e.g., Magus's elemental barriers counter mismatched elements). Certain accessories grant player characters a counter-attack chance (see §6.3).
- **Game over** triggers when all three active party members are KO'd, except in the scripted Crono death scene at the Ocean Palace where the loss is canonical and unavoidable.
- **Battle rewards.** Each victory awards EXP, G (gold), and Tech Points (TP). EXP and TP go only to surviving members of the active party of three — benched characters earn nothing, which is the central reason era-swap rotation matters.

### 2.2 Tech System

Techs are character abilities that cost MP. They are organized in three tiers.

**Single Techs** — 8 per character, learned in fixed order by accumulating Tech Points (TP) past per-tech thresholds.

- The **first elemental Single Tech** for Crono (Lightning), Marle (Ice), Lucca (Fire), and Frog (Water) is **not** earned via TP. Instead, the first time the party visits the End of Time, **Spekkio "awakens"** their magic and grants the tech for free. After that, subsequent magical techs proceed via the normal TP track.
- **Robo and Ayla** do not receive Spekkio's awakening — Robo's magic-flavored techs are mechanical (lasers, bombs); Ayla has no magic.
- **Magus** joins with all eight of his Single Techs already learned.

**Dual Techs** — Combo abilities between two characters. Requirements:
- Both participants know the prerequisite Single Techs.
- Both have full ATB gauges at the moment of casting.
- The combined MP cost (sum of components, sometimes with a small surcharge) is paid.
- No separate "learning" event — once both prereqs are met, the combo appears in the menu.

**Triple Techs** — Combo abilities between all three active members. Same gauge/MP rules. Some Triples require a unique key item (a "Rock") to be held by one of the participants, and only one Rock is in the inventory at a time, so swapping Rocks gates which Triple is currently selectable. Rocks: Black, Blue, Silver, Gold, White.

The full canonical tech roster (Singles, Duals, Triples) is enumerated in [docs/techs.md](docs/techs.md). Magus's Dual/Triple restrictions are noted in his §4 character entry.

### 2.3 Stats & Progression

Per-character stats:
- **HP** — KO at 0.
- **MP** — Tech cost.
- **Power** — physical damage.
- **Stamina** — physical defense.
- **Speed** — ATB fill rate (small differences matter a lot; capped per character).
- **Magic** — magic damage.
- **Magic Defense** — magic damage absorbed.
- **Hit %**, **Evade %**, **Strike %** (critical hit chance) — combat rolls.

**Level cap: 99.** Per-character growth tables determine stat gains per level. Growth attenuates after L60.

**Stat-boost capsules / "Tabs"** — consumable items that permanently raise one stat by 1: Power Tab, Magic Tab, Speed Tab. (Speed Tab is the rarest and most valuable.) Scattered in chests, given by NPCs, and obtainable via Charm.

**Equipment slots — four per character:**
1. **Weapon** — character-specific class (see §6.1).
2. **Helm** — universal.
3. **Armor** — universal.
4. **Accessory** — universal, one slot.

No shield slot.

### 2.4 Magic & Elements

Four elements — there is no separate Holy/Light element:
- **Lightning** (also called Heaven/Sky in JP) — Crono, Magus.
- **Fire** — Lucca, Magus.
- **Water/Ice** — Marle, Frog, Magus. (Water and Ice are the same element internally; both characters' "Water" and "Ice" tech names alias to it.)
- **Shadow** — Robo, Magus. Robo is the only basic party member with Shadow-element offensive techs (Laser Spin, Shock). His healing techs (Cure Beam, Heal Beam) are non-elemental, and Area Bomb is Fire-typed.

**Ayla has no element**; all her techs are physical. Regular weapon attacks in the SNES game are **non-elemental physical** — even weapons whose names suggest an element (Bolt Sword, Flash Blade) do not actually carry that element on swings. Elemental damage comes from techs, not from the basic attack command.

Resistance multipliers run 0% / 50% / 100% / 200%, plus an "absorb" state where a hit heals the target. Some bosses cycle their own elemental absorption mid-fight — most notably **Magus**, whose **Magic Wall** continuously rotates which element he absorbs, forcing the party to read the cue and switch damage types each round.

#### Spekkio, the Master of War

Spekkio resides at the End of Time and grants the four magic-using characters their first elemental Single Tech via an "awakening." His own visible form scales to the **lead character's level** at the moment of encounter — encountering him at higher level yields a harder (optional) battle:

| Lead-character level | Spekkio's form |
|---|---|
| 1–9 | Prehistoric Frog |
| 10–19 | Kilwala |
| 20–29 | Ogan |
| 30–39 | Gaoler (red) |
| 40–98 | Masa & Mune (blue) |
| 99 | Pink Nu (one of the hardest fights in the game) |

### 2.5 Status Effects

Negative statuses (inflicted by enemy attacks or by player techs like Crono's Confuse, Lucca's Hypno Wave, Marle's Provoke):

- **Poison** — gradual HP drain on each ATB tick / turn boundary; bubble icon.
- **Sleep** — incapacitated until hit; "Zzz" icon.
- **Chaos** — character attacks an ally or enemy at random; star icon. (Crono's tech *named* "Confuse" inflicts the *Chaos* status — the in-game status is "Chaos," not "Confuse.")
- **Lock** — silence-equivalent; disables all Single, Dual, and Triple Techs for the rest of the battle. Rare; only applied at the start of fights by certain enemies.
- **Slow** — halves ATB fill rate.
- **Stop** — ATB gauge frozen until cleared.
- **Blind** — physical attacks miss frequently.
- **Berserk** — auto-attacks only; player loses control.

Positive statuses (granted by player techs like Marle's Haste, Lucca's Protect, or accessory effects):

- **Haste** — roughly doubles ATB fill rate; red character outline.
- **Protect** — physical defense up by ~33%; yellow outline.
- **Shield** — magic defense up.
- **Barrier** — magic defense up (stronger than Shield in some sources; the game has both).
- **Shade / Specs** — utility buffs available via items.

Status protection comes from accessories (Ribbon, Vigil's Hat, Amulet) and certain armor pieces.

---

## 3. World & Time Travel

### 3.1 Eras

Seven canonical eras:
- **65,000,000 BC** — Prehistory. Humans (Ioka tribe) vs. Reptites. No magic. Lavos arrives at the end of this era.
- **12,000 BC** — Antiquity / Kingdom of Zeal. Floating sky-continents lit by the Mammon Machine. Enlightened Ones above, Earthbound Ones below.
- **600 AD** — Middle Ages. Kingdom of Guardia at war with Magus's Mystics.
- **1000 AD** — Present. Peaceful Guardia; the protagonists' home era.
- **1999 AD** — The Day of Lavos. Not freely explorable; cinematic only and as a final-fight endpoint.
- **2300 AD** — Future. Post-apocalyptic ruins. Survivors in domes; rogue robots outside.
- **End of Time** — A timeless hub plaza where the party regroups, swaps members, and meets Spekkio and Gaspar.

Geography mostly aligns across eras (a mountain in 600 AD is still there in 1000 AD), enabling time-puzzle quests.

### 3.2 Travel Mechanisms

- **Time Gates** — fixed glowing portals between eras. Initially activated by Marle's Pendant; later operable with **Lucca's Gate Key**.
- **The Epoch / Wings of Time** — a time-traveling vehicle built by Belthasar, acquired mid-game. After an upgrade, it gains overworld flight, allowing the party to land outside dungeons in any era.
- **End of Time pillars of light** — each pillar leads to a specific era. Visiting the End of Time is also when the party rotates which three of the seven members are active.

### 3.3 Sealed Chests & Sealed Doors

A signature time-puzzle mechanic. **Sealed Chests** are blue-glowing chests scattered across multiple eras; **Sealed Doors** likewise. They were a security technology of Zeal that survived the kingdom's fall and ended up dispersed across history.

- They cannot be opened until the party **charges Marle's Pendant** at the **Mammon Machine** in 12,000 BC.
- Once charged, the same Pendant opens every Sealed Chest and Sealed Door across all eras.
- **The "double-dip" trick:** the same physical chest exists in 600 AD and in 1000 AD. If the player **inspects** the chest in 600 AD without taking the contents, then travels to 1000 AD and takes the (upgraded) item there, they can return to 600 AD and also collect the lesser version. The player ends up with both. We will preserve this trick — it's part of the game's culture.

The Pendant is also what opens the **Black Omen** entrance after Zeal rises in the late game.

---

## 4. Playable Characters

Seven recruitable characters. Each has a unique weapon class, element, and tech style.

### Crono
- **Era:** 1000 AD. **Weapon:** Katana. **Element:** Lightning.
- **Role:** Balanced physical attacker with strong AoE; de-facto party leader.
- **Single Techs (TP-learn order):** Cyclone (5 TP), Slash (90), Spincut (160), Life (400), Lightning 2 (500), Confuse (800), Luminaire (1000). **Lightning** is granted free by Spekkio, not via TP.
- **Recruited:** Game start (Millennial Fair).
- **Note:** Silent protagonist. Forced into the party until his death event at the Ocean Palace; optional thereafter. The "Confuse" tech inflicts the **Chaos** status (see §2.5).

### Marle (Princess Nadia)
- **Era:** 1000 AD. **Weapon:** Crossbow. **Element:** Water/Ice.
- **Role:** Primary healer, ice mage, ranged physical.
- **Single Techs:** Aura, Provoke, **Ice** (Spekkio-granted), Cure, Haste, Ice 2, Cure 2, Life 2.
- **Recruited:** Millennial Fair (immediate); rejoins permanently after the Manolia Cathedral rescue.

### Lucca Ashtear
- **Era:** 1000 AD. **Weapon:** Gun. **Element:** Fire.
- **Role:** Fire mage, status/utility caster, secondary item healer.
- **Single Techs:** Flame Toss, Hypno Wave, **Fire** (Spekkio-granted), Napalm, Protect, Fire 2, Mega Bomb, Flare.
- **Recruited:** Millennial Fair (Telepod demonstration); joins permanently after Marle's disappearance.

### Robo (Prometheus / R-66Y)
- **Era:** 2300 AD. **Weapon:** Mechanical arm. **Element:** Shadow (offensive techs only — heals are non-elemental).
- **Role:** Tank / sustain — high HP/defense, party-wide healing via Heal Beam.
- **Single Techs:** Rocket Punch, Cure Beam, Laser Spin, Robo Tackle, Heal Beam, Area Bomb, Shock, Uzzi Punch.
- **Recruited:** 2300 AD, Proto Dome, repaired by Lucca.
- **Note:** Robo does not visit Spekkio for awakening; his "magic" is mechanical.

### Frog (Glenn)
- **Era:** 600 AD. **Weapon:** Broadsword (Masamune is his ultimate). **Element:** Water.
- **Role:** Well-rounded physical attacker with healing/water magic.
- **Single Techs:** Slurp, Slurp Cut, **Water** (Spekkio-granted), Heal, Leap Slash, Cure 2, Frog Squash, Water 2.
- **Recruited:** 600 AD, after the Hero Medal is restored to him; commits permanently after the Masamune is reforged.
- **Note:** **Frog Squash** is a low-HP-scaling tech. Damage roughly = (MaxHP − CurrentHP) × Stamina × 10 / 280, modified by enemy defense. The lower Frog's HP, the bigger the hit. (One of three "crisis"-style scaling weapons/techs in the game alongside Crisis Arm and Doomsickle.)
- **Personality:** Cursed by Magus into a frog form; honor-bound knight, guilt-ridden over Cyrus's death.

### Ayla
- **Era:** 65,000,000 BC. **Weapon:** Fists (cannot equip or unequip — see §6.1). **Element:** None.
- **Role:** Pure physical powerhouse — highest base Power stat. No magic.
- **Single Techs:** Kiss, Roundillo Kick, Cat Attack, Rollo Kick, Boulder Toss, **Charm**, Tail Spin, Triple Kick.
- **Recruited:** 65M BC, Ioka Village, after recovering the stolen Gate Key from the Reptites.
- **Note:** Charm (see §6.5) is one of the most strategically important abilities in the game. Ayla also does not visit Spekkio.

### Magus (Janus Zeal)
- **Era:** 12,000 BC. **Weapon:** Scythe. **Elements:** All four — uniquely.
- **Role:** Glass-cannon black mage; covers every element. His Lightning 2, Ice 2, and Fire 2 are roughly **30% stronger** than the same-name spells from Crono / Marle / Lucca.
- **Single Techs:** Lightning 2, Ice 2, Fire 2, Dark Bomb, Magic Wall (self-buff: reduces magical damage taken), Dark Mist, Black Hole, Dark Matter.
- **Recruited:** Optional. After the Ocean Palace catastrophe, the party can spare him at North Cape.
- **Note:** No Dual/Triple Techs in the SNES original (DS port adds them; out of scope for v1). He joins with all eight Single Techs already learned and equipped with the **Amulet** (status immunity).

---

## 5. Story & Sidequests

### 5.1 Main Story Beats (in order)

1. **Millennial Fair (1000 AD)** — Crono meets Marle; Lucca's Telepod resonates with Marle's pendant and warps her through a time gate.
2. **Rescue in 600 AD** — The party retrieves Marle, who has been mistaken for her ancestor Queen Leene. They free the real Leene from Manolia Cathedral (boss: Yakra), correcting history.
3. **Trial of Crono (1000 AD)** — Trial for "kidnapping the princess." This is a unique mini-system: the player's **earlier behavior at the Millennial Fair** generates evidence for or against Crono. Specific actions tracked include trying to sell the Pendant, eating the old man's food, walking off while Marle buys candy, ignoring the lost cat, and grabbing the dropped Pendant before checking on Marle. Each of seven jurors then votes guilty or innocent based on these flags. **The verdict only affects flavor and a small reward** (more innocent verdicts → more Ethers in the prison cell). Regardless of outcome, the **Chancellor** (later revealed to be Yakra XIII in disguise) circumvents the court and sentences Crono to death. The party escapes through a forest gate to 2300 AD.
4. **2300 AD Apocalypse** — Discovery of the Day of Lavos via the Arris Dome recording. Robo is repaired at Proto Dome.
5. **End of Time** — Time-travel freedom unlocked. Gaspar explains the gates; the party can now move between eras.
6. **Mystic War (600 AD)** — Frog is recruited; Masamune retrieved at Denadoro and reforged by Melchior.
7. **Magus's Castle** — Defeat Ozzie/Flea/Slash, then Magus. Magus's interrupted Lavos summon throws everyone to 65M BC.
8. **Prehistory** — Ayla is recruited. Reptite war culminates at the Tyranno Lair, ending with Lavos's meteor strike.
9. **Kingdom of Zeal (12,000 BC)** — Meet Schala, Janus, the Prophet (Magus). Mt. Woe collapses. The Mammon Machine plot accelerates.
10. **Ocean Palace / Crono's Death** — Lavos awakens. Crono shields the party and is disintegrated. Zeal sinks; the Black Omen rises.
11. **Epoch acquired** — Wings of Time stolen by Dalton, then reclaimed.
12. **Crono's Revival (optional but canonical)** — Time Egg + Norstein Bekkler's Clone + summit of Death Peak in 2300 AD.
13. **Magus revealed / recruited** — North Cape; spare or kill.
14. **Sidequests (open phase)** — see §5.2.
15. **Black Omen** — Optional megadungeon, accessible in 600 AD, 1000 AD, or 2300 AD.
16. **Final Lavos Fight** — Three phases: outer shell, inner shell, Lavos Core (left Bit / right Bit / center body — only the center body counts; killing the wrong target triggers a bad ending).

### 5.2 Major Sidequests

Most are unlocked once the party has the Epoch and is in the open phase before the final Lavos fight. They generally reward an ultimate weapon, signature accessory, or stat boost.

- **Frog — Cyrus's Grave at Northern Ruins.** A multi-era dungeon repaired by sending **Tools** to the Choras carpenter in 600 AD. Putting Cyrus's spirit to rest grants Frog his strongest endgame gear.
- **Robo — Fiona's Forest.** In 600 AD, Fiona near Choras wants to replant the Sunken Desert. Robo stays behind 400 years to help; in 1000 AD a forest exists. Reward: **Greendream** (auto-revive accessory). Prerequisite: clearing the **Sunken Desert** (boss: Retinite).
- **Robo — Geno Dome.** Mother Brain plot in 2300 AD. Reward: **Crisis Arm** (Robo's ultimate), Terra Arm, Megaelixir, Atropos's Ribbon.
- **Lucca — Mother's Fate.** A gate that opens in Lucca's house late game lets Lucca save her mother Lara from the conveyor belt accident from her childhood.
- **Marle — Rainbow Shell / King's Trial.** Retrieve the Rainbow Shell from **Giant's Claw** (600 AD, but the dungeon links across eras). In 1000 AD, the Chancellor (another Yakra descendant) frames King Guardia; Marle uses the Shell as evidence. Reward: **Prism Dress**, **Prism Helm**, **Prism Specs** crafted by Melchior from Shell scraps.
- **Crono — Death Peak.** Required if the player wants Crono back after his Ocean Palace death. Needs the **Time Egg** (from Gaspar) and **Crono's Clone** (from Norstein Bekkler at the Millennial Fair). Skipping this is the major route to alternate endings.
- **Sun Stone quest.** Spans 65M BC → 1000 AD. Place the **Moon Stone** in Sun Keep in prehistory; retrieve it fully charged in 1000 AD as the **Sun Stone**. Used to forge **Wondershot** (Lucca), **Sun Shades**, and feed the **Rainbow** forging at Melchior.
- **Ozzie's Fort (600 AD).** Optional cleanup of Magus's three lieutenants in their hideout.
- **Black Omen.** Optional megadungeon, accessible from 600 AD, 1000 AD, or 2300 AD. Boss gauntlet ending in Queen Zeal + Mammon Machine. Defeating it removes the Omen from the world map of every era.

Note: Magus has no personal sidequest in the SNES original. Ayla has no dedicated character quest either — her contribution is the Charm-only Tab/equipment economy (see §6.5).

### 5.3 Endings (13 in SNES original)

Endings are determined by **when in the story Lavos is defeated**. Lavos can be challenged from the End of Time bucket or by ramming the Epoch into the 1999 AD shell. Some endings require New Game+ because they need Lavos defeated before plot points that are otherwise mandatory.

1. **Beyond Time** — Canonical ending; Lavos defeated post-Crono-revival. Variants depend on party composition and sidequest completion.
2. **Reunion** — Post-revival but pre-Magus encounter at North Cape.
3. **The Dream Project** — Lavos beaten from the Telepod at the Millennial Fair on NG+ before recruiting anyone. Dev team cameo.
4. **The Successor of Guardia** — Beaten right after the trial.
5. **Good Night** — Beaten after seeing the future, before the Wings of Time.
6. **The Legendary Hero** — Beaten after the Cathedral but before the Masamune is reforged. Tata is acclaimed the hero.
7. **The Unknown Past** — Post-Masamune, pre-Magus.
8. **People of the Times** — Post-Magus, pre-Tyranno Lair.
9. **The Oath** — Post-Tyranno Lair, pre-Ocean Palace.
10. **Dino Age** — Post-Ocean-Palace, pre-Crono-revival. Reptites have evolved and rule the world.
11. **What the Prophet Seeks** — Magus in party but Crono still dead.
12. **A Slide Show?** — Post-revival, sidequests incomplete; Marle and Lucca's slideshow turns into commentary on the men of the cast. Crono delivers his only spoken line.
13. **The Apocalypse** — The **bad ending**: triggered when the party **loses** the final Lavos fight. Lavos's eruption is shown from the Truce Dome director's view as the dome collapses around him; the planet greys out and the screen reads "...But the future refused to change."

(DS port adds **Dream's Epilogue** / Developer's Office variants. Out of scope for v1.)

### 5.4 New Game+

See §10.9 for full carry-over/reset details. In short: levels, equipment, items, learned techs carry over. Story flags, key items, and the Epoch reset. Gold resets to 200G. A warp-to-Lavos option is unlocked early, enabling the 13 endings based on when Lavos is fought.

---

## 6. Items & Equipment

### 6.1 Weapons

Each character uses a unique weapon class. Slots are class-locked: you cannot put Crono's katana on anyone else.

#### Weapon stat schema

Every weapon record carries:

| Field | Notes |
|---|---|
| **Attack Power** (AP) | Base damage value used by the damage formula. |
| **Critical Hit %** | If non-zero, overrides the character's base crit rate. Otherwise the wielder's base rate is used: Crono 10%, Marle 20%, Lucca 20%, Robo 10%, Frog 23%, Magus 10%. Ayla's varies by fist tier. |
| **Special** | Optional. Stat bonus, on-hit status, anti-type multiplier, or a custom damage formula that overrides AP entirely. |

**Critical hit damage:** ×2 by default. Some weapons override to ×4 (Shiva Edge — only when crit fires) or to a flat 9999 (Bronze Fist; Apocalypse Arm in DS port).

#### Damage formula (physical attack)

Different characters route off different stats — this is non-obvious and matters for builds:

- **Crono, Frog, Robo, Magus** — Power-driven. 1 PWR ≈ 4/3 effective attack contribution.
- **Ayla** — Power-driven, more efficient: 1 PWR ≈ 1.75 attack.
- **Marle and Lucca** — **Hit-driven**, not Power. 1 Hit ≈ 2/3 attack contribution. They want **Hit Ring / Sight Cap**, not Power Ring.

Effective damage roughly: `(Weapon AP + character contribution from Power or Hit) × random factor − target Stamina/Defense`. Crit doubles (or overrides). The full formula with multipliers and caps lives at StrategyWiki's Formulae page (see §12 References) — flagged in §11 to verify before locking in numbers.

#### Crono — Katanas

| Weapon | AP | Special | Acquisition |
|---|---:|---|---|
| Mop | 1 | joke weapon; charm only | Charm a specific Nu |
| Wood Sword | 3 | — | starting weapon |
| Iron Blade | 7 | — | shop, 1000 AD Truce |
| Steel Saber | 15 | — | shop |
| Lode Sword | 20 | — | shop, 600 AD |
| Bolt Sword | 25 | — | chest, 2300 AD (despite the name, **no Lightning element**) |
| Red Katana | 30 | — | chest |
| Flint Edge | 40 | — | chest, 12,000 BC |
| Slasher | 43 | +2 Speed | drop from Slash, Magus's Castle |
| Aeon Blade | 70 | — | shop, late Antiquity |
| Demon Edge | 90 | — | chest, late game |
| Alloy Blade | 110 | — | chest, Black Omen |
| Star Sword | 125 | — | chest |
| Vedic Blade | 135 | — | chest |
| Swallow | 145 | +3 Speed | chest |
| Kali Blade | 150 | 2× crit rate | chest |
| Slasher 2 | 155 | crit boost | chest |
| Shiva Edge | 170 | crit deals ×4 (~7% rate) | chest |
| **Rainbow** | **220** | **70% crit rate** | forged by Melchior from Sun Stone + 10 Rainbow Shells, or chest in Black Omen |

#### Marle — Crossbows / Bowguns

| Weapon | AP | Special | Acquisition |
|---|---:|---|---|
| Bronze Bow | 3 | — | starting weapon |
| Iron Bow | 15 | — | shop |
| Lode Bow | 20 | — | shop |
| Robin Bow | 25 | — | chest / shop |
| Sage Bow | 40 | — | chest |
| Dream Bow | 60 | — | chest |
| Comet Arrow | 80 | — | chest |
| Sonic Arrow | 100 | inflicts **Slow** on hit | chest |
| Siren | 140 | inflicts **Stop** on hit | chest, Northern Ruins |
| Stardust Bow | 150 | inflicts Chaos; 2× crit rate | chest |
| **Valkerye** | **180** | **2× crit rate**; anti-dragon bonus | Sun Stone forging chain |

#### Lucca — Guns

| Weapon | AP | Special | Acquisition |
|---|---:|---|---|
| Air Gun | 5 | — | starting weapon |
| Dart Gun | 7 | — | shop |
| Auto Gun | 15 | — | shop / chest |
| Plasma Gun | 25 | inflicts **Stop on machines** | chest |
| Ruby Gun | 40 | — | chest, 12,000 BC |
| Dream Gun | 60 | — | chest |
| Mega Blast | 80 | — | chest |
| Shock Wave | 110 | inflicts **Chaos** | chest, Black Omen |
| **Wondershot** | **250** | damage rolls ×1/10, ×1/2, ×1, ×2, or ×3 of base on the in-game seconds counter — variable | Sun Stone forging chain |

#### Robo — Mechanical arms

| Weapon | AP | Special | Acquisition |
|---|---:|---|---|
| Tin Arm | 20 | — | starting equipment |
| Hammer Arm | 25 | — | shop |
| Mirage Hand | 25 | — | chest |
| Stone Arm | 40 | — | chest |
| Doom Finger | 50 | — | chest |
| Magma Hand | 70 | — | chest |
| Megaton Arm | 90 | — | chest |
| Big Hand | 105 | — | chest |
| Kaiser Arm | 120 | — | chest, Black Omen |
| Giga Arm | 135 | — | chest |
| Terra Arm | 150 | — | Geno Dome reward |
| **Crisis Arm** | **1** (override) | **damage = base × (last digit of Robo's current HP)** — HP ending in 9 hits hardest; ending in 0 deals nothing | Geno Dome |

#### Frog — Broadswords

| Weapon | AP | Special | Acquisition |
|---|---:|---|---|
| Bronze Edge | 6 | — | joining equipment |
| Iron Sword | 10 | — | shop |
| Masamune (initial) | 75 | story-required; lowers Magus's magic defense; affects Mammon Machine | reforged by Melchior from Bent Hilt + Bent Sword + Dreamstone |
| Flash Blade | 90 | — | chest |
| Pearl Edge | 105 | 1.5× damage vs magic-type enemies | chest |
| Rune Blade | 120 | +4 Magic | chest |
| Demon Hit | 120 | 2× damage vs magic-type enemies | chest |
| Brave Sword | 135 | 2× damage vs magic-type enemies | chest, Northern Ruins |
| **Masamune (upgraded)** | **200** | 2× damage vs magic-type enemies; affects Mammon Machine and Lavos's Magus-form copy | Cyrus's Grave sidequest at Northern Ruins reforges it via the Sun Stone |

#### Ayla — Fists (locked, auto-upgrade by level)

| Levels | Fist tier | Crit rate | Special |
|---|---|---:|---|
| 1–23 | Fist I | 20% | base |
| 24–47 | Fist II | 25% | — |
| 48–71 | Fist III | 30% | — |
| 72–95 | Iron Fist | 35% | crits inflict **Chaos** status |
| 96–99 | Bronze Fist | 10% | **crits deal flat 9999 damage** (even on bosses and Lavos) |

Ayla cannot equip or unequip. Her fists remain on her even during the Blackbird sequence where everyone else is stripped of gear.

#### Magus — Scythes

| Weapon | AP | Special | Acquisition |
|---|---:|---|---|
| Dark Scythe | 120 | — | joining equipment |
| Hurricane | 135 | — | chest |
| Star Scythe | 150 | — | chest |
| Judgment Scythe | 155 | — | chest |
| **Doom Sickle (Doomsickle)** | **160** | **damage × (1 + fallen allies)** — base, 2×, or 3× depending on KO count | chest, Northern Ruins |

#### Critical-hit build path

The "crit-build" centerpiece weapons are: **Slasher / Slasher 2 / Kali Blade / Shiva Edge / Rainbow** (Crono); **Stardust Bow / Valkerye** (Marle); **Bronze Fist** (Ayla); upgraded **Masamune + Hero Medal accessory** (Frog). Stack with Speed for more turns to fish for crits.

#### DS-port-only weapons (out of scope for v1)

The DS port adds Dimensional-Vortex weapons not in the SNES original: **Dreamseeker** (Crono, 240 AP / 90% crit), **Venus Bow** (Marle, always 777 / no crit), **Spellslinger** (Lucca, scales with MP), **Apocalypse Arm** (Robo, 1 AP / crits = 9999), **Dreamreaper** (Magus, 180 AP / 4× crit). Treat as stretch goals.

### 6.2 Armor & Helms

Universal across all characters unless marked. Gender keys: **(M)** = males only (Crono, Frog, Robo, Magus), **(F)** = females only (Marle, Lucca, Ayla), **(Lucca)** / **(Magus)** = that character only. No marker = all characters.

#### Body Armor

| Name | Def | Special | Acquisition |
|---|---:|---|---|
| Hide Tunic | 5 | — | starting (Crono, Marle) |
| Karate Gi | 10 | — | shop 300G |
| Bronze Mail | 16 | — | shop 520G (M) |
| Maiden Suit | 18 | — | chest, Cathedral (F) |
| Iron Suit | 25 | — | shop 800G |
| Titan Vest | 33 | — | shop 1200G |
| Taban Vest | 33 | Fire halved; Speed +2 | gift from Taban (Lucca) |
| Gold Suit | 39 | — | shop 1300G |
| Ruby Vest | 45 | Fire halved | trade at Ioka (3 Fangs + 3 Feathers); chest |
| Dark Mail | 45 | M.Def +5 | chest, Magus's Castle (M) |
| Red Vest | 45 | Fire halved | sealed chest 600 AD (base) |
| Blue Vest | 45 | Water halved | sealed chest 600 AD (base) |
| White Vest | 45 | Lightning halved | sealed chest 600 AD (base) |
| Black Vest | 45 | Shadow halved | sealed chest 600 AD (base) |
| Meso Mail | 52 | — | chest, Tyranno Lair |
| Mist Robe | 54 | — | chest, Magus's Castle (F) |
| Lumin Robe | 63 | M.Def +5 | shop 6500G, Algetty (F) |
| Flash Mail | 64 | — | shop 8500G, Algetty (M) |
| Red Mail | 70 | **Absorbs Fire** (heals HP) | sealed chest 1000 AD (powered-up) |
| Blue Mail | 70 | **Absorbs Water** (heals HP) | sealed chest 1000 AD (powered-up) |
| White Mail | 70 | **Absorbs Lightning** (heals HP) | sealed chest 1000 AD (powered-up) |
| Black Mail | 70 | **Absorbs Shadow** (heals HP) | sealed chest 1000 AD (powered-up) |
| Lode Vest | 71 | — | shop 8500G, Kajar |
| Aeon Suit | 75 | — | shop 9000G, Last Village |
| Raven Armor | 76 | — | starting (Magus) |
| Ruby Armor | 78 | Fire reduced 80% | trade at Ioka (10 each of Petal/Fang/Feather/Horn); Charm from Rust Tyranno |
| Taban Suit | 79 | Fire reduced 90%; Speed +3 | gift from Taban after Zeal falls (Lucca) |
| Zodiac Cape | 80 | M.Def +10 | chest, Black Omen (F) |
| Nova Armor | 82 | Status immunity | chest, Black Omen; Charm from Fangbeast (M) |
| Gloom Cape | 84 | — | chest, Ozzie's Fort (Magus) |
| Moon Armor | 85 | M.Def +10 | sealed chest 1000 AD, Northern Ruins (powered-up from Nova) (M) |
| **Prism Dress** | **99** | **Magic damage −33% (auto-Barrier)** | Rainbow Shell quest (Melchior: 1 Dress OR 3 Helms); Charm from Queen Zeal (F) |

**Vest → Mail upgrade trick:** for each elemental color, inspect the sealed chest in 600 AD without taking it, take the Mail in 1000 AD, then return to 600 AD to also collect the Vest. Both obtained per playthrough.

#### Helms

| Name | Def | Special | Acquisition |
|---|---:|---|---|
| Hide Cap | 3 | — | starting (Crono, Marle, Lucca) |
| Bronze Helm | 8 | — | shop 200G; starting (Frog) |
| Iron Helm | 14 | — | shop 500G |
| Beret | 17 | — | shop 700G (F) |
| Gold Helm | 18 | — | chest, Denadoro; given by Knight Captain (M) |
| Rock Helm | 20 | — | trade at Ioka; starting (Ayla) |
| CeraTopper | 23 | — | chest, Tyranno Lair (×2, missable) |
| Taban Helm | 24 | M.Def +10 | gift from Taban (Lucca) |
| Glow Helm | 25 | — | shop 2300G, Algetty (M) |
| Doom Helm | 29 | — | starting (Magus) |
| Lode Helm | 29 | — | shop 6500G, Kajar |
| Sight Cap | 30 | prevents Chaos | chest, Ozzie's Fort / Giant's Claw; shop 20000G |
| Memory Cap | 30 | prevents Lock | chest, Death Peak; shop 20000G |
| Time Hat | 30 | prevents Stop + Slow | chest, Mt. Woe; shop 30000G |
| Aeon Helm | 33 | — | shop 7800G, Last Village |
| R'bow Helm | 35 | Lightning halved | Charm from Red Mudbeast |
| Mermaid Cap | 35 | Water halved | Charm from Blue Mudbeast |
| Dark Helm | 35 | Shadow halved | chest, Death Peak (M) |
| **Haste Helm** | **35** | **auto-Haste** | chest, Black Omen; Charm from Elder Lavos Spawn (head) |
| Vigil Hat | 36 | status immunity | chest, Geno Dome / Black Omen; shop 50000G |
| Safe Helm | 38 | auto-Protect (phys. damage −33%) | chest, Forest Ruins (choice: this OR Swallow) |
| **Prism Helm** | **40** | **M.Def +9; magic damage −33%; status immunity** | Rainbow Shell quest (Melchior: 3 Helms OR 1 Dress) |
| Gloom Helm | 42 | status immunity; Speed +1 | chest, Ozzie's Fort (Magus) |
| Ozzie Pants | 45 | auto-Chaos + HP drain on wearer (joke) | Charm from Ozzie |

### 6.3 Accessories

One slot per character. Accessories **cannot be bought or sold** — all are obtained from chests, sealed chests/doors, quest rewards, Charm, or as starting equipment.

| Name | Effect | Acquisition |
|---|---|---|
| Bandana | Speed +1 | starting (Crono) |
| Ribbon | Hit +2 | starting (Marle) |
| Power Glove | Power +2 | chest, Truce Canyon 600 AD |
| Power Scarf | Power +4 | starting (Ayla) |
| Power Ring | Power +6 | sealed chest, Guardia Forest 1000 AD |
| Magic Scarf | Magic +2 | chests, Heckran Cave / Fiendlord's Keep / Cursed Woods |
| Magic Ring | Magic +6 | sealed chest, Magic Cave 600 AD |
| Defender | Stamina +2 | chest, Cathedral 600 AD; starting (Robo) |
| Muscle Ring | Stamina +6 | chest, Sunken Desert; Charm from Incognito / Tera Mutant (upper) |
| Hit Ring | Hit +10 | sealed door, Arris Dome; Charm from Giga Mutant (upper) |
| Speed Belt | Speed +2 | chest, Cathedral 600 AD |
| Dash Ring | Speed +3 | sealed chest, Heckran Cave; chest, Ozzie's Fort; Charm from Flyclops |
| Silver Earring | Max HP +25% | chest, Denadoro Mts. |
| Gold Earring | Max HP +50% | sealed door, Arris Dome; Charm from Synchrite |
| Silver Stud | MP cost ×0.5 | chest, Denadoro Mts. |
| **Gold Stud** | **MP cost ×0.25** | sealed door, Trann Dome; Charm from Flyclops |
| Wall Ring | M.Def +10 | sealed chest, Heckran Cave 1000 AD |
| Sight Scope | shows enemy HP | starting (Lucca) |
| Charm Top | boosts Charm success rate (Ayla) | sealed door, Bangor Dome |
| Berserker | auto-Berserk + auto-Protect; phys. damage ×1.5; uncontrollable | chest, Lab 16 (2300 AD) |
| Rage Band | 50% counter-attack chance | chest, Sewers 2300 AD |
| Frenzy Band | 80% counter-attack chance | chest, Giant's Claw 600 AD |
| Third Eye | Evade ×2.5 | Hunting Range (Nu when raining); Charm from Nizbel / Nizbel II |
| Wallet | converts all EXP to Gold | sealed door, Bangor Dome |
| **Amulet** | **status immunity (all negative)** | starting (Magus); dropped if Magus killed at North Cape |
| Flea Vest | M.Def +12 | Charm from Flea, Ozzie's Fort |
| Magic Seal | Magic +5, M.Def +5 | chest, Black Omen |
| Power Seal | Power +10, Stamina +10 | chest, Black Omen; Charm from Tera Mutant (lower) |
| **Green Dream** | **auto-revive once per battle** | quest reward: Fiona's Forest |
| **Hero Medal** | Masamune crit rate → 50% (Frog only) | Tata's house, Porre 600 AD |
| **Sun Shades** | **all damage dealt +25%** | quest reward: Sun Stone (Taban forges it) |
| **Prism Specs** | **all damage dealt +50%** | quest reward: Rainbow Shell + Sun Stone (Melchior forges) |

**Robo's Ribbon** is not an equippable accessory — defeating Atropos XR in Geno Dome permanently adds +3 Speed and +10 M.Def to Robo's base stats.

#### Triple Tech Rock accessories

Rocks occupy the accessory slot on one participant. Only one Rock effect is active at a time.

| Rock | Enables | Characters | Acquisition |
|---|---|---|---|
| Black Rock | Dark Eternal | Marle + Lucca + Magus | Kajar 12,000 BC (book puzzle) |
| Blue Rock | Omega Flare | Lucca + Robo + Magus | chest, Giant's Claw |
| Gold Rock | Grand Dream | Marle + Frog + Robo | Denadoro Mts. (Frog must lead) |
| Silver Rock | Spin Strike | Frog + Robo + Ayla | Laruba Ruins (post-Zeal-fall) |
| White Rock | Poyozo Dance | Marle + Lucca + Ayla | chest, Black Omen |

#### DS-port-only accessories (out of scope for v1)

Dragon's Tear, Valor Crest, Champion's Badge, Angel's Tiara, Master's Crown. See DS equipment guides.

### 6.4 Consumables

**Healing.** Tonic (~50 HP) → Mid Tonic (~200) → Full Tonic (full); Heal (cures status); Revive (single ally, partial HP); **Shelter** (full party HP/MP — usable **only on save points**); Lapis (party AoE moderate heal); Athenian Water; Ambrosia (full party HP/MP, very rare).

**MP.** Ether → Mid Ether → Full Ether; Elixir (full HP+MP, single); **Megalixir** (full HP+MP, party — Charm-only from Nu).

**Combat utility.** Barrier Sphere (boost magic defense for one battle); Shield Sphere (boost physical defense for one battle).

**Permanent stat tabs.** Power Tab (+1 Power), Magic Tab (+1 Magic), Speed Tab (+1 Speed). Found in chests, hidden behind objects, given by NPCs (e.g., the Power Tab the boy on Zenan Bridge throws), and obtainable via Charm.

### 6.5 Charm Ability (Ayla)

Activated like any single-target Tech, costs no MP. Targets one enemy.

- Each enemy has a separate **drop slot** (post-battle) and **charm slot** (mid-battle steal). The charm slot is usually rarer.
- The stolen item enters inventory immediately, mid-battle.
- Charm rate is high on most enemies, low on bosses, and zero on charm-immune enemies. The **Charm Top** accessory raises the rate.
- Charming does not block normal post-battle drops.
- A significant slice of endgame gear is **Charm-only**: Gold Stud, Megalixir, Sun Shades, top-tier elemental Plate armor, Speed/Magic/Power Tabs from rare enemies (Son of Sun, Nu, Mega Mutant, Rubble), and joke items like the Mop.

Charm makes Ayla effectively mandatory for completionist runs.

### 6.6 Key Items

- **Pendant** — Marle's heirloom; activates time gates and (when energized at the Mammon Machine) opens sealed chests / sealed doors and the Black Omen.
- **Gate Key** — Lucca's invention; opens time gates without external power. Stolen during the Cathedral arc; recovered later.
- **Dreamstone** — red rock from Ayla's tribe, used to reforge the Masamune.
- **Ruby Knife** — fashioned from Dreamstone by Melchior; shatters the Mammon Machine.
- **Rainbow Shell** — from Giant's Claw (600 AD); forges Prism gear and serves as evidence at the King's trial.
- **Sun Stone / Moon Stone** — Moon Stone is the un-charged form, stolen by Marco in 1000 AD. Once recovered and placed in Sun Keep across eras, it charges into the Sun Stone, used for ultimate-weapon forging.
- **Hero Medal** — Tata's medal proving the true hero; equippable accessory on Frog.
- **Robo's Ribbon** — found in Atropos XR's wreckage in Geno Dome; Robo's signature accessory.
- **Bent Hilt / Bent Sword** — the two halves of the Masamune, found in Denadoro Mountains.
- **C. Trigger (Chrono Trigger / Time Egg)** — Gaspar's gift; used with Crono's Clone at Death Peak to revive Crono.
- **Clone (of Crono)** — purchased from Norstein Bekkler's carnival at the Millennial Fair for prize tickets.
- **Poyozo Doll** — cosmetic Bekkler prize.
- **Tools** — given to the carpenter in Choras (1000 AD); used to repair the Northern Ruins in the past.
- **Bike Key / Jetbike Key** — unlocks the Jet Bike race against Johnny in 2300 AD on Lab 32.
- **Jerky** — given to the Mayor of Porre's wife in 600 AD; alters Porre's wealth in 1000 AD.
- **PowerMeal** — used in the Reptite arc to feed an NPC.
- **Petal / Fang / Horn / Feather** — monster parts Ayla can Charm from prehistoric enemies; traded at Melchior / Trading Post for mid-tier gear.

---

## 7. Minigames

Minor diversions woven through the world. None are individually game-changing, but the rewards (Silver Points, Tabs, key items) hook into the main systems.

- **Millennial Fair (1000 AD) — opening hub.**
  - **Soda-Guzzling Contest** — mash A as fast as possible to drink a can; 5 Silver Points reward.
  - **Norstein Bekkler's Tent of Horrors** — high-difficulty mini-games (cup-shuffling, cat-catching, lookalike) that **cost** Silver Points (10/40/80) and award unique prizes including **Crono's Clone**, the **Poyozo Doll**, and a Power Tab.
  - **Gato** the singing robot — small fight, gives Silver Points. Acts as the battle tutorial.
  - **Crono's Race** — running race against a man at the fair, Silver Point reward.
  - Other mini-games: telepod display, dance machines.
- **Hunting Range (65,000,000 BC).** Hunt wild prehistoric animals to drop **Petal**, **Fang**, **Horn**, **Feather** (the same items Ayla can Charm). Trade them to the Ioka Trading Hut for special equipment.
- **Drinking contest with Ayla (65,000,000 BC).** Part of Ayla's recruitment sequence at Ioka — Ayla challenges the party, knocks them out, and the Reptite raid follows; the party joins forces with her after.
- **Johnny's Race (2300 AD).** With the **Bike Key** from Doan, race the robot Johnny down the abandoned highway in Lab 32 to bypass the obstacle. Re-runnable for fun once unlocked.

---

## 8. Economy & Shops

**Currency:** G (Gold). Single currency. No secondary currency except **Silver Points** at the Millennial Fair (Bekkler's Carnival), which buy Crono's Clone, Poyozo Doll, Power Tab, etc.

**Shops by era:** Truce, Porre, Choras, Medina, Bekkler's Carnival (1000 AD); Truce / Dorino / Porre / Choras / Medina (600 AD); Trann / Arris / Proto / Keeper's Domes (2300 AD); Enhasa / Kajar / Zeal Palace / Algetty / Last Village (12,000 BC); Ioka Trading Hut (65M BC, barter only — see §10.4).

**Shop mechanics:**
- Triggered by talking to NPC shopkeepers → dialogue → shop menu overlay.
- Types are not rigid — most are mixed (equipment + consumables). Inns are a fixed-price full-heal service.
- **Selling:** equipment and consumables at **50% of buy price**. **Accessories cannot be sold.**
- **Stat comparison** shown when browsing equipment (attack/defense delta per character).
- **No "buy multiple"** in SNES — each purchase confirmed individually.

**Medina overpricing:** before Ozzie's Fort is cleared, Medina shops charge ~128× normal price (capped at 65,535G — 16-bit max). After Ozzie's Fort, prices drop to normal. Binary toggle, not gradual.

**Gear acquisition tiers:**
- *G-only (shop):* tonics, basic weapons, early helms, Bandana, Power/Magic Ring, Shelter, Heal, Revive, basic armor.
- *Chest-only:* most mid/late weapons, Speed Belt, Defender, Wall Ring.
- *Charm-only:* Gold Stud, Megalixir, Sun Shades, top-tier elemental Plate, several Tabs.
- *Quest-reward only:* Greendream, Hero Medal, Robo's Ribbon, Prism Specs, Sun Stone, upgraded Masamune, Wondershot, Rainbow.

**Income inflation:** the **Wallet** accessory converts all EXP to Gold (more G per battle, zero EXP gain). Black Omen enemies are the canonical farming spot; selling charmed Petal/Fang/Horn/Feather stacks is the standard infinite-G loop.

---

## 9. Bestiary

Enemies are organized by era. Most enemies have a typical elemental weakness reflecting their habitat. Full data tables are split across three docs:

- [docs/bestiary.md](docs/bestiary.md) — stat tables (HP, EXP, G, TP, weakness, drop, charm) for regular enemies and bosses, plus regular enemy behavior (paired mechanics, state changes, counters, status inflictors)
- [docs/boss-ai.md](docs/boss-ai.md) — per-boss AI specs: attack lists, phase transitions, counter triggers, kill-order requirements, ATB speed values

Summary by era below.

### 9.1 65,000,000 BC — Dinosaurs & Reptites
Reptite warriors and mages, raptors (Kilwala, Terrasaur, Megasaur), pterosaurs (Avian Rex), giant insects, Roundillo / Rolypoly. Many lightning-weak. **Bosses:** Nizbel, Nizbel II, Black Tyranno, Azala.

### 9.2 12,000 BC — Antiquity / Magical Beasts
Mages, Blue Imps, Jinn, Bantam Imps, mermen, undead near Mt. Woe. **Bosses:** Golem, Golem Twins, Giga Gaia, Mud Imp, Lavos Spawn, Queen Zeal, Mammon Machine.

### 9.3 600 AD — Mystics & Medieval Beasts
Mystic imps and goblins, henches, knights, Hench slimes, undead in Cursed Woods, naga-ettes, ogan-types in Magus's Castle. **Bosses:** Yakra, Zombor, Masa & Mune, Ozzie, Flea, Slash, Magus, Retinite, Rust Tyranno.

### 9.4 1000 AD — Wildlife & Mystic Remnants
Mostly wildlife (naga-ettes, blue imps, gnashers, jinn bottles, kilwalas) since the world is at peace; surviving Mystics in Medina. **Bosses:** Heckran, Dragon Tank, Yakra XIII, Rust Tyranno (resurrected).

### 9.5 2300 AD — Robots & Mutants
Proto-2/3/4 robots, Bugger, Acid/Alkaline pairs, Departed/Decedent (irradiated humans), Debugger, Krawlie, Lasher, Tubster. Mostly Shadow / Fire weak. **Bosses:** R-Series, Guardian + Bits, Mother Brain + Displays, Atropos XR, Son of Sun.

### 9.6 Black Omen / Lavos
A best-of gauntlet drawing from every era plus unique enemies (Mega Mutant, Giga Mutant, Terra Mutant, Lavos Spawn, Side-Kick, Cybot, Tubster). Final fights: Queen Zeal → Mammon Machine → Lavos shell → inner shell → Lavos Core (left Bit / right Bit / center body — only the center body counts).

Antagonists and significant NPCs are covered in the §5 story beats and [docs/boss-ai.md](docs/boss-ai.md).

---

## 10. Engine & Presentation Systems

### 10.1 Dialogue & NPC Interaction

**Text box display.** Dialogue appears in a rectangular window positioned at the **top or bottom** of the screen (set per textbox instance). The speaker is identified by a **name label** in that character's color. No character portraits in the SNES original. Text typewriters character-by-character; player presses a button to advance. Window skin is player-customizable (8 presets via Config menu).

**Crono is silent.** He never has dialogue lines. Other characters speak; Crono's responses are implied or chosen via player prompts.

**Branching choices.** The game presents binary or multiple-choice prompts at specific points:
- Millennial Fair behaviors (implicit — tracked as flags, evaluated at trial)
- Trial testimony responses (lying adds guilty votes)
- Prison break: wait 3 days or escape immediately
- Character naming at recruitment
- Spare or fight Magus (North Cape)
- Revive Crono or not (optional)
- Various yes/no NPC prompts

**NPC dialogue is progression-aware.** Every NPC's text is gated by the story counter — as the main storyline flag advances, NPC dialogue updates to reflect current events. The player must press interact to trigger dialogue (not ambient auto-trigger).

**Party-composition-aware dialogue.** Certain scenes branch based on which characters are in the active party. After Crono's death, the first party member becomes the field leader and speaks in scenes where the "leader" role matters.

### 10.2 Event / Cutscene Scripting

All cutscenes are **real-time in-engine** using sprites and screen effects — no FMV in the SNES original. During scripted sequences, player input is locked; characters move along scripted paths. There is **no letterbox**; cutscenes play in the same viewport as gameplay.

**Event command types** (based on the ROM's event system and the Temporal Flux editor):

| Category | Commands |
|---|---|
| Movement | set coordinates, walk to point, set speed, set facing direction, follow path |
| Animation | play sprite animation, emote, attack pose, unique gesture |
| Dialogue | textbox (top/bottom), decision prompt (yes/no/multi), shop menu, naming screen, party select |
| Timing | wait N frames/seconds |
| Screen | fade to/from black, flash white, screen shake, color overlay, darken/brighten |
| Audio | change BGM, play SFX, stop/fade music |
| Party | add/remove character, force composition, set leader |
| Battle | force-start encounter with specific enemy group |
| State | set/check story flags, give/remove items, check item possession |
| Camera | scroll to coordinates, lock/unlock player-follow |
| Visibility | show/hide sprites, change layer priority |
| Flow | conditional branch (check flags, party composition, story counter), jump |
| Map | warp to map/coordinates, trigger gate sequence |

**Mode 7 sequences** (hardware rotation/scaling): Jet Bike Race (interactive), opening credits clock pendulum, Lavos crash animation, Magus's Castle gate vortex, Epoch ramming Lavos, ending fireworks, load/save clock display.

### 10.3 Encounter Trigger System

**Zero random encounters.** All enemies are visible on the field as sprites (or hidden in ambush positions).

**Trigger types:**
- **Contact** — player sprite touches enemy sprite. Most common.
- **Proximity** — player enters a detection radius; enemy begins chasing.
- **Ambush** — enemy is invisible or disguised (e.g., Cathedral nuns, ceiling drops, underground pops) until player steps on a trigger tile.
- **Scripted** — story-forced battles triggered by entering an area or interacting with an object.

**Enemy field behavior:**
- **Stationary** — stands in place, fights only on contact.
- **Patrol** — walks a set path; may accelerate toward player when in range. Chasers target the **last character in the party formation** (trailing follower).
- **Ambush** — invisible until trigger, then instantly engages.

**Field-to-battle transition (seamless):**
1. Player movement locks.
2. Party members spread into battle formation positions **on the same map**.
3. ATB battle menu appears.
4. Enemy sprites shift to battle positions/animations.
5. Combat proceeds. On victory, results display briefly, menu disappears, player regains control.
6. Area BGM restarts from the beginning (not resume — see §10.8).

**Avoidance.** Most encounters are avoidable by maneuvering around enemy sprites. Some are unavoidable (narrow corridors, story fights, ambushes).

**Respawn.** In most areas, enemies respawn when the player leaves and re-enters the room. Certain enemies (Rubble, bosses, story encounters) do not respawn.

### 10.4 Inventory System

**Shared pool.** One unified inventory across the entire party — not per-character. Equipment and consumables live in the same pool.

**Stacking.** Consumables stack up to **99** per item type. Equipment does not stack (each piece is a separate entry).

**Key items** are stored in a **separate list**, distinct from consumables/equipment. Cannot be used, sold, or discarded.

**Equipment storage.** Unequipped items return to the shared pool. The equipment menu can access **benched characters** (not just the active 3) to manage their gear.

**Character removal.** When a character is forcibly removed by the story, their equipped items leave with them and are temporarily inaccessible. Voluntary party swaps at the End of Time do not affect equipment — benched characters retain their gear and it's still manageable via menu.

**No sort function** in the SNES original. Items appear in a fixed internal order by item ID.

**Ioka Trading Hut** — barter system using Petals, Fangs, Horns, Feathers. Stock rotates at story milestones (3 phases). See [docs/bestiary.md](docs/bestiary.md) hunting section for material sources.

| Phase | Trigger | Notable items | Cost pattern |
|---|---|---|---|
| 1 | initial visit | Ruby Gun, Sage Bow, Stone Arm, Flint Edge, Ruby Vest, Rock Helm | 3+3 of two material types |
| 2 | after Magus defeated | Dreamstone Gun, Dreamstone Bow, Magma Hand, Aeon Blade | 3+3 (upgraded stock) |
| 3 | late game | Ruby Armor | 10 each of all 4 types |

Phase 1 items become unavailable once Phase 2 activates — missable.

### 10.5 Menu System

**Field menu** (press menu button):

| Option | Function |
|---|---|
| Status/Equip | view stats + manage equipment (all characters, including benched) |
| Item | use consumables on party members; scrollable list with quantities |
| Tech | view-only: learned techs, TP to next, Dual/Triple tabs. Cannot reorder or disable. |
| Config | battle mode, gauge speed, message speed, window color, controller, stereo/mono, cursor memory (menu/battle/skill-item), gauge display |
| Party Order | rearrange walking order of active 3 (not swap members) |
| Save | save to 1 of **3 slots**. In dungeons: only at **save point sparkles** (blue/white twinkles). On the world map: anywhere. Shelter consumable (full party HP+MP) is also restricted to save points. |

**Party swapping** is a **separate action** (Y button), only available after reaching the End of Time. Brings up a character selection screen.

**Equipment menu flow:** select character → highlight slot (weapon/helm/armor/accessory) → browse compatible unequipped items → stat comparison preview shown → confirm swap.

**Battle menu:**

| Command | Notes |
|---|---|
| Attack | standard physical, non-elemental, single target |
| Tech / Combo | Single Techs list; label changes to "Combo" when Dual/Triple available (requires multiple full ATB gauges). Greyed if MP insufficient. |
| Item | battle consumables |

**Run is NOT a menu command.** Fleeing = hold L+R simultaneously at any time. Cannot flee from bosses.

**Wait mode detail:** ATB gauges pause **only inside submenus** (Tech list, Item list). Top-level command selection (Attack/Tech/Item) does NOT pause. Start button fully pauses in both modes.

**Cursor memory** (config option): when enabled, remembers last-used command and last-selected tech/item per character between turns.

### 10.6 Party Field Movement

**Snake formation.** Leader walks in front (player-controlled); 2 followers trail behind, replaying the leader's position history with a delay.

**Movement is free-form** (non-grid-based), smooth 8-directional with pixel-level precision.

**Leader rules:**
- **Crono is forced as leader** while alive and in the party.
- After Crono's death, first character in party roster becomes leader.
- On the **world map**, only the leader sprite is shown (followers hidden).
- In field areas / dungeons, all 3 are visible.

**Follower behavior:** followers stop in place during NPC interactions. During cutscenes, followers are scripted to specific positions via event commands.

**Blackbird sequence** — unique: party is stripped of all equipment, items, and gold. Must navigate the dungeon to recover gear from separate storage rooms. Ayla is uniquely valuable (her fists can't be removed). Guards patrol; stealth-oriented navigation through air ducts.

### 10.7 Camera

**Field / dungeon:** 3/4 top-down oblique perspective (standard SNES RPG view). **Scrolls smoothly** to follow the player (not screen-by-screen). Small rooms fit entirely in the viewport (camera fixed). Scripted sequences can pan the camera independently of the player.

**World map:** zoomed-out scrolling view following the player/Epoch sprite. Wraps horizontally. Character sprites are smaller than in field areas.

**No real perspective changes** — the Jet Bike Race (Mode 7 pseudo-3D) is the only exception. All "angle" variation in other areas is achieved through art direction, not camera transformation.

### 10.8 Music & Audio

**Battle music transition.** When an encounter triggers, area BGM **hard-cuts** to battle theme (not crossfade). After battle, area BGM **restarts from the beginning** (does not resume).

**No victory fanfare** after regular battles — unlike Final Fantasy. A brief results display appears, then area music restarts.

**Battle themes by context:**

| Theme | Used for |
|---|---|
| Battle 1 ("Critical Moment") | most regular encounters |
| Battle 2 ("Burn! Bobonga!") | 65M BC encounters specifically |
| Boss Battle 1 ("A Determination") | most bosses |
| Boss Battle 2 ("The Fierce Battle") | intense late-game bosses (Giga Gaia, Golem Twins) |
| Lavos's Theme | Lavos Shell encounters |
| World Revolution | inside Lavos descent |
| The Final Battle | Lavos Core fight |

**Dramatic silence** used deliberately: after Crono's death, the "future refused to change" game-over, Lucca's flashback, Death Peak moments.

**64 tracks** across the OST (Yasunori Mitsuda primary, Nobuo Uematsu and Noriko Matsueda contributing). Each major location has its own theme; some locations change music at different story points.

### 10.9 Game State & Progression Flags

**Primary storyline counter.** A single byte (address 7F0000) that increments at each major story event. This counter gates: area access, NPC dialogue, shop inventories, available events, world map locations.

Known early values: 00 = Millennial Fair, 06 = Crono wakes, 0F = Marle vanishes into portal, 1C = Queen Leene rescued, 21 = Frog leaves throneroom, etc. — through the entire game.

**Supplementary bit flags** for:
- Treasure chest opened state (per chest, per era for sealed chests)
- Sealed chest inspected-but-not-opened state (for the double-dip trick)
- Trial court points (7 behavioral flags from the fair)
- Character recruitment status
- Key item possession
- Specific event states (Magus recruited vs defeated, Crono alive vs dead, Mt. Woe destroyed, etc.)

**Major state-change checkpoints** (world-altering):
- Cathedral cleared → 600 AD opens up
- Sent to 2300 AD → future era accessible
- End of Time reached → hub unlocked, party management enabled
- Magus defeated → 12,000 BC accessible
- Ocean Palace / Crono's death → massive state change: Blackbird, North Cape, party leader system, Epoch gains flight, sidequests open
- Ozzie's Fort cleared → Medina prices normalize

**New Game+ flag handling:** story counter resets to 00. All progression flags reset. Character levels, techs, equipment, and consumables carry over. Gold resets to 200G. Key items removed and re-granted at their normal story points. Warp-to-Lavos option unlocked early (right Telepod at Fair, End of Time bucket).

### 10.10 Scene Structure

**5 explorable overworld maps** (65M BC, 12,000 BC, 600 AD, 1000 AD, 2300 AD), plus the End of Time hub (3–4 rooms) and 1999 AD (battle stage only).

**Transition model:**
1. **World map** — top-level scrolling overworld. Player sprite (smaller scale) walks between location markers.
2. **Town / area** — entering a location marker triggers a screen fade to a full-scale map.
3. **Interior / room** — entering buildings transitions to interior maps. Dungeons have multiple connected rooms.
4. **Room-to-room** — within a dungeon/town, transitions are either seamless walk-throughs (doorways, stairs) or fade transitions.

**Approximate room counts per era:**

| Era | Rooms (est.) | Notes |
|---|---:|---|
| 65M BC | 15–20 | Ioka, Hunting Range, Forest Maze, Reptite Lair, Dactyl Nest, Tyranno Lair |
| 12,000 BC | 25–30 | Zeal Palace, Kajar, Enhasa, Mt. Woe, Ocean Palace, Blackbird, Last Village, North Cape |
| 600 AD | 40–50 | Guardia Castle, Cathedral, Zenan Bridge, Denadoro, Magus's Castle, Cursed Woods, Northern Ruins, Ozzie's Fort, Giant's Claw |
| 1000 AD | 30–40 | Guardia Castle, Millennial Fair, Truce, Lucca's House, Heckran Cave, Medina, Porre, prison/courtroom |
| 2300 AD | 30–40 | Domes (Bangor/Trann/Arris/Proto/Keeper's), Labs, Factory, Geno Dome, Sewers, Sun Palace, Death Peak |
| End of Time | 3–4 | main hub, Spekkio's room, Epoch dock |
| Black Omen | 15–20 | shared dungeon across 600/1000/2300 AD |
| Lavos interior | 5–10 | battle stages |

Total: ~500 indexed map entries in the ROM (some unused/duplicates).

**Epoch flight + landing.** In flight, Epoch sprite flies freely over the world map. Can land on any traversable ground tile (not water/mountains/buildings). Time travel via Epoch: pressing Y opens a Time Gauge; player selects era with L/R; Epoch transitions to that era's overworld at the same relative position.

**Time gates.** In field areas: shimmering blue portal sprites. On the world map: not directly visible — player enters the location containing the gate. At the End of Time: each discovered gate is a pillar of light (up to 9 pillars unlockable). Gate Key (Lucca's invention) required for natural gates; Epoch bypasses this.

---

## 11. Open Questions / To Verify

Items still needing pinned numbers before we lock data tables:

1. **Per-character stat-growth tables** — gains per level, especially the L60+ attenuation; pulled from Geni's stat-growth FAQ on GameFAQs.
2. **Charm rates per enemy** — Yunalesca's Charm FAQ on GameFAQs is the canonical source.
3. **Spell-resistance tables per enemy** — every enemy's element multiplier vector (0/50/100/200/absorb).
4. **Magic Wall / Black Hole / Dark Mist exact behaviors** — Magic Wall % reduction, Black Hole pull/instakill rules, Dark Mist single-target vs. AoE.
5. **Sealed Chest / Sealed Door item table** — full list of locations and the lesser/greater item pair at each.
6. **Norstein Bekkler prizes per game tier** — exact rewards at 10 / 40 / 80 Silver Point cost levels.
7. **Per-weapon AP verification** — the §6.1 tables draw from cross-checked community guides; final pass should verify against ROM data (Data Crystal / TCRF).
8. **Physical damage formula constants** — the full damage equation (random multiplier range, defense subtraction model, crit multiplier ordering) needs a verified pass against StrategyWiki's Formulae page and DragonKnightZero's Mechanics Guide.
9. **Medina exact price multiplier** — currently listed as ~128×; exact value needs ROM verification.

Resolved since last pass: per-tech TP thresholds and MP costs for all 7 characters are now in [docs/techs.md](docs/techs.md).

---

## 12. References

Canonical sources used to compile and verify this spec. The body has been cross-checked against these for the items called out in §11's "resolved" list; entries still under §11 should be re-checked here before implementation.

### Chrono Wiki (Fandom)
- Game overview: https://chrono.fandom.com/wiki/Chrono_Trigger
- Active Time Battle: https://chrono.fandom.com/wiki/Active_Time_Battle
- Tech / Dual Tech / Triple Tech: https://chrono.fandom.com/wiki/Tech, https://chrono.fandom.com/wiki/Dual_Tech, https://chrono.fandom.com/wiki/Triple_Tech
- List of Techs: https://chrono.fandom.com/wiki/List_of_Techs_in_Chrono_Trigger
- Character pages: https://chrono.fandom.com/wiki/Crono, https://chrono.fandom.com/wiki/Marle, https://chrono.fandom.com/wiki/Lucca, https://chrono.fandom.com/wiki/Robo, https://chrono.fandom.com/wiki/Frog, https://chrono.fandom.com/wiki/Ayla, https://chrono.fandom.com/wiki/Magus
- End of Time: https://chrono.fandom.com/wiki/End_of_Time
- Epoch: https://chrono.fandom.com/wiki/Epoch
- New Game+: https://chrono.fandom.com/wiki/New_Game_Plus
- Endings: https://chrono.fandom.com/wiki/Endings
- Sun Stone, Rainbow Shell, Black Omen, Geno Dome, Ozzie's Fort: dedicated pages on chrono.fandom.com
- Equipment lists: https://chrono.fandom.com/wiki/List_of_Weapons_in_Chrono_Trigger, https://chrono.fandom.com/wiki/List_of_Armors_in_Chrono_Trigger, https://chrono.fandom.com/wiki/List_of_Helmets_in_Chrono_Trigger, https://chrono.fandom.com/wiki/List_of_Accessories_in_Chrono_Trigger, https://chrono.fandom.com/wiki/List_of_Items_in_Chrono_Trigger
- Charm: https://chrono.fandom.com/wiki/Charm
- Shop: https://chrono.fandom.com/wiki/Shop
- Antagonists: https://chrono.fandom.com/wiki/Lavos, https://chrono.fandom.com/wiki/Queen_Zeal, https://chrono.fandom.com/wiki/Schala, https://chrono.fandom.com/wiki/Dalton, https://chrono.fandom.com/wiki/Ozzie, https://chrono.fandom.com/wiki/Gurus_of_Zeal, https://chrono.fandom.com/wiki/Cyrus, https://chrono.fandom.com/wiki/Azala, https://chrono.fandom.com/wiki/Nizbel, https://chrono.fandom.com/wiki/Yakra, https://chrono.fandom.com/wiki/Mother_Brain, https://chrono.fandom.com/wiki/Giga_Gaia, https://chrono.fandom.com/wiki/Lavos_Spawn, https://chrono.fandom.com/wiki/Prophet

### StrategyWiki
- Game hub: https://strategywiki.org/wiki/Chrono_Trigger
- Battle System: https://strategywiki.org/wiki/Chrono_Trigger/Battle_System
- Techs: https://strategywiki.org/wiki/Chrono_Trigger/Techs
- Walkthrough: https://strategywiki.org/wiki/Chrono_Trigger/Walkthrough
- Endings: https://strategywiki.org/wiki/Chrono_Trigger/Endings

### GameFAQs
- Chrono Trigger FAQ index: https://gamefaqs.gamespot.com/snes/563538-chrono-trigger/faqs
- Kao Megura's general FAQ: https://gamefaqs.gamespot.com/snes/563538-chrono-trigger/faqs/8350
- Yunalesca / Andrew Schultz equipment, charm, and shopping FAQs (linked from the index)

### Chrono Compendium
- https://www.chronocompendium.com/Term/Chrono_Trigger.html

### Wikipedia
- https://en.wikipedia.org/wiki/Chrono_Trigger

### Other community references actually consulted in this pass
- gamercorner.net Chrono Trigger guides: https://guides.gamercorner.net/ct/ (status effects, accessory effects, party-member pages including Robo and Ayla)
- Caves of Narshe Chrono Trigger guide: https://www.cavesofnarshe.com/ct/ (Trial guide, character optimization, weapons by class)
- Chrono Trigger Wiki (chronotrigger.wiki.gg): https://chronotrigger.wiki.gg/wiki/Weapons (alternate community wiki, useful for cross-checking Fandom)
- The Cutting Room Floor on Chrono Trigger (SNES): https://tcrf.net/Chrono_Trigger_(SNES) (data dives, debug content)
- Bill Pringle's ending guide: https://billpringle.com/games/ct_end.html
- Thonky's Chrono Trigger walkthrough: https://www.thonky.com/chrono-trigger/
- arrpeegeez Sealed Chest / Sealed Door location guide: https://www.arrpeegeez.com/2024/01/chrono-trigger-walkthrough-sealed-chest.html
