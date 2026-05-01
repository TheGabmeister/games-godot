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
- **Battle rewards.** Each victory awards EXP, G (gold), and Tech Points (TP). EXP and TP go only to surviving members of the active party of three — benched characters earn nothing, which is the central reason era-swap rotation matters.

### 2.2 Tech System

Techs are character abilities that cost MP. They are organized in three tiers.

**Single Techs** — 8 per character, learned in fixed order by accumulating Tech Points (TP) past per-tech thresholds. Magus joins with all his Single Techs already learned.

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

Four elements:
- **Lightning** — Crono, Magus.
- **Fire** — Lucca, Magus.
- **Water/Ice** — Marle, Frog, Magus. (Water and Ice are the same element internally.)
- **Shadow** — Robo, Magus.

**Ayla has no element**; all her techs are physical. Plain attacks and most weapons are non-elemental physical.

Resistance multipliers are typical 0% / 50% / 100% / 200%, plus an "absorb" state where a hit heals the target. Some bosses (notably Magus) cycle their own elemental absorption mid-fight, forcing the party to switch damage types.

**Spekkio**, the Master of War at the End of Time, "awakens" magic for Crono, Marle, Lucca, and Frog the first time the party visits. Without that awakening, magical Single Techs are unavailable. Robo, Ayla, and Magus do not need Spekkio.

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

---

## 4. Playable Characters

Seven recruitable characters. Each has a unique weapon class, element, and tech style.

### Crono
- **Era:** 1000 AD. **Weapon:** Katana. **Element:** Lightning.
- **Role:** Balanced physical attacker with strong AoE; de-facto party leader.
- **Signature techs:** Cyclone, Slash, Lightning, Spincut, Lightning 2, Confuse, Luminaire.
- **Recruited:** Game start (Millennial Fair).
- **Note:** Silent protagonist. Forced into the party until his death event at the Ocean Palace; optional thereafter.

### Marle (Princess Nadia)
- **Era:** 1000 AD. **Weapon:** Crossbow. **Element:** Water/Ice.
- **Role:** Primary healer, ice mage, ranged physical.
- **Signature techs:** Aura, Provoke, Ice, Cure, Haste, Ice 2, Cure 2, Life 2.
- **Recruited:** Millennial Fair (immediate); rejoins permanently after the Manolia Cathedral rescue.

### Lucca Ashtear
- **Era:** 1000 AD. **Weapon:** Gun. **Element:** Fire.
- **Role:** Fire mage, status/utility caster, secondary item healer.
- **Signature techs:** Flame Toss, Hypno Wave, Fire, Napalm, Protect, Fire 2, Mega Bomb, Flare.
- **Recruited:** Millennial Fair (Telepod demonstration); joins permanently after Marle's disappearance.

### Robo (Prometheus / R-66Y)
- **Era:** 2300 AD. **Weapon:** Mechanical arm. **Element:** Shadow.
- **Role:** Tank / sustain — high HP/defense, party-wide healing via Heal Beam.
- **Signature techs:** Rocket Punch, Cure Beam, Laser Spin, Robo Tackle, Heal Beam, Area Bomb, Shock, Uzzi Punch.
- **Recruited:** 2300 AD, Proto Dome, repaired by Lucca.

### Frog (Glenn)
- **Era:** 600 AD. **Weapon:** Broadsword/Katana (Masamune is his ultimate). **Element:** Water.
- **Role:** Well-rounded physical attacker with healing/water magic.
- **Signature techs:** Slurp, Slurp Cut, Water, Heal, Leap Slash, Cure 2, Frog Squash, Water 2.
- **Recruited:** 600 AD, after Tata's Hero Medal sequence; commits permanently after the Masamune is reforged.
- **Personality:** Cursed by Magus into a frog form; honor-bound knight, guilt-ridden over Cyrus's death.

### Ayla
- **Era:** 65,000,000 BC. **Weapon:** Fists (cannot equip ordinary weapons; her hand armor and level scale unarmed strikes). **Element:** None.
- **Role:** Pure physical powerhouse — highest base Power stat. No magic.
- **Signature techs:** Kiss, Roundillo Kick, Cat Attack, Rollo Kick, Boulder Toss, **Charm**, Tail Spin, Triple Kick.
- **Recruited:** 65M BC, Ioka Village, after recovering the stolen Gate Key from the Reptites.
- **Note:** Charm (see §6.5) is one of the most strategically important non-combat abilities in the game.

