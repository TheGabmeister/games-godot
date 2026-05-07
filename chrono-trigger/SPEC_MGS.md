# Metal Gear Solid — Gameplay Systems Spec

Metal Gear Solid, PlayStation 1, 1998 (Konami / Kojima Productions).

---

## 1. Core Gameplay Systems

### 1.1 Stealth Model

Top-down 2D stealth with three detection channels: **sight**, **sound**, and **environmental traces**.

**Sight detection:**
- Guards have a cone-shaped field of vision displayed on the Soliton Radar as colored triangles extending from each enemy dot.
- Detection is instant if Snake enters a guard's vision cone.
- Guards cannot see Snake when he is crawling under objects, inside a cardboard box (unless inspected), flattened against a wall outside their cone, or behind cover.
- Surveillance cameras have their own vision cones and trigger Alert on detection. Destroyed with Stinger, Nikita, or C4. Temporarily disabled with Chaff Grenades (~10 seconds).
- Infrared laser tripwires are invisible without Thermal Goggles or Cigarette smoke. Breaking a beam triggers Alert.
- Gun cameras detect and fire automatically. Disabled by Chaff Grenades. Destroyed with explosives or sustained gunfire.

**Sound detection:**
- Running is louder than walking. Walking through water puddles is especially noisy.
- Gunfire and explosions near guards trigger immediate Alert.
- Guards hear wall-knocking (press Square while wall-pressing) — core distraction mechanic.
- Difficulty scales hearing: Easy = poor; Normal/Hard = normal; Extreme = extremely sensitive.

**Environmental traces:**
- Snow footprints are visible and guards follow them ("Whose footprints are these?"). Footprints fade over time.
- Blood trails from wounds alert guards. Bandage stops bleeding.
- Sneezing (from catching a cold in prolonged cold exposure) alerts nearby guards. Cured by Cold Medicine.

### 1.2 Alert System

Three phases. MGS1 does not have a distinct "Caution" phase (added in MGS2).

| Phase | Radar State | Timer | Enemy Behavior |
|---|---|---|---|
| **Infiltration** (Normal) | Active | None | Guards patrol set routes. Investigate suspicious sounds ("?" indicator, cone turns red on radar). Return to patrol if nothing found. |
| **Alert** | Jammed | Countdown from **99.99s**; resets if Snake re-spotted | "!" indicator + iconic alert sting. Enemies converge on Snake, call reinforcements. Reinforcement waves of 3 soldiers (SPAS-12 shotguns). Music changes to alert BGM. Elevators lock. |
| **Evasion** | Jammed | Second countdown | Guards break patrol routes, actively search hiding spots (under desks, in lockers, behind objects). If Snake re-spotted, returns to Alert. When timer expires, returns to Infiltration. |

Entering a new room/area can clear evasion status more quickly. Killing/neutralizing a guard before they complete their radio call to HQ prevents Alert from triggering.

### 1.3 Combat

**Third-person shooting (primary):** Hold Square to draw/aim. Snake aims in facing direction. Release to fire. Soft auto-aim locks onto nearest visible enemy. Cannot fire in first-person view in the original PS1 version (added in Integral). PSG-1 and Stinger automatically use first-person aiming.

**Hand-to-hand combat:**

| Move | Input | Damage |
|---|---|---|
| Punch | Circle | 3–4 |
| Punch-Punch-Kick combo | Circle ×3 | 12–16 total |
| Grab/Choke | Square near enemy (unarmed) | Hold to choke; repeated presses snap neck |
| Throw | Square + direction near enemy | 3–4; knocks unconscious |

### 1.4 Health System

**Life Gauge** — horizontal bar, top of screen. Starts at **256 HP** (Rank 1). Increases after each boss defeat via the Rank system:

| Rank | After Defeating | Max HP |
|---|---|---|
| 1 | (Start) | 256 |
| 2 | Ocelot | 320 |
| 3 | Tank | 384 |
| 4 | Ninja | 448 |
| 5 | Mantis | 512 |
| 6 | Sniper Wolf 1 | 576 |
| 7 | Hind D | 640 |
| 8 | Vulcan Raven 2 | 704 |
| 9 | REX | 768 |

HP restoration after boss defeat varies by difficulty: Easy = full refill; Normal = restore to pre-upgrade max; Hard = only the upgrade amount (+64); Extreme = none.

**Ration auto-use:** If a Ration is the currently equipped item and Snake's HP hits 0, one Ration is automatically consumed for a full heal. If no Ration is equipped — even if Rations exist in inventory — Snake dies. This creates a constant trade-off: equip a Ration as a safety net, or equip Thermal Goggles / Body Armor for tactical advantage.

### 1.5 Movement

| Action | Control | Notes |
|---|---|---|
| Walk/Run | D-pad / Left stick | Running creates audible footsteps |
| Crouch | X | Low profile. Press direction while crouched for quiet sneaking walk |
| Crawl | X from crouch | Prone. Quietest mode. Pass through narrow spaces and vents. Crawl over Claymores to collect them |
| Wall Press | Move against wall | Camera tilts for corner view. Slide along wall, peek corners, knock to lure guards |
| First-Person Look | Triangle | Observation only — cannot shoot (original PS1). PSG-1/Stinger override to scoped view |
| Ladder | Contextual | Automatic on approach |

No ledge-hanging or climbing in the original PS1 version (added in MGS2 and the GameCube remake The Twin Snakes).

**Cardboard Box fast travel:** Equipping a specific Cardboard Box inside the back of a cargo truck causes a guard to drive Snake to the labeled destination: Box A → Heliport, Box B → Nuke Building, Box C → Snowfield.

**Speed note:** Snake moves faster with any weapon equipped vs. barehanded.

### 1.6 Soliton Radar

Located in the upper-right corner of the screen. Top-down map of the immediate area showing walls and room layout. Snake = white dot. Enemies = red dots with vision cone indicators.

| State | Display |
|---|---|
| Infiltration | Fully functional — map, enemies, cones |
| Alert | Jammed — shows "ALERT" + 99.99 countdown |
| Evasion | Jammed — shows "EVASION" + countdown |
| Chaff active | Jammed (trade-off: disables electronics for enemies too) |
| Certain indoor areas | Naturally jammed ("strong harmonic resonance") |

When a guard hears a suspicious sound, their vision cone turns **red** on the radar.

### 1.7 Codec System

