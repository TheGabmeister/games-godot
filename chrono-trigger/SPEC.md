# Chrono Trigger — Godot Recreation Spec

A gameplay-focused recreation of Square's 1995 SNES JRPG *Chrono Trigger* in the Godot engine. This spec is **not** a pixel-perfect or asset-perfect remake; it documents the rules, content, and systems we want to reproduce so the design surface matches the original.

This document deliberately stays at the spec level: features, systems, characters, items, enemies, story structure. No code, no Godot node trees, no implementation choices. Those come later.

---

## 1. Design Goals & Non-Goals

### Goals
- Faithful reproduction of the **Active Time Battle (ATB)** system, including the field-to-battle continuity (no separate battle screen).
- All seven playable characters with their full Single / Dual / Triple Tech rosters.
- Seven playable eras connected by time gates and the Epoch.
- The full main quest with its branching, plus the major sidequests.
- New Game+ with multiple endings tied to when Lavos is defeated.
- An economy and item system rich enough to support meaningful build choices (accessories, charm-only gear, elemental armor).

### Non-Goals
- 1:1 pixel-art reproduction of SNES sprites, tilesets, or animations.
- Reproduction of the original soundtrack (Yasunori Mitsuda's score is not redistributable).
- DS-port-only content in v1 (Lost Sanctum, Dimensional Vortex, Magus dual/triple techs). Treat as stretch goals.
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
- **Escape.** "Run" is continuous and time-based (player holds the run input; an escape value accumulates). Some battles are flagged un-runnable (most bosses, story fights). Enemies can still hit the party while it flees.
- **Counter.** Some enemies counter every attack; some counter only on specific damage types (e.g., Magus's elemental barriers counter mismatched elements). The **Rage Band** and **Frenzy Band** accessories give the wearer a chance to counter when struck. The **Berserker** accessory forces auto-attacks but boosts stats.
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

**Magus has no Dual/Triple Techs in the SNES original** (canon: he doesn't bond with the party). The DS port adds Magus combos; v1 ships SNES-only.

The full canonical tech roster (Singles, Duals, Triples) is enumerated in [docs/techs.md](docs/techs.md) — a separate doc to keep this spec readable.

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

**Ayla has no element**; all her techs are physical. Plain attacks are non-elemental physical, though some weapons add an element to physical hits (e.g., Bolt Sword adds Lightning).

Resistance multipliers run 0% / 50% / 100% / 200%, plus an "absorb" state where a hit heals the target. Some bosses cycle their own elemental absorption mid-fight — most notably **Magus**, whose **Magic Wall** continuously rotates which element he absorbs, forcing the party to read the cue and switch damage types each round.

**Magus's spells** are roughly 30% stronger than the same-name spells cast by Crono / Marle / Lucca, since he is the late-game black-mage recruit.

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

### 2.6 Saving

- **In dungeons / interior maps**: save only at **save point sparkles** (small blue/white twinkles on the floor). Stepping on one and confirming opens the save menu.
- **On the world map**: open the menu and save anywhere.
- **Shelter** consumable: full party HP+MP restore, **usable only on save points**. Single-use, consumed.

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

After clearing the game, NG+ is unlocked from the cleared save. Carried over: levels, equipment, items, gold, learned techs, consumed stat tabs. Reset: story progression, plot key items, the Epoch's time-travel ability.

---

## 6. Items & Equipment

### 6.1 Weapons

Each character uses a unique weapon class. Acquisition: shops for early/mid tiers; chests, drops, Charm, and quest rewards for mid/late.

- **Crono — Katanas.** Notable: **Slasher / Slasher 2** (boosted critical-hit rate), **Rainbow** (ultimate; forged by Melchior from a Sun Stone + 10 Rainbow Shells, or found as a Black Omen chest).
- **Marle — Crossbows / Bowguns.** Ultimate: **Valkerye** (high attack, anti-dragon bonus).
- **Lucca — Guns.** Ultimate: **Wondershot** (Sun Stone forging). Damage is a multiplier rolled on the **last digit of the in-game seconds counter** — possible rolls are ×1/10, ×1/2, ×1, ×2, ×3 of the calculated base. Highly variable, so it's a "swing" weapon.
- **Robo — Mechanical arms.** Ultimate: **Crisis Arm** (Geno Dome). Damage is tied to the **last digit of Robo's current HP**: the calculated attack value is multiplied by the digit (HP ending in 9 hits hardest; HP ending in 0 deals nothing). Players manipulate Robo's HP to land a 9 before swinging. Also notable: **Terra Arm**.
- **Frog — Broadswords.** Ultimate: **Masamune (upgraded)**, achieved by reforging via the Sun Stone after the Cyrus's Grave sidequest at Northern Ruins. Alternate: **Brave Sword**.
- **Ayla — Fists (locked).** Ayla's "weapon" cannot be equipped or unequipped. Her fists upgrade automatically by **level brackets**:

  | Levels | Fist tier | Notes |
  |---|---|---|
  | 1–23 | Fist | base |
  | 24–47 | Fist (T2) | higher crit rate |
  | 48–71 | Fist (T3) | higher crit rate |
  | 72–95 | Iron Fist | crits can inflict **Chaos** status |
  | 96–99 | Bronze Fist | low crit rate, but **crits deal 9999 damage** |

  The fists remain equipped even during the Blackbird sequence (where everyone else is stripped of gear). Ayla is the only character who never has an open weapon slot.
- **Magus — Scythes.** Ultimate: **Doomsickle (Doom Scythe)** at Northern Ruins. Damage is **multiplied by 1 + (number of fallen allies)**: full party = base damage; one ally KO'd = 2× damage; two allies KO'd = 3× damage. A "last man standing" weapon.

**Critical hit specialty.** Slasher/Slasher 2 (Crono), Bronze Fist (Ayla), and weapon-specific crit boosts on the Hero Medal (Frog/Masamune) define the crit-build path.

### 6.2 Armor & Helms

Universal across all characters; no class restriction. Tiers run from cloth (Hide Tunic) through metal (Iron / Gold / Lode / Aeon) to high-magic (Mist Robe, Lumin Robe, Zodiac Cape, Nova Armor, Moon Armor).

Notable:
- **Elemental resistance set** — White / Black / Blue / Red Vest → upgraded to White / Black / Blue / Red Mail. Each color covers one element: White = Lightning, Black = Shadow, Blue = Water, Red = Fire. The Mail tier fully nullifies its element.
- **Ruby Vest** — halves Fire (chest, Heckran's Cave / Lucca's mom sidequest).
- **Taban Vest / Suit / Helm** — given by Lucca's father at story milestones.
- **Prism Dress / Prism Helm** — forged from Rainbow Shell; halve **all** elemental damage. Top-tier.
- **Haste Helm** — auto-Haste at battle start (Black Omen drop/Charm).
- **Ozzie Pants** — joke item dropped from Ozzie; large defense vs. specific enemy types.

### 6.3 Accessories

One slot per character. Major axis of build variety. Grouped by effect:

**Stat boosts.** Power Ring, Power Glove, Power Scarf (Power+); Magic Ring, Magic Scarf (Magic+); Silver Earring / Gold Earring (Max HP+); Silver Stud / Gold Stud (MP cost reduction — Gold Stud reduces to 1/4 cost; Charm-only from Rubble in Black Omen); Hit Ring (Hit+); Defender (Defense+).

**Status / immunity.** Wall Ring (magic defense), Ribbon (Speed+ and minor protections), Bandana (Speed+; early shop), Third Eye (evasion), Vigil's Hat (status protection), Charm Top (boosts Ayla's Charm rate), **Amulet** (Magus's; status immunity + magic defense; he joins with it equipped).

**Auto-cast / on-event.** Berserker (forces auto-attack but boosts stats — loses control), Rage Band / Frenzy Band (counter-attack chance), **Greendream** (auto-revive once when KO'd; Fiona's Forest reward), **Hero Medal** (boosts Masamune crit rate when on Frog), **Robo's Ribbon** (Robo's signature; Geno Dome reward).

**Utility / movement.** Dash Ring (doubles overworld movement speed), Speed Belt (Speed+ in battle — one of the best accessories), Wallet (more G per battle).

**Damage modifiers.**
- **Prism Specs** — **+50% damage dealt** (applies to both physical attacks and techs). Found in the Guardia Castle treasure room after the King's Trial sidequest. One of the strongest accessories in the game.
- **Sun Shades** — **+25% physical damage dealt, +50% magical damage dealt**. Acquired via the Sun Stone quest chain.

Both accessories *increase* damage; neither halves anything. The two stack with party damage buffs (e.g., Haste's effective DPS multiplier from extra turns).

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
- **The Trial verdict (1000 AD).** Effectively a minigame in that earlier behavior is graded; see §5.1 beat 3.

---

## 8. Economy

- **Currency:** G (Gold). Single currency.
- **Shops by era:** Truce, Porre, Choras, Medina, Bekkler's Carnival (1000 AD); Truce / Dorino / Porre / Choras / Medina (600 AD); Trann / Arris / Proto / Keeper's Domes (2300 AD); Enhasa / Kajar / Zeal Palace / Algetty / Last Village (12,000 BC); Ioka Trading Hut (65M BC, trades petals/fangs/horns/feathers).
- **Medina dynamic pricing:** In 1000 AD, Medina shopkeepers initially mark up prices ~170× against humans. After story beats (defeating Magus, the Jerky sidequest changing Porre's culture) the **Trading Post** opens with dramatically lower prices.
- **Bekkler's Carnival:** Silver Points (not G) buy Crono's Clone, Poyozo Doll, Power Tab, etc.
- **Gear acquisition tiers:**
  - *G-only (shop):* tonics, basic weapons, early helms, Bandana, Power/Magic Ring, Shelter, Heal, Revive, basic armor.
  - *Chest-only:* most mid/late weapons, Speed Belt, Defender, Wall Ring.
  - *Charm-only:* Gold Stud, Megalixir, Sun Shades, top-tier elemental Plate, several Tabs.
  - *Quest-reward only:* Greendream, Hero Medal, Robo's Ribbon, Prism Specs, Sun Stone, upgraded Masamune, Wondershot, Rainbow.
- **Income inflation:** the Wallet accessory boosts G per battle; Black Omen enemies are the canonical farming spot; selling charmed petal/fang/horn/feather stacks is the standard infinite-G loop.

---

## 9. Bestiary

Enemies are organized by era. Most enemies have a typical elemental weakness reflecting their habitat. Each enemy entry will eventually carry: HP, stats, drop item, charm item, charm rate, weakness/resist table.

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

### 9.7 Major Antagonists & Significant NPCs
- **Lavos** — parasitic alien, the true final boss.
- **Queen Zeal** — corrupted ruler of Zeal; sacrifices Schala.
- **Schala Zeal** — Janus's sister; emotional spine of the late game.
- **Dalton** — Zealian aristocrat-general; commandeers the Epoch.
- **Ozzie / Flea / Slash** — Magus's three Mystic generals.
- **King Guardia (XXI in 600 AD, XXXIII in 1000 AD)** — Marle's ancestor / father.
- **The Three Gurus** — Melchior (Life; smith in 1000 AD), Belthasar (Reason; builds the Epoch in 2300 AD), Gaspar (Time; runs the End of Time).
- **Cyrus** — Frog's mentor; ghost at Northern Ruins.
- **Glenn** — Cyrus's young squire, transformed into Frog.
- **Azala** — Reptite queen.
- **Nizbel / Nizbel II** — armored Reptite minibosses.
- **Yakra / Yakra XIII** — Mystic monsters impersonating Chancellors across eras.
- **Mother Brain** — rogue AI in Geno Dome.
- **Giga Gaia** — three-part boss atop Mt. Woe.
- **Lavos Spawn** — Lavos's offspring; recurring miniboss.
- **The Prophet** — Magus in disguise in 12,000 BC.

---

## 10. Open Questions / To Verify

Items still needing pinned numbers before we lock data tables:

1. **Per-tech TP thresholds for non-Crono characters** — Crono's are documented in §4 (Cyclone 5 / Slash 90 / Spincut 160 / Life 400 / Lightning 2 500 / Confuse 800 / Luminaire 1000). Other characters' thresholds need a pass against Chrono Wiki / StrategyWiki.
2. **Per-tech MP costs** — partial table exists for Crono; full per-character table needed.
3. **Per-character stat-growth tables** — gains per level, especially the L60+ attenuation; pulled from Geni's stat-growth FAQ on GameFAQs.
4. **Charm rates per enemy** — Yunalesca's Charm FAQ on GameFAQs is the canonical source.
5. **Medina / Trading Post price multipliers** — exact pre- and post-Jerky values per item.
6. **Spell-resistance tables per enemy** — every enemy's element multiplier vector (0/50/100/200/absorb).
7. **Magic Wall / Black Hole / Dark Mist exact behaviors** — Magic Wall % reduction, Black Hole pull/instakill rules, Dark Mist single-target vs. AoE.
8. **Sealed Chest / Sealed Door item table** — full list of locations and the lesser/greater item pair at each.
9. **Norstein Bekkler prizes per game tier** — exact rewards at 10 / 40 / 80 Silver Point cost levels.

These should be filled in as we build out per-system data tables. Resolved items previously listed here (Crono tech order; Wonder Shot / Crisis Arm / Doomsickle formulas; Sun Shades vs. Prism Specs effects; Ayla's weapon-slot lock; Sun Stone questline ownership; ending #13 identity) are now baked into the body of this spec.

---

## 11. References

Canonical sources used to compile and verify this spec. The body has been cross-checked against these for the items called out in §10's "resolved" list; entries still under §10 should be re-checked here before implementation.

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