### Magus (Janus Zeal)
- **Era:** 12,000 BC. **Weapon:** Scythe. **Elements:** All four (Lightning 2, Ice 2, Fire 2, Dark Matter).
- **Role:** Glass-cannon black mage; uniquely covers every element.
- **Signature techs:** Lightning 2, Ice 2, Fire 2, Dark Bomb, Magic Wall, Dark Mist, Black Hole, Dark Matter.
- **Recruited:** Optional. After the Ocean Palace catastrophe, the party can spare him at North Cape.
- **Note:** No Dual/Triple Techs in the SNES original.

---

## 5. Story & Sidequests

### 5.1 Main Story Beats (in order)

1. **Millennial Fair (1000 AD)** — Crono meets Marle; Lucca's Telepod resonates with Marle's pendant and warps her through a time gate.
2. **Rescue in 600 AD** — The party retrieves Marle, who has been mistaken for her ancestor Queen Leene. They free the real Leene from Manolia Cathedral (boss: Yakra), correcting history.
3. **Trial of Crono (1000 AD)** — Trial for "kidnapping." Regardless of verdict, the Chancellor orders execution; the party escapes through a forest gate to 2300 AD.
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

Each character (except Crono and Magus in v1) has an associated optional quest, typically rewarding a stat-boosting personal item or that character's ultimate weapon.