Press Select to open the Codec. Adjust frequency with D-pad, press Up to call. Memory Window (Down) quick-dials previously contacted people. Codec **pauses gameplay** — time is frozen during conversations.

| Frequency | Contact | Role |
|---|---|---|
| **140.85** | Colonel Campbell / Naomi Hunter | Mission commander. Primary hints, boss advice, plot exposition. Naomi shares medical intel on same frequency. |
| **140.96** | Mei Ling | **Save game function.** Chinese/Western proverbs on each save. Manages Soliton Radar. |
| **141.52** | Nastasha Romanenko | Weapon-specific intel (context-sensitive on pickup). Nuclear technology expertise. |
| **141.80** | Master Miller | Survival advice. Actually Liquid Snake in disguise — revealed late game. |
| **140.15** | Meryl Silverburgh | Available after certain story events. Frequency found on the back of the physical CD case (fourth-wall break). |
| **141.12** | Otacon | Available after rescuing him. Science/tech guidance, especially during REX fight. |
| **140.48** | Deepthroat | **Incoming calls only** — cannot be dialed. Anonymous tips at key moments. Revealed to be Gray Fox. |

**Hidden frequencies (Integral version):** 140.66 plays classic Metal Gear music depending on area. 140.07 plays Japanese developer commentary.

Contacts provide different dialogue depending on Snake's location, story progress, equipped items, and recent events. Calling at unusual times or repeatedly triggers unique/humorous dialogue.

---

## 2. World Structure

### 2.1 Shadow Moses Island

All gameplay takes place on Shadow Moses Island, a nuclear weapons disposal facility in Alaska's Fox Archipelago. Linear progression through connected areas with limited backtracking (notably for the PAL Key temperature puzzle late game).

### 2.2 Area Progression

| # | Area | Key Events |
|---|---|---|
| 1 | Cargo Dock | Insertion point. Swim, collect Rations underwater, elevator up |
| 2 | Heliport | First surface area. SOCOM in truck. Cameras, guards, searchlights |
| 3 | Tank Hangar 1F | Main infiltration hub. Ventilation ducts. Spy on Meryl exercising |
| 4 | Tank Hangar B1 (Cells) | Meet "DARPA Chief" (Decoy Octopus). He dies of FoxDie |
| 5 | Tank Hangar B2 (Armory) | Multiple keycard-locked rooms. **Boss: Revolver Ocelot.** Baker dies. Gray Fox severs Ocelot's hand |
| 6 | Canyon | Outdoor snow. Claymore minefield. **Boss: M1 Tank** (Vulcan Raven) |
| 7 | Nuke Building 1F | Nuclear warhead storage, ground floor |
| 8 | Nuke Building B1 | Offices, storage. Nikita launcher, Diazepam |
| 9 | Nuke Building B2 | Gas corridor (Gas Mask required). Electrified floor puzzle (Nikita to destroy control panel). Leads to Laboratory |
| 10 | Laboratory | **Boss: Cyborg Ninja** (Gray Fox). Meet Otacon |
| 11 | Nuke Building B1 — Director's Office | Meet Meryl in person. **Boss: Psycho Mantis** |
| 12 | Caves | Natural caves. Wolves (pacified by Handkerchief or scent-marked Box) |
| 13 | Underground Passage | **Boss: Sniper Wolf (1st).** Snake captured after the fight |
| 14 | Medical Room / Cells | Torture sequence. Cell escape (Ketchup trick / Gray Fox / hide under bed) |
| 15 | Communication Tower A | 27 floors of stairwell combat (forced alert). Rope at top |
| 16 | Comm Tower A Exterior | Rappelling sequence — Hind D attacks, steam vents |
| 17 | Comm Tower Bridge | Walkway destroyed by Hind D. Stinger found here |
| 18 | Communication Tower B | **Boss: Hind D** (rooftop). Stealth soldier elevator ambush going down |
| 19 | Snowfield | **Boss: Sniper Wolf (2nd).** Emotional death scene |
| 20 | Blast Furnace | Molten metal, moving crane, platforming. PAL Key heats to red here |
| 21 | Cargo Elevator | Elevator descent. Enemy ambush during ride |
| 22 | Underground Warehouse (Freezer) | **Boss: Vulcan Raven (on foot).** PAL Key freezes to blue here |
| 23 | Underground Base (REX Hangar) | PAL Key terminals. **Boss: Metal Gear REX.** **Boss: Liquid Snake (fistfight)** |
| 24 | Supply Route / Escape Tunnel | Jeep chase. Liquid pursues. FoxDie kills Liquid at tunnel exit |

### 2.3 Area Connections

```
Cargo Dock
  └─ (elevator) → Heliport
                     └─→ Tank Hangar 1F
                           ├─ (stairs) → Tank Hangar B1 (Cells)
                           ├─ (stairs) → Tank Hangar B2 (Armory)
                           └─ (exit north) → Canyon
                                               └─→ Nuke Building 1F
                                                     ├─ (stairs) → Nuke Building B1
                                                     │                ├─→ Director's Office
                                                     │                └─ (stairs) → Nuke Building B2
                                                     │                                └─→ Laboratory
                                                     └─→ Caves
                                                           └─→ Underground Passage
                                                                 └─→ (capture) → Medical Room / Cells
                                                                       └─→ Comm Tower A
                                                                             └─→ (rappel) → Bridge
                                                                                   └─→ Comm Tower B
                                                                                         └─→ Snowfield
                                                                                               └─→ Blast Furnace
                                                                                                     └─→ Cargo Elevator
                                                                                                           └─→ Warehouse (Freezer)
                                                                                                                 └─→ REX Hangar
                                                                                                                       └─→ Escape Tunnel
```

The PAL Key puzzle requires backtracking between the Warehouse (cold → blue key), the Blast Furnace (hot → red key), and the REX Hangar control room. The key can revert if carried through the wrong temperature zone.

---

## 3. Playable Characters

### Solid Snake (David)

The sole playable character. No RPG stats — MGS is an action-stealth game. Snake has a Life Gauge and an O2 gauge (underwater/gas areas).

**Abilities:** Walk, run, crouch, crawl, wall-press, peek corners, knock on walls, first-person look, codec, punch-punch-kick combo, grab/choke/throw, fire weapons, equip items.

**No other playable characters** in the main story. VR Training missions are also played as Snake (VR Missions expansion adds a Ninja-playable mode).