- **Frog — Cyrus's Grave / Masamune upgrade.** Northern Cape; reforge with Sun Stone + Rainbow Shell at Melchior.
- **Robo — Fiona's Forest.** Robo stays behind 400 years to replant a desert in 600 AD; in 1000 AD a forest exists. Reward: **Greendream** (auto-revive).
- **Lucca — Mother's Fate.** A late-game gate lets Lucca save her mother Lara from the conveyor belt accident.
- **Marle — Rainbow Shell trial.** Retrieve the Rainbow Shell from Giant's Claw (1000 AD); use it as evidence in King Guardia's trial. Reward: **Prism Dress / Prism Helm / Prism Specs** crafted by Melchior.
- **Ayla — Sun Stone.** Place the dim Sun Stone in Sun Keep in 65M BC; retrieve fully charged in 1000 AD. Powers Wondershot (Lucca), Valkerye (Marle), and the Rainbow forging chain.
- **Crono — Death Peak (revival).** Required if the player wants Crono back. Skipping it is a major route to alternate endings.
- **Geno Dome (Robo).** Mother Brain plot in 2300 AD. Reward: **Crisis Arm** (Robo's ultimate), Terra Arm, Megaelixir.
- **Ozzie's Fort (600 AD).** Optional cleanup of Magus's lieutenants.
- **Sunken Desert (600 AD).** Fiona's Forest prerequisite; boss: Retinite.
- **Northern Ruins / Cyrus's Spirit.** Multi-era dungeon repaired by sending Tools to the carpenter in Choras. Frog's strongest gear path.
- **Black Omen.** Optional megadungeon (boss gauntlet ending in Queen Zeal). Defeating it removes it from the world map of every era.

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
12. **A Slide Show** — Post-revival, sidequests incomplete; ending is still images.
13. **A Professor's Confession** — Lucca-focused variant.

(DS port adds **Developers' Office** and **Dream's End**. Out of scope for v1.)

### 5.4 New Game+

After clearing the game, NG+ is unlocked from the cleared save. Carried over: levels, equipment, items, gold, learned techs, consumed stat tabs. Reset: story progression, plot key items, the Epoch's time-travel ability.

---

## 6. Items & Equipment

### 6.1 Weapons

Each character uses a unique weapon class:

- **Crono** — Katanas. Notable: **Slasher / Slasher 2** (high crit), **Rainbow** (ultimate; built from Sun Stone + Rainbow Shells, or chest in Black Omen).
- **Marle** — Crossbows / Bowguns. Ultimate: **Valkerye** (anti-dragon).
- **Lucca** — Guns. Notable: **Wonder Shot** (random damage, unique formula), **Megablast**.
- **Robo** — Mechanical arms. Notable: **Crisis Arm** (damage tied to ones digit of current HP — HP ending in 9 deals up to 9999, ending in 1 deals 1), **Terra Arm**.
- **Frog** — Broadswords. Ultimate: **Masamune (upgraded)** via Sun Stone / Cyrus's grave; alternate **Brave Sword**.
- **Ayla** — Fists only. Cannot equip ordinary weapons; her unarmed damage scales with level and her accessory.
- **Magus** — Scythes. Ultimate: **Doomsickle** (scales with number of fallen party members; Northern Ruins).

Acquisition: shops for early/mid tiers; chests, drops, Charm, and quest rewards for mid/late tiers.

> **Open question for implementation:** Wonder Shot's exact damage formula, Crisis Arm's HP-digit table, and Doomsickle's scaling formula need verification against the live Chrono Wiki numbers before we hard-code them.

### 6.2 Armor & Helms

Universal across all characters; no class restriction. Tiers run from cloth (Hide Tunic) through metal (Iron / Gold / Lode / Aeon) to high-magic (Mist Robe, Lumin Robe, Zodiac Cape, Nova Armor, Moon Armor).

Notable:
- **Elemental resistance set** — White / Black / Blue / Red Vest → upgraded to White / Black / Blue / Red Mail; each line covers one element (Light/Shadow/Water/Fire), with the Mail tier fully nullifying.
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

**Damage modifiers.** **Prism Specs** (effect: damage modifier on physical hits; chest in Guardia Castle treasure room post-trial). **Sun Shades** (paired item from the Sun Stone quest).

> **Open question for implementation:** Sun Shades vs. Prism Specs exact effect text differs across sources/translations (one halves damage taken, the other doubles damage dealt — or vice versa). Verify against the Chrono Wiki canonical pages before locking in numbers.

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

## 7. Economy

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

## 8. Bestiary

Enemies are organized by era. Most enemies have a typical elemental weakness reflecting their habitat. Each enemy entry will eventually carry: HP, stats, drop item, charm item, charm rate, weakness/resist table.

### 8.1 65,000,000 BC — Dinosaurs & Reptites
Reptite warriors and mages, raptors (Kilwala, Terrasaur, Megasaur), pterosaurs (Avian Rex), giant insects, Roundillo / Rolypoly. Many lightning-weak. **Bosses:** Nizbel, Nizbel II, Black Tyranno, Azala.

### 8.2 12,000 BC — Antiquity / Magical Beasts
Mages, Blue Imps, Jinn, Bantam Imps, mermen, undead near Mt. Woe. **Bosses:** Golem, Golem Twins, Giga Gaia, Mud Imp, Lavos Spawn, Queen Zeal, Mammon Machine.

### 8.3 600 AD — Mystics & Medieval Beasts
Mystic imps and goblins, henches, knights, Hench slimes, undead in Cursed Woods, naga-ettes, ogan-types in Magus's Castle. **Bosses:** Yakra, Zombor, Masa & Mune, Ozzie, Flea, Slash, Magus, Retinite, Rust Tyranno.

### 8.4 1000 AD — Wildlife & Mystic Remnants
Mostly wildlife (naga-ettes, blue imps, gnashers, jinn bottles, kilwalas) since the world is at peace; surviving Mystics in Medina. **Bosses:** Heckran, Dragon Tank, Yakra XIII, Rust Tyranno (resurrected).

### 8.5 2300 AD — Robots & Mutants
Proto-2/3/4 robots, Bugger, Acid/Alkaline pairs, Departed/Decedent (irradiated humans), Debugger, Krawlie, Lasher, Tubster. Mostly Shadow / Fire weak. **Bosses:** R-Series, Guardian + Bits, Mother Brain + Displays, Atropos XR, Son of Sun.

### 8.6 Black Omen / Lavos
A best-of gauntlet drawing from every era plus unique enemies (Mega Mutant, Giga Mutant, Terra Mutant, Lavos Spawn, Side-Kick, Cybot, Tubster). Final fights: Queen Zeal → Mammon Machine → Lavos shell → inner shell → Lavos Core (left Bit / right Bit / center body — only the center body counts).

### 8.7 Major Antagonists & Significant NPCs
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

## 9. Open Questions / To Verify

These are flagged here so we don't lock in wrong numbers later:

1. **Per-tech TP thresholds** — commonly cited as roughly 10 / 50 / 100 / 200 / 400 / 800 / 1500 / 2500, but exact values vary per character and need pinning against Chrono Wiki.
2. **Per-tech MP costs** — likewise need a verified table.
3. **Per-character growth tables** — stat gains per level, especially the L60+ attenuation.
4. **Wonder Shot, Crisis Arm, Doomsickle damage formulas.**
5. **Sun Shades vs. Prism Specs effect wording** — sources disagree; verify on the live wiki.
6. **Charm rates per enemy** — Yunalesca's Charm FAQ on GameFAQs is the canonical source.
7. **Medina / Trading Post price multipliers** — exact pre/post-Jerky values.
8. **Endings 12 and 13** — minor variants of "A Slide Show"; some sources count them as one.
9. **Ayla's weapon slot** — confirm whether the SNES original allows any equippable weapons or whether the slot is fully locked.

These should be filled in as we build out per-system data tables.

---

## 10. References

Canonical sources used to compile this spec. (Note: the research agents that produced the underlying notes for this document had their direct web access blocked in our build sandbox, so the URLs below are recommended verification targets rather than live-fetched citations. Verify exact numbers against these pages before implementation.)

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