---

## 4. Story & Progression

### 4.1 Setup

The year is 2005. Shadow Moses Island has been seized by renegade FOXHOUND special forces and Genome Soldiers. They threaten nuclear launch via Metal Gear REX unless the U.S. delivers Big Boss's remains and $1 billion within 24 hours.

**FOXHOUND members leading the revolt:** Liquid Snake (commander), Revolver Ocelot, Psycho Mantis, Sniper Wolf, Vulcan Raven, Decoy Octopus.

### 4.2 Main Story Beats

1. **Briefing & Insertion** — Colonel Campbell briefs Snake. Rescue two hostages (DARPA Chief Donald Anderson, ArmsTech President Kenneth Baker), determine if the terrorists can launch, neutralize the threat. Snake infiltrates via submarine.
2. **DARPA Chief** — Snake finds Anderson in the cells. Anderson reveals REX needs two PAL codes; he already gave his under torture. Anderson dies of apparent heart attack (actually FoxDie killing Decoy Octopus in disguise).
3. **Revolver Ocelot** — Baker is wired with C4. Ocelot duels Snake. Gray Fox appears and severs Ocelot's hand. Baker gives Snake a PAL key and optical disc, then dies (FoxDie).
4. **Deepthroat** — Anonymous codec calls warn Snake of traps (later revealed: Gray Fox).
5. **Meryl Contact** — Snake contacts Meryl via codec (140.15 — on the back of the real game's CD case).
6. **M1 Tank** — Vulcan Raven commands a tank in the canyon. Snake destroys it with grenades and chaff.
7. **Nuke Building** — Gas corridors, electrified floors. Snake uses Nikita missiles to destroy a control panel.
8. **Cyborg Ninja** — Gray Fox attacks in the laboratory. Hand-to-hand fight. Gray Fox revealed as Frank Jaeger, Snake's former comrade.
9. **Otacon** — Dr. Hal Emmerich, REX's designer, didn't know it was a nuclear launch platform. Agrees to help Snake.
10. **Psycho Mantis** — Possesses Meryl. Fourth-wall boss fight (memory card reading, controller port 2 trick, HIDEO blackout). Opens hidden passage before dying.
11. **Sniper Wolf (1st)** — Shoots Meryl. Snake sniper-duels Wolf with the PSG-1. Snake is captured afterward.
12. **Torture** — Ocelot's electric torture rack. Resist (mash Circle) → Meryl lives. Submit (press Select) → Meryl dies. No continues if HP reaches zero. Turbo controllers detected.
13. **Cell Escape** — Ketchup trick (fake blood), or wait for Gray Fox to break the door, or hide under the bed.
14. **Communication Towers** — 27-floor stairwell combat. Rappelling down exterior. Hind D destroys the connecting bridge.
15. **Hind D** — Liquid's helicopter. Stinger-only fight on Comm Tower B rooftop.
16. **Sniper Wolf (2nd)** — Snowfield duel. Wolf's death scene.
17. **Vulcan Raven (2nd)** — Freezer warehouse. Raven reveals the "DARPA Chief" was Decoy Octopus. Ravens consume his body.
18. **PAL Key Sequence** — Three terminals: room-temp key (yellow), frozen key (blue), heated key (red). Snake believes he's deactivating REX.
19. **Liquid's Revelation** — "Master Miller" reveals himself as Liquid Snake. The real Miller is dead. Snake unknowingly activated REX, not deactivated it. Snake carries FoxDie. Snake and Liquid are Big Boss clones (Les Enfants Terribles).
20. **Metal Gear REX** — Two-phase Stinger fight. Gray Fox sacrifices himself to destroy the radome.
21. **Liquid Fistfight** — Hand-to-hand atop REX wreckage. 2.5-minute time limit.
22. **Escape** — Jeep chase with Meryl or Otacon driving. Liquid pursues, then dies from FoxDie at the tunnel exit.
23. **Epilogue** — Campbell fakes Snake's death. Post-credits: Ocelot calls the U.S. President (Solidus Snake, a third clone), confirming he was a government double agent. He has REX's specifications.

### 4.3 Branching & Endings

The torture sequence is the sole branching point.

**Meryl ending (resist all torture):** Meryl survives. Snake escapes with Meryl. He reveals his real name ("David"). They ride off on a snowmobile. **Unlock: Bandana** (infinite ammo). This is the **canon** ending (confirmed by MGS2 and MGS4).

**Otacon ending (submit during any torture round):** Meryl dies during captivity. Snake escapes with Otacon. **Unlock: Stealth Camouflage** (invisibility to most enemies).

### 4.4 New Game+

| Unlock | Condition | Effect |
|---|---|---|
| Bandana | Complete with Meryl ending | Infinite ammo, no reloading |
| Stealth Camouflage | Complete with Otacon ending | Invisible to most guards/cameras (not bosses) |
| Tuxedo | Obtain both endings (complete twice) | Cosmetic — Snake wears a tuxedo |

Special items are available from the start of subsequent playthroughs. Usable without penalty for ranking purposes.

### 4.5 Fourth-Wall Breaks & Easter Eggs

- **Psycho Mantis memory card reading** — scans PS1 memory card for Konami saves (Castlevania: SotN, Suikoden, Azure Dreams, Vandal Hearts, Policenauts). Comments on play style from MGS save data.
- **DualShock vibration** — Mantis "moves" the controller with psychic powers.
- **HIDEO blackout** — screen displays "HIDEO" mimicking a TV channel switch.
- **Controller Port 2** — must switch controller to Port 2 to bypass Mantis's input reading.
- **Meryl's codec frequency** — "It's on the back of the CD case" refers to the actual physical game packaging.
- **Ghost photos** — 42–43 developer "ghost" images hidden throughout the game, photographable with the Camera item.
- **Johnny Sasaki** — recurring joke guard with chronic diarrhea.
- **Ocelot's torture warning** — "There are no continues, my friend" (addressing the player).
- **Campbell's "turn off the console"** — directly addresses the player.
- **Women's bathroom reactions** — unique codec dialogue from all contacts if Snake enters the women's bathroom.
- **Cigarette health lecture** — Naomi and Mei Ling lecture Snake about smoking; Nastasha (a smoker) does not.

---

## 5. Items & Equipment

### 5.1 Equipment System

Two separate menus:
- **R2 (hold):** Weapon menu. D-pad to select. Release to equip. "NO WEAPON" to holster.
- **L2 (hold):** Item menu. D-pad to select. Release to equip. "NO ITEM" to unequip.
- **R1/L1 (tap):** Quick-cycle to previously equipped weapon/item.

One weapon and one item equipped at a time. HUD shows weapon (top-right) and item (top-left) with ammo/quantity. Max ammo capacity increases after each boss defeat (Rank system).

### 5.2 Weapons

| Weapon | Type | Mag/Pickup | Location | Notes |
|---|---|---|---|---|
| SOCOM | Pistol (.45) | 12/12 | Heliport truck or Tank Hangar | Suppressor attachment (permanent, no durability). Soft auto-aim |
| FAMAS | Assault rifle | 25/25 | Armory B2 (Level 2 card) | Full auto. Effective for crowd control |
| PSG-1 | Sniper rifle | 5/5 | Armory B2 (Level 5 card) | First-person scope. Sway steadied by Diazepam. Required for Sniper Wolf fights |
| Nikita | RC missile launcher | 4/4 | Nuke Building B1 (Level 3 card) | First-person missile-cam. Steer with D-pad. Used for around-corner kills and the electrified floor puzzle |
| Stinger | Lock-on missile launcher | 5/5 | Comm Tower Bridge | First-person lock-on (reticle turns red + beep). Required for Hind D and REX |
| C4 | Plastic explosive | 2/— | Armory B2 (Level 1 card) | Place and remote detonate. Destroys walls (reveals hidden rooms) |
| Claymore | Directional mine | 1/— | Canyon (crawl to collect) | Invisible once placed. Triggered by enemy proximity. Mine Detector to see |
| Grenade | Frag grenade | 4/— | Armory, Valley, Snowfield | Arc throw. Hold to cook fuse |
| Chaff Grenade | EMP grenade | 3/— | Heliport, Tank Hangar, Valley | Disables all electronics ~10s (cameras, gun cameras, IR sensors, REX homing). Also jams Snake's radar |
| Stun Grenade | Flashbang | 3/— | Heliport, Armory, Snowfield | Stuns all enemies in area for several seconds |

**Ammo capacity progression (Normal difficulty, partial):**

| Rank | SOCOM | FAMAS | Grenade | Rations |
|---|---|---|---|---|
| 1 (Start) | 25 | — | — | 1–2 |
| 2 (post-Ocelot) | 49 | — | 12 | 2 |
| 3 (post-Tank) | 73 | 101 | 16 | 3 |
| 4 (post-Ninja) | 97 | 151 | 20 | 3 |
| 5 (post-Mantis) | 121 | 201 | 24 | 4 |
| 6 (post-Wolf 1) | 145 | 251 | 28 | 4 |
| 7 (post-Hind) | — | 301 | — | 5 |
| 8 (post-Raven 2) | — | 351 | 32 | 5 |

### 5.3 Items

| Item | Effect |
|---|---|
| Ration | Full heal. Auto-consumed at 0 HP if equipped (see §1.4). Can freeze in cold areas — must thaw before use. Max: 5 (Easy/Normal), 2 (Hard/Extreme) |
| Suppressor | Permanently silences SOCOM. Auto-attaches when both are in inventory. No durability (durability added in MGS3). Tank Hangar 1F (Level 2 card) |
| Thermal Goggles | Reveals IR laser beams, Claymores, stealth-camo enemies, heat signatures. Location depends on SOCOM pickup order |
| Night Vision Goggles | Amplifies light in dark areas. Nuke Building B1 (Level 5 card) |
| Gas Mask | Reduces O2 depletion in poison gas corridors. Nuke Building B2 (Level 3 card) |
| Body Armor | Reduces all projectile damage by 50% |
| Scope | Binoculars. Zoom in first-person. Available from start |
| Mine Detector | Shows Claymores on radar. Crawl over mines to collect. Tank Hangar 2F (Level 2 card) |
| Diazepam | Temporarily steadies PSG-1 scope sway. Multiple doses carried |
| Cigarettes | Reveals IR laser beams (smoke makes them visible). Slowly drains HP while equipped. Available from start |
| Cardboard Box A | Stealth disguise. Fast travel → Heliport. Tank Hangar 2F (Level 1 card) |
| Cardboard Box B | Fast travel → Nuke Building. Nuke Building B1 (Level 4 card) |
| Cardboard Box C | Fast travel → Snowfield. Snowfield warehouse (Level 6 card) |
| Bandage | Stops bleeding (prevents blood trail that guards follow) |
| Cold Medicine | Cures cold (stops sneezing that alerts guards). Nuke Building B1 (Level 6 card) |
| Ketchup | Fake blood in prison cell to trick guard into opening door |
| Handkerchief | Sniper Wolf's scent. Pacifies wolves in cave area. Given by Otacon during prison sequence |
| Rope | Rappelling down Comm Tower A. Found at top of Comm Tower A |
| Timer Bomb | Planted in Snake's inventory after torture. Must be discarded immediately (~25-minute fuse) |
| Camera | Takes photos. Enables ghost photo mini-game (42–43 developer ghosts). Hidden room near Ocelot arena (C4 wall) |
| AP Sensor | Detects humans via controller vibration. Stronger rumble = closer enemy. Useful when radar jammed |

### 5.4 Key Items

**Security Keycards (Levels 1–7)** — Single card that upgrades through story. Higher levels open all doors at or below that level.

| Level | Source |
|---|---|
| 1 | DARPA Chief (Donald Anderson / Decoy Octopus) |
| 2 | Kenneth Baker (after Ocelot fight) |
| 3 | Dead soldier (after Tank fight) |
| 4 | Otacon (after Ninja fight) |
| 5 | Otacon (during prison sequence) |
| 6 | Otacon (during prison escape) |
| 7 | Vulcan Raven (after his second fight) |

**PAL Key** — Shape memory alloy card. Changes form with temperature. Must be inserted into three terminals in REX's hangar:
1. **Yellow** (room temperature) — insert first
2. **Blue** (cold) — carry to Warehouse/Freezer, wait ~61 seconds to freeze. Insert second
3. **Red** (hot) — carry to Blast Furnace, wait ~61 seconds to heat. Insert third

The key reverts if carried through the wrong temperature zone. Narrative twist: inserting all three keys **activates** REX (Liquid's deception), not deactivates it.

**MO Disc** — Contains REX combat data. Plot MacGuffin given by Baker. Removed from inventory when captured.

---

## 6. Enemies & AI

### 6.1 Genome Soldiers

Next-Generation Special Forces, genetically enhanced with Big Boss's soldier genes. Primary enemy throughout Shadow Moses.

**Behavior variations:**
- **Patrolling** — Walk set routes in a loop. Vision cone visible on radar. Turn at fixed waypoints.
- **Stationary** — Guard a fixed position, scanning a limited arc.
- **Sleeping** — Won't detect Snake unless loud noise or physical contact.

**Equipment variants:**
- **Standard (FAMAS)** — Most common. 5.56mm assault rifle, 25-round magazine.
- **NBC troops** — Gas masks, dark fatigues. Nuke Building. FAMAS with underbarrel grenade launcher.
- **Arctic warfare** — Winter camo for outdoor/snow areas.
- **Shotgun (reinforcements only)** — SPAS-12. Only dispatched during Alert mode. Not on normal patrols.

**Detection parameters:**

| Parameter | Easy | Normal | Hard | Extreme |
|---|---|---|---|---|
| Hearing | Poor | Normal | Normal | Extreme |
| Bullet damage | 64 | 96 | 128 | 128 |

### 6.2 Security Systems

- **Surveillance cameras** — Fixed wall-mounted, sweep a set arc. Vision cone on radar. Destroyed with explosives. Disabled by Chaff (~10s). Blind spot directly underneath.
- **Gun cameras** — Camera + automatic machine gun. Found in Comm Tower stairwells (sets of 1, 2, 3, then 4). Trigger immediate gunfire on detection. Disabled by Chaff. Destroyed with explosives or sustained fire.
- **Claymore mines** — Invisible. Detectable with Mine Detector (radar dots) or Thermal Goggles. Crawl to collect. Walking/running detonates.
- **IR sensors** — Invisible laser tripwires. Revealed by Cigarette smoke or Thermal Goggles. Breaking a beam triggers Alert or gas trap.

### 6.3 AI Behaviors

- **Footprint tracking** — Guards follow snow footprints to Snake's position. If trail ends (faded), they return to patrol.
- **Body discovery** — Limited compared to later MGS games. Guards who walk near a downed colleague become suspicious ("?" indicator) and investigate.
- **Radio call** — On spotting Snake, guards have a brief window before completing a radio call. Kill/KO them before completion to prevent Alert.
- **Cannot shoot radios** — This mechanic was added in MGS2/3. Must neutralize the entire guard.
- **Sound investigation** — Guards investigate knocked walls, footsteps on noisy surfaces, gunshots. Leave patrol route, search briefly, return if nothing found.
- **Dead guard respawn** — Easy/Normal: guards do not respawn. Hard/Extreme: guards eventually respawn.
- **Unconscious guards** — Wake up after a period of time.
- **Choking timing** — 10 taps to kill, 9 to knock unconscious.

### 6.4 Wolves

Found exclusively in the cave area. Hostile by default — bite on sight.
- **Handkerchief** — Sniper Wolf's scent; pacifies wolves.
- **Scent-marked Box** — If Meryl punches a wolf pup and Snake equips a box near it, the pup urinates on the box. This box then pacifies wolves on subsequent visits.

---

## 7. Boss Fights

### 7.1 Revolver Ocelot

| | |
|---|---|
| **HP** | 1024 (all difficulties) |
| **Snake HP** | 256 |
| **Arena** | Rectangular room. Baker wired to C4 tripwires in center — touching wires = instant Game Over |
| **Weapon** | Single Action Army revolver (6 shots, then reloads) |

- Fight restricted to the outer perimeter. Both combatants circle the room.
- Bullets ricochet off walls — cover doesn't guarantee safety.
- **Attack window:** 6-shot reload. On Easy, Ocelot stands still during taunts.
- Running speed increases on higher difficulties.
- **Damage:** Ocelot's SAA = 48–66. SOCOM = 92–128. Grenade = 367–512.
- **Shots to kill:** 7 SOCOM (Easy) to 12 (Extreme).

### 7.2 M1 Tank (Vulcan Raven 1st)

| | |
|---|---|
| **Snake HP** | 320 |
| **Arena** | Open canyon snowfield with minefield |

- Tank has main cannon (~201–206 damage) and machine gun (48 damage).
- **Chaff Grenades** disable tank's electronic targeting — forces machine gun only. Essential.
- **Grenades** thrown at the turret are the primary damage method.
- Claymores/C4 on the tank's path damage treads, slowing it.
- Staying close forces machine gun use (cannon requires distance).
- Rations and grenades resupply at the top of the map.

### 7.3 Cyborg Ninja (Gray Fox)

| | |
|---|---|
| **HP** | 255 (Phase 3 separate: ~120) |
| **Snake HP** | 384 |
| **Arena** | Otacon's Laboratory |

**Phase 1 — Sword:** Deflects ALL bullets. Must fight unarmed (PPK combo). Dodge sword slashes, counter.

**Phase 2 — Stealth Camo:** Goes invisible. Hides behind computers. Shadow visible. Thermal Goggles reveal. Chaff Grenades stun him (cybernetic suit disruption).

**Phase 3 — Electric Field:** Generates electrical field (punching it damages Snake 50–300). Guns now work. Use FAMAS/SOCOM at range.

**Phase 4 — Frenzy:** Faster teleports, aggressive sword combos (162–255 damage). Continue ranged weapons.

### 7.4 Psycho Mantis

| | |
|---|---|
| **HP** | 904 (Easy) to 1,260 (Extreme) |
| **Snake HP** | 448 |
| **Arena** | Director's Office |

**Pre-fight fourth-wall sequence:**
- Memory card reading (Castlevania: SotN, Suikoden, Azure Dreams, Vandal Hearts, Policenauts)
- Play style analysis based on MGS save data
- DualShock vibration demonstration
- HIDEO blackout (fake TV channel switch)

**Meryl possession:** Mantis controls Meryl — she attacks Snake or aims at herself. Punch her unconscious or Stun Grenade.

**Core mechanic:** Mantis reads Port 1 controller inputs, dodging everything. **Solution:** Switch controller to Port 2. Alternate: destroy the two busts in upper corners of the room.

**Attacks (after port switch):** Psychic blasts (44–80), thrown furniture (36–60, dodge by crawling), spinning paintings (cannot crawl under — run sideways), teleportation to 3 positions, stealth camo (Thermal Goggles counter).

**Hits to kill:** 16 (Easy) to 44 (Extreme).

### 7.5 Sniper Wolf (1st)

| | |
|---|---|
| **HP** | 1,024 (all difficulties) |
| **Snake HP** | 512 |
| **Arena** | Underground passage corridor — long-range sniper alley |

- **Required weapon:** PSG-1.
- **Diazepam** steadies scope sway.
- Wolf's red laser sight shows her aim. When laser disappears, she's repositioning (safe to aim).
- Hide behind wall, wait for laser to drop, pop out, Diazepam, fire. 5–7 hits to kill.

### 7.6 Hind D (Liquid's Helicopter)

| | |
|---|---|
| **HP** | 1,024 (all difficulties) |
| **Snake HP** | 576 |
| **Arena** | Comm Tower B rooftop with water tanks for cover |

- **Stinger only** — all other weapons ineffective.
- Attacks: machine gun strafing (90–180 damage), guided missiles (256–512).
- After 5–7 hits, Hind retreats behind building (Phase 2), re-engages more aggressively.
- **Hits to kill:** 14 (Easy) to 18 (Extreme).

### 7.7 Sniper Wolf (2nd)

| | |
|---|---|
| **HP** | 1,024 (all difficulties) |
| **Arena** | Open snowfield with trees and rock cover |

- PSG-1 + Diazepam works but open terrain makes it harder.
- **Nikita strategy (safer):** Guide remote missiles around cover to hit Wolf from the side. She can't shoot them down.
- 7–10 hits to kill.

### 7.8 Vulcan Raven (2nd — On Foot)

| | |
|---|---|
| **HP** | 600 (Easy) to 840 (Extreme) |
| **Snake HP** | 704 |
| **Arena** | Freezer warehouse — shipping container maze |

- Raven carries M61 Vulcan gatling gun (90–225 damage). Never stand in front.
- Position visible on radar.
- **Nikita missiles** — effective from behind, but Raven shoots them down from the front.
- **Claymore mines** — plant in his patrol path.
- **Stinger/Grenades** — hit from side/behind.
- 7–10 explosive hits to kill.

### 7.9 Metal Gear REX

| | |
|---|---|
| **HP** | 1,500 (Easy) to 2,100 (Extreme) |
| **Snake HP** | 768 (auto-refilled) |
| **Arena** | Underground hangar |

**Phase 1 — Radome:** Target the radar dish on REX's left shoulder with Stinger missiles. Chaff Grenades jam REX's missile homing — critical. REX attacks: homing missiles (128–256), machine gun (32–160), laser (160–200), stomp (devastating at close range). 2-second invincibility frames between Stinger hits.

**Transition:** Gray Fox appears, sacrifices himself to physically destroy the radome. Liquid opens the cockpit.

**Phase 2 — Open Cockpit:** Target exposed cockpit. No more homing missiles but Liquid aims manually. Optimal distance: close enough that missiles overshoot, far enough to avoid stomp. Passing between REX's legs breaks line of sight.

**Total Stinger hits:** 12 (Easy) to 18 (Extreme) across both phases.

### 7.10 Liquid Snake (Fistfight)

| | |
|---|---|
| **HP** | 255 (P1) + 170 (P2) + ~56 (P3) |
| **Snake HP** | Auto-refilled |
| **Arena** | Top of Metal Gear REX wreckage |

- **Hand-to-hand only.** Time limit: **2m 30s** (first attempt), **3m** (after Game Over).
- PPK combo: punches 28–70, kicks 56–140. Completing the full combo is risky — Liquid often counterattacks after the kick.
- **Safe strategy:** Two punches, retreat before kick.
- As HP drops, Liquid gains a charging tackle. Sidestep, punish during recovery.
- **Fight does not end at 0 HP** — must land a kick to knock Liquid off the edge.
- If Snake is knocked off, mash button to climb back. Do NOT approach Liquid when he's hanging — he does a reversal.

### 7.11 Jeep Chase (Final)

- Rail-shooter segment. Meryl or Otacon drives, Snake shoots.
- **Hits to win:** 16 (Easy) to 31 (Extreme).
- Infinite ammo during this sequence.

### Boss HP Summary

| Boss | HP (Normal) | HP (Extreme) |
|---|---|---|
| Revolver Ocelot | 1,024 | 1,024 |
| M1 Tank | varies | varies |
| Cyborg Ninja | 255 (+~120 P3) | 255 |
| Psycho Mantis | ~904 | ~1,260 |
| Sniper Wolf 1 | 1,024 | 1,024 |
| Hind D | 1,024 | 1,024 |
| Sniper Wolf 2 | 1,024 | 1,024 |
| Vulcan Raven 2 | ~600 | ~840 |
| Metal Gear REX | ~1,500 | ~2,100 |
| Liquid (fistfight) | 255/170/~56 | same |
| Jeep Chase | 16–31 hits | 16–31 hits |

---

## 8. Economy

No currency or shop system. MGS1's "economy" is the **Rank system** — defeating bosses progressively increases Snake's max HP and max ammo capacity (see §1.4 and §5.2). Items are found in the field, not purchased.

**Ammo respawn by difficulty:** Easy = respawns quickly; Normal/Hard = respawns slowly; Extreme = does not respawn.

### Difficulty Scaling Summary

| Parameter | Easy | Normal | Hard | Extreme |
|---|---|---|---|---|
| Guard hearing | Poor | Normal | Normal | Extreme |
| Guard bullet damage | 64 | 96 | 128 | 128 |
| Turret damage | 80 | 120 | 120 | 160 |
| Max Rations | 5 | 5 | 2 | 2 |
| Ammo respawn | Fast | Slow | Slow | None |
| HP restore after boss | Full | Pre-upgrade amount | +64 only | None |

The original PS1 release ships with **Easy** and **Normal**. Beating the game unlocks **Hard** and **Extreme**. The Integral version adds **Very Easy** (includes silenced infinite-ammo MP5).

---

## 9. Minigames & Side Systems

### 9.1 VR Training (Built-in)

Accessible from the main menu. Tron-inspired virtual grid environments.
- **10 Sneaking missions** (+ Practice variants with easier placement, no timer)
- **10 Time Attack missions** (same maps, timed)
- **1 Survival Mode** (unlocked by completing all 30 stages)

### 9.2 VR Missions (Standalone Expansion, 1999)

Separate disc: **300 missions** across categories:
- **Sneaking Mode (60):** Reach goal undetected. Sub-modes: "No Weapon" (pure stealth), "SOCOM" (eliminate all enemies).
- **Weapon Mode (80):** Destroy targets with assigned weapon. Bonus for unused ammo.
- **Advanced Mode (80):** Bomb disposal, puzzle solving, time trials.
- **Special Mode:** Includes Cyborg Ninja–playable missions.

### 9.3 Ranking System

An animal codename rank is assigned at the end of each playthrough based on performance across 4 difficulty levels.

**Measured criteria:** Clear time, alerts, kills, continues, rations consumed, saves.

**Selected ranks:**

| Tier | Easy | Normal | Hard | Extreme |
|---|---|---|---|---|
| Best | Hound | Doberman | Fox | **Big Boss** |
| Speed | Pigeon | Falcon | Hawk | Eagle |
| High kills | Piranha | Shark | Jaws | Orca |
| High rations | Pig | Elephant | Mammoth | Whale |
| Many saves | Cat | Deer | Zebra | Hippopotamus |
| Slow clear | Koala | Capybara | Sloth | Giant Panda |
| Worst | Chicken | Mouse | Rabbit | Ostrich |
| Stealth | Spider | Tarantula | Centipede | Scorpion |

**Big Boss rank requirements (highest possible):**
- Difficulty: Extreme
- Clear time: under 3 hours
- Continues: 0
- Alerts: 4 or fewer
- Kills: 25 or fewer
- Rations used: 1 or fewer
- Special items (Bandana/Stealth): allowed

### 9.4 Ghost Photos

Using the Camera item, 42–43 invisible developer "ghost" images are hidden at specific locations/angles throughout the game. They appear as transparent faces in photos. An "Exorcise" option in the photo viewer removes them.

---

## 10. UI & HUD

### 10.1 Gameplay HUD

The HUD is minimal and context-sensitive. During normal gameplay:

| Element | Position | Description |
|---|---|---|
| **Life Gauge** | Top-left | Horizontal bar labeled "LIFE." Depletes left-to-right as damage is taken. Color shifts green → yellow → red at low HP. |
| **O2 Gauge** | Below Life Gauge | Appears only underwater or in gas-filled areas. Depletes over time; reaching zero drains HP rapidly. Gas Mask slows depletion. |
| **Equipped Weapon** | Top-right (below radar) | Weapon icon + name. Ammo display: current magazine / total reserve. Shows "NO WEAPON" when unarmed. |
| **Equipped Item** | Top-left (below Life Gauge) | Item icon + name. Quantity display. Shows "NO ITEM" when nothing equipped. |
| **Soliton Radar** | Upper-right corner | Top-down minimap of immediate area. Snake = white dot, enemies = red dots with vision cone triangles. Walls and room layout visible. See §1.6 for states. |
| **Alert Timer** | Replaces radar | During Alert/Evasion: radar replaced by phase label ("ALERT" / "EVASION") + countdown from 99.99. |

### 10.2 In-Game Indicators

- **"!" (Exclamation Mark)** — Large red icon above enemy's head on visual confirmation of Snake. Accompanied by the iconic ascending alert sting. Triggers Alert mode.
- **"?" (Question Mark)** — Icon above enemy's head on suspicious sound/trace. Softer alert tone. Guard investigates but no Alert triggered yet.
- **Damage feedback** — Screen flashes red on hit. No floating damage numbers (damage values are internal only).
- **Boss health bars** — Bosses display a Life Gauge identical in style to Snake's, positioned at the bottom of the screen. Labeled with the boss's name.
- **"FULL" message** — Displayed when attempting to pick up ammo/items at max capacity.
- **"GET WEAPON FIRST"** — Displayed when stepping on ammo for a weapon not yet acquired.
- **Interaction prompts** — No explicit button prompts on screen. The player learns controls from the Codec (Campbell explains mechanics contextually) and the manual.

### 10.3 Menu Overlays

**Weapon/Item Selection (R2/L2):** Holding R2 or L2 opens a horizontal strip overlay. Weapon strip at top-right, item strip at top-left. Icons scroll left/right with D-pad. Releasing the shoulder button equips the highlighted selection. Gameplay pauses while menus are open.

**Codec Screen:** Full-screen overlay showing two character portraits (caller and receiver) flanking a frequency display. Waveform visualization animates with voice. Frequency adjustable with D-pad. Memory Window (Down) shows quick-dial list of known contacts.

**Pause Menu (Start):** Options include Resume, Codec (frequencies), Options (audio/display settings), and Quit. No map screen — navigation relies on the Soliton Radar and memorization.

### 10.4 HUD State Changes

| Game State | HUD Behavior |
|---|---|
| Infiltration (normal) | Full HUD — life gauge, radar, equipped weapon/item |
| Alert | Radar replaced by "ALERT" + countdown. Life gauge and equipment visible |
| Evasion | Radar replaced by "EVASION" + countdown |
| Codec | Full-screen codec overlay. Gameplay paused |
| Cutscene | HUD hidden. Player input locked |
| Boss fight | Boss life gauge added at bottom. Snake's HUD remains. Radar may be disabled on higher difficulties |
| First-person view | HUD remains. Binoculars/scope overlay depending on item (PSG-1 = crosshair + scope ring, Stinger = lock-on reticle) |
| Wall press | HUD remains. Camera angle shifts to show around corner |

---

## 11. Engine & Presentation Systems

### 11.1 Save System

Manual saves only via Codec call to Mei Ling (140.96). Saving records progress at the last checkpoint. Checkpoints placed at: area transitions, before boss fights, certain story milestones. Loading shows a mission log summarizing story progress and objectives. Mei Ling offers a different proverb each save.

### 11.2 Game Over

When HP reaches 0 without an equipped Ration:
- Screen shows "GAME OVER."
- Support character shouts "Snake? SNAKE? SNAAAAAAKE!" (varies by who is on Codec).
- Options: Continue (restart from checkpoint) or Quit (title screen).

**Special Game Over conditions:**
- Killing a hostage (Baker during Ocelot, Meryl during Mantis) = instant Game Over
- Tripping Tank Hangar laser beams = gas trap Game Over
- Timer Bomb not discarded = Game Over
- REX stomp = instant death
- Failing timed sequences (Liquid fistfight timer)

**Torture exception:** The torture scene is the only point with **no Continue option**. HP reaching 0 = hard Game Over, must load last manual save. Ocelot: "There are no continues, my friend."

### 11.3 Camera

Fixed overhead camera with contextual angles. Camera tilts when wall-pressing to show around corners. Certain rooms use dramatic angles. First-person view (Triangle) for observation only (no shooting in original PS1). Scoped weapons (PSG-1, Stinger) override to first-person.

### 11.4 Dialogue

All dialogue is **fully voice-acted**. Story exposition primarily through Codec calls and in-engine cutscenes. Cutscenes are real-time (no pre-rendered FMV for gameplay scenes). Player input locked during cutscenes. Codec conversations pause gameplay.

### 11.5 Controls (PS1)

| Button | Action |
|---|---|
| D-Pad / Left Stick | Move |
| X | Crouch / Stand / Crawl (contextual) |
| Circle | Action: interact, punch (×3 for PPK combo) |
| Square | Weapon: fire (hold to aim) / Grab-Choke (unarmed near enemy) |
| Triangle | First-person view |
| R1 | Weapon quick-cycle |
| R2 (hold) | Weapon menu |
| L1 | Item quick-cycle |
| L2 (hold) | Item menu |
| Select | Codec |
| Start | Pause |

---

## 12. Open Questions / Unverified

1. **Exact sight cone distances and angles** — community estimates 45–60° arc, 15–20m range. No published official values. The FoxdieTeam decompilation project may contain precise values.
2. **Evasion timer duration** — varies by area and difficulty; exact base values not confirmed across all scenarios.
3. **Guard respawn timing on Hard/Extreme** — known to occur but exact intervals unverified.
4. **Exact ammo capacity progression** — the table in §5.2 is partial (sourced from speedrunner data). Full progression for all weapons at all ranks needs verification against the decompiled source.
5. **Damage formula internals** — damage ranges are documented from gameplay observation but the exact formula (random factor, defense calculation) should be verifiable from the decompiled C source.
6. **Hind D fight exact hit thresholds** — Stinger damage vs Hind varies by source (57–69 per hit vs fixed 64). Phase transition trigger needs pinning.
7. **Tank boss HP model** — described as "combined gunner health" but exact values not confirmed.
8. **PAL Key temperature timers** — listed as ~61 seconds each; may vary by version (PS1 vs Integral vs Master Collection).

---

## 13. References

### Metal Gear Wiki (Fandom)
- Enemy status: https://metalgear.fandom.com/wiki/Enemy_status
- Exclamation point: https://metalgear.fandom.com/wiki/Exclamation_point
- Soliton Radar: https://metalgear.fandom.com/wiki/Soliton_Radar
- Gun camera: https://metalgear.fandom.com/wiki/Gun_camera
- Infrared sensor: https://metalgear.fandom.com/wiki/Infrared_sensor
- Next-Generation Special Forces: https://metalgear.fandom.com/wiki/Next-Generation_Special_Forces
- Torture device: https://metalgear.fandom.com/wiki/Torture_device
- Suppressor: https://metalgear.fandom.com/wiki/Suppressor
- Ration: https://metalgear.fandom.com/wiki/Ration
- Card key: https://metalgear.fandom.com/wiki/Card_key
- Cigarette: https://metalgear.fandom.com/wiki/Cigarette
- Anti-personnel sensor: https://metalgear.fandom.com/wiki/Anti-personnel_sensor
- Codename (gameplay): https://metalgear.fandom.com/wiki/Codename_(gameplay)
- Shadow Moses Island: https://metalgear.fandom.com/wiki/Shadow_Moses_Island
- Metal Gear Solid secrets: https://metalgear.fandom.com/wiki/Metal_Gear_Solid_secrets
- Game Over: https://metalgear.fandom.com/wiki/Game_Over

### Konami Official Manual (Master Collection)
- Alert levels: https://metalgear.konami.net/manual/mc1/mgs1/pc/en/page10.html
- Codec: https://metalgear.konami.net/manual/mc1/mgs1/pc/en/page05.html
- Controls: https://metalgear.konami.net/manual/mc1/mgs1/pc/en/page03.html
- Inventory: https://metalgear.konami.net/manual/mc1/mgs1/pc/en/page06.html
- Movement: https://metalgear.konami.net/manual/mc1/mgs1/pc/en/page19.html

### StrategyWiki
- Weapons: https://strategywiki.org/wiki/Metal_Gear_Solid/Weapons
- Items: https://strategywiki.org/wiki/Metal_Gear_Solid/Items
- VR Training: https://strategywiki.org/wiki/Metal_Gear_Solid/VR_Training

### Metal Gear Speedrunners Wiki
- Boss data: https://metalgearspeedrunners.com/wiki/doku.php?id=mgs1_bosses
- Difficulty differences: https://metalgearspeedrunners.com/wiki/doku.php?id=mgs1_difficulty_differences
- FAQ: https://metalgearspeedrunners.com/wiki/doku.php?id=mgs1_faq
- Big Boss rank: https://metalgearspeedrunners.com/wiki/doku.php?id=big_boss_rank_requirements

### Samurai Gamers
- All weapons: https://samurai-gamers.com/metal-gear-solid/all-weapons-list-and-locations-mgs1/
- All items: https://samurai-gamers.com/metal-gear-solid/all-items-list-and-locations-mgs1/
- Controls: https://samurai-gamers.com/metal-gear-solid/game-controls-mgs1/
- Post-game unlockables: https://samurai-gamers.com/metal-gear-solid/post-game-unlockables-guide-mgs1/
- Boss guides: https://samurai-gamers.com/metal-gear-solid/main-story-walkthrough-2/

### Decompilation
- FoxdieTeam MGS PSX decompilation: https://github.com/FoxdieTeam/mgs_reversing (main EXEs 100% decompiled to C; overlays ongoing)

### GameFAQs
- Rankings FAQ: https://gamefaqs.gamespot.com/ps/197909-metal-gear-solid/faqs/4029
- Boss guide: https://gamefaqs.gamespot.com/ps/197909-metal-gear-solid/faqs/4023

### Other
- IMFDB weapon reference: https://www.imfdb.org/wiki/Metal_Gear_Solid
- Wikipedia: https://en.wikipedia.org/wiki/Metal_Gear_Solid_(1998_video_game)
