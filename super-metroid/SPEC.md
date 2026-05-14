# Super Metroid — Gameplay Systems Spec

Super Nintendo Entertainment System (SNES), 1994. Developed by Nintendo R&D1 and Intelligent Systems. Published by Nintendo.

---

## 1. Core Gameplay Systems

### 1.1 Primary Loop

Super Metroid is a 2D action-exploration platformer — the defining entry of the "Metroidvania" genre. The core loop is:

1. **Explore** the interconnected world of Planet Zebes
2. **Encounter barriers** — locked doors, environmental hazards, impassable terrain
3. **Acquire upgrades** that grant new movement or combat abilities
4. **Return** to previously inaccessible areas now reachable with new abilities
5. **Defeat bosses** to unlock deeper regions
6. **Repeat** until the final confrontation

The game is non-linear within its gating structure. Multiple paths through the world are viable, and the game famously supports sequence breaking (§3.3).

### 1.2 Combat System

Combat is real-time, integrated into exploration. Samus can fire her arm cannon in eight directions while standing or jumping, and can fire downward while airborne.

**Aiming directions:** Left, Right, Up, Diagonal-Up-Left, Diagonal-Up-Right, Diagonal-Down-Left, Diagonal-Down-Right, Down (air only).

**Weapon categories:** Beams (infinite ammo, chargeable, stackable — §6.1), Missiles and Super Missiles (limited ammo projectiles — §6.6), Bombs and Power Bombs (Morph Ball explosives — §6.6), and utility items like the Grapple Beam and X-Ray Scope (§6.5).

**Damage to Samus:** Contact with enemies and environmental hazards depletes energy. Suit upgrades provide damage reduction (§6.3). When energy reaches zero, Reserve Tanks activate (if set to Auto — §6.7) or the game ends.

### 1.3 Resource Management

| Resource | Starting | Maximum | Refill Sources |
|---|---|---|---|
| Energy | 99 | 1,499 | Enemy drops, Recharge Stations, Gunship |
| Reserve Energy | 0 | 400 | Energy pickups (only when main energy is full) |
| Missiles | 0 | 230 | Enemy drops, Missile Recharge, Gunship |
| Super Missiles | 0 | 50 | Enemy drops, Missile Recharge, Gunship |
| Power Bombs | 0 | 50 | Enemy drops, Missile Recharge, Gunship |

See §6.7 for expansion pickup counts and §7.3 for enemy drop tables.

### 1.4 Progression

Progression is gated by equipment (§3.3). Defeating the four main bosses — Kraid, Phantoon, Draygon, and Ridley — unlocks the path to the final area, Tourian. The game tracks item collection percentage on the file select screen. 100% completion requires collecting all 100 items (§6.7).

---

## 2. Controls & Input

### 2.1 Default Button Layout (SNES Controller)

| Button | Action |
|---|---|
| D-Pad Left/Right | Move |
| D-Pad Up | Aim Up / Enter Door |
| D-Pad Down | Crouch / Morph Ball (press twice) |
| B | Jump |
| Y | Fire |
| X | Cancel Item (deselects Missile/Super/Power Bomb) |
| A | Dash (hold to run) |
| L | Aim Diagonal Down |
| R | Aim Diagonal Up |
| Select | Cycle selected sub-weapon (Missiles → Super Missiles → Power Bombs → X-Ray → Grapple) |
| Start | Pause / Map Screen |

### 2.2 Remapping

All face buttons and shoulder buttons can be remapped via the Controller Setting Mode on the title screen. The D-Pad and Start are fixed. Aim Diagonal Up and Aim Diagonal Down can only be assigned to L or R; if those shoulder buttons are reassigned, the diagonal aim is unbound.

### 2.3 Context-Sensitive Inputs

- **Morph Ball:** Press Down twice from standing, or once from crouching
- **Mid-air Morph:** Press Down twice while airborne; horizontal velocity is preserved if Jump is held
- **Wall Jump:** While spin-jumping against a wall, press away from the wall then press Jump (§4.4)
- **Shinespark charge:** While running at full Speed Booster speed, press Down to store the charge (§4.5)
- **Grapple Beam:** Hold the Fire button while Grapple is selected and aim diagonally; release to let go
- **X-Ray Scope:** Hold the Fire button while X-Ray is selected to scan; Samus is stationary during use

---

## 3. World Structure

### 3.1 Overview

The game takes place across two locations: **Space Colony Ceres** (brief prologue) and **Planet Zebes** (the main game). Zebes is a single contiguous world divided into six major areas connected by elevators, shafts, and tunnels. There is no fast travel aside from returning to the Gunship on the surface.

### 3.2 Areas of Zebes

| Area | Environment | Key Features |
|---|---|---|
| **Crateria** | Surface, rain, rocky caves | Landing Site (Gunship), starting area, connects to all other areas. Old Tourian entrance from Metroid 1 |
| **Brinstar** | Underground jungle, overgrown caves | Largest area. Split into sub-regions (Blue, Green, Pink, Red). Home to Kraid and Spore Spawn |
| **Norfair** | Volcanic, extreme heat | Upper and Lower sections. Requires Varia Suit for heat protection. Home to Crocomire, Ridley, and Golden Torizo |
| **Wrecked Ship** | Derelict spacecraft, powered down | All rooms are dark and systems inert until Phantoon is defeated, then power is restored |
| **Maridia** | Underwater caves, sand, quicksand | Heavy underwater traversal. Requires Gravity Suit for free movement. Home to Botwoon and Draygon |
| **Tourian** | Space Pirate command center | Final area. Linear gauntlet of Metroids leading to Mother Brain. Unlocked after defeating all four main bosses |

**Area connections:** Elevators link areas vertically. Crateria connects to Brinstar (central elevator), to the Wrecked Ship (through the flooded cavern), and to Maridia (far-right elevator). Brinstar connects to Norfair (multiple elevators) and to Maridia (through the Red Tower descent). Tourian is accessed from Crateria's old entrance after all four statues are activated.

### 3.3 Ability Gating

Progression is gated by abilities that open new traversal options and door/barrier types. The table below lists the primary gates.

**Door Types:**

| Door Color | Opens With | Behavior |
|---|---|---|
| Blue | Any weapon | Always openable once encountered |
| Red | 5 Missiles or 1 Super Missile | Permanently becomes blue after opening |
| Green | 1 Super Missile | Permanently becomes blue after opening |
| Yellow | 1 Power Bomb | Permanently becomes blue after opening |
| Gray | N/A | Locked until a room condition is met (e.g., all enemies killed) |
| Eye | Shoot the eye with Missiles/Supers | Organic barrier in Tourian. Opens when hit, closes permanently behind Samus |
| Metal | Indestructible | Permanent wall; cannot be opened |

**Gate Switches:**

| Gate Color | Opens With | Notes |
|---|---|---|
| Blue | Any beam shot | Wave Beam can activate from either side |
| Green | 1 Super Missile | Only from the side with the switch |

**Block Types:**

| Block Type | Cleared By |
|---|---|
| Bomb Block | Bombs, Power Bombs |
| Missile Block | Missiles, Super Missiles |
| Super Missile Block | Super Missiles only |
| Power Bomb Block | Power Bombs only |
| Speed Booster Block | Running through with Speed Booster active |
| Screw Attack Block | Screw Attack contact |
| Crumble Block | Collapses shortly after Samus stands on it |
| Shot Block | Any beam or missile |
| Grapple Block | Grapple Beam |

**Critical progression abilities (intended order):**

1. **Morph Ball** → access to tunnels and small passages
2. **Missiles** → open red doors
3. **Bombs** → break bomb blocks, perform bomb jumps
4. **Super Missiles** → open green doors
5. **Power Bombs** → open yellow doors, clear Power Bomb blocks
6. **Speed Booster** → break Speed Booster blocks, access Shinespark traversal
7. **Ice Beam** → freeze enemies as platforms (required for Tourian Metroids)
8. **Varia Suit** → survive heated rooms in Norfair
9. **Gravity Suit** → free movement in water/lava
10. **Grapple Beam** → cross large gaps via Grapple points
11. **Space Jump** → infinite mid-air somersaults, reach any height

**Minimum required items to complete the game:** Morph Ball, Missiles, Bombs, Super Missiles, Power Bombs, Speed Booster or Ice Beam (at least one), and at minimum 3 Energy Tanks.

---

## 4. Movement & Traversal

### 4.1 Basic Movement

- **Walking:** D-Pad left/right. Moderate speed.
- **Running (Dash):** Hold the Dash button while walking. Significantly faster. Required to activate the Speed Booster.
- **Crouching:** Press Down. Samus lowers her profile, can fire forward or diagonally upward.
- **Jumping:** Variable height based on how long Jump is held. Full jump height is roughly 3 tiles; with Hi-Jump Boots, roughly 5 tiles.
- **Spin Jump:** Initiated by jumping while moving horizontally. Samus somersaults; enables Wall Jump and Space Jump. Cannot fire beams during spin (can fire missiles/supers).

### 4.2 Morph Ball

- Press Down twice from standing (or once from crouching) to enter Morph Ball form
- Samus becomes a sphere roughly 1 tile in diameter, fitting through narrow passages
- Can lay Bombs (unlimited, 3-second fuse, maximum 3 active at once) and Power Bombs
- **Spring Ball** (upgrade): enables jumping in Morph Ball form. Jump height matches bipedal jump (affected by Hi-Jump Boots)
- **Bomb Jump:** A Bomb's explosion propels Morph Ball Samus upward. By timing sequential bomb placements, Samus can chain bomb jumps to gain unlimited vertical height (Infinite Bomb Jump)

### 4.3 Space Jump

After acquiring the Space Jump, Samus can chain spin jumps indefinitely by pressing Jump at the apex of each spin. This allows unlimited vertical and horizontal flight. Combined with the Screw Attack, Samus becomes a flying weapon that destroys most enemies on contact.

### 4.4 Wall Jump

Samus can kick off vertical walls while spin-jumping:
1. Spin-jump toward a wall
2. When Samus touches the wall, press the D-Pad away from the wall
3. Press Jump to kick off

Wall jumps can be chained between two walls or repeated on a single wall (with precise timing). This technique is taught in-game by the Etecoon creatures in Brinstar. Wall jumping can reach any height with practice, making it a key sequence-breaking tool.

### 4.5 Speed Booster & Shinespark

**Speed Booster:** While dashing on flat ground for approximately 36 tiles, Samus enters a blue/flashing speed state. In this state she destroys Speed Booster blocks and most enemies on contact, and cannot be stopped by normal means.

**Shinespark:** While in Speed Booster state, pressing Down stores a charge (Samus flashes). The charge lasts 180 frames (~3 seconds NTSC). During the charge window:
1. Press Jump while stationary to launch
2. Input a direction within the 28-frame window (frames 2–30):
   - **No input / Up:** Vertical launch
   - **Forward:** Horizontal launch (in facing direction)
   - **Diagonal Up + Forward:** Diagonal launch (hold Aim-Up before Jump)
   - Downward Shinespark is not possible

**Energy cost:** Shinespark drains 1 energy per frame during flight. Minimum 30 energy required to activate. Samus is damaged on collision impact (70-frame crash animation).

**Aerial Shinespark:** While spin-jumping with a stored charge, release Jump, press Up, then hold Jump + direction to launch from mid-air.

### 4.6 Mockball

The Mockball is an advanced technique that preserves running speed through a Morph Ball transition. Normally, entering Morph Ball kills horizontal momentum. By pressing Down to morph during the landing frames of a jump while at dash speed, Samus rolls at full running speed. This allows passing through Morph Ball tunnels at Speed Booster velocity and is a key tool for early sequence breaks — notably reaching the early Super Missiles in Brinstar without defeating Spore Spawn.

### 4.7 Underwater Movement

Without the Gravity Suit, water drastically reduces movement speed and jump height. Samus cannot Space Jump or Speed Boost underwater without the Gravity Suit. The Gravity Suit removes all water physics penalties.

---

## 5. Story & Progression

### 5.1 Structure

The game is divided into three acts with no explicit chapter markers — progression is continuous and player-driven.

**Prologue — Space Colony Ceres:**
Samus arrives at Ceres Station to find the researchers dead and the baby Metroid (the last Metroid, entrusted to Samus in Metroid II) stolen by Ridley. A brief encounter with Ridley triggers a 1-minute self-destruct countdown. Samus escapes to her ship. The Ceres Ridley fight is designed to be unwinnable — the station explodes before enough damage can be dealt under normal play.

**Main Game — Planet Zebes:**
Samus descends to Zebes to recover the baby Metroid and eliminate the Space Pirate threat. The four main bosses guard the path to Tourian:
- **Kraid** (Brinstar) — giant reptilian creature
- **Phantoon** (Wrecked Ship) — ghostly entity powering down the ship
- **Draygon** (Maridia) — aquatic crustacean boss
- **Ridley** (Lower Norfair) — Samus's nemesis, the Space Pirate commander

All four must be defeated to unlock Tourian's entrance.

**Finale — Tourian:**
A linear gauntlet of Metroids leads to Mother Brain through rooms sealed by Eye Doors (organic barriers that open when shot in the eye, then permanently close behind Samus). The Mother Brain fight has three phases (§7.2). After Mother Brain is defeated, a 3-minute countdown begins. Samus must escape from Tourian upward through Crateria to the Gunship. During the escape:
- Previously locked gray doors are open
- The screen shakes periodically
- A hidden path leads to the Etecoons and Dachoras — rescuing them is optional but acknowledged in the ending (they are seen flying away from Zebes)
- If the timer expires, Samus dies and the game returns to the title screen

### 5.2 Endings

The ending image varies based on completion time. All endings show the same narrative — there are no branching story paths. Faster times reveal more of Samus without her Power Suit:

| Completion Time | Ending |
|---|---|
| ≥10 hours | Samus in full suit, helmet on |
| 3–10 hours | Samus removes helmet |
| <3 hours | Samus in civilian clothes |

Item collection percentage is displayed on the ending screen but does not affect the ending image.

### 5.3 Environmental Storytelling

The game has no dialogue after the opening narration. Story is conveyed through environmental details: the ruined Ceres Station, the skeletal remains in Tourian, the baby Metroid's recognition of Samus during the Mother Brain fight, and the Etecoons/Dachoras teaching Samus advanced techniques.

---

## 6. Items & Equipment

### 6.1 Beam Weapons

Beams fire from Samus's arm cannon. Multiple beams can be equipped simultaneously and their effects stack. **Spazer and Plasma Beam are mutually exclusive** — only one can be active at a time. The Charge Beam can be combined with any beam.

**Beam Damage Table (internal values):**

| Beam Configuration | Uncharged | Charged (×3) |
|---|---|---|
| Power Beam (base) | 20 | 60 |
| Ice Beam | 30 | 90 |
| Spazer | 40 | 120 |
| Wave Beam | 50 | 150 |
| Plasma Beam | 150 | 450 |
| Ice + Spazer | 60 | 180 |
| Ice + Wave | 60 | 180 |
| Wave + Spazer | 70 | 210 |
| Ice + Wave + Spazer | 100 | 300 |
| Ice + Plasma | 200 | 600 |
| Wave + Plasma | 250 | 750 |
| Ice + Wave + Plasma | 300 | 900 |

**Beam properties:**
- **Charge Beam:** Hold Fire for 2 seconds to charge; release for a 3× damage shot. Charged shots also produce a Pseudo Screw Attack aura during spin jumps.
- **Ice Beam:** Freezes most enemies on contact. Frozen enemies serve as temporary platforms. Essential for defeating Metroids in Tourian.
- **Wave Beam:** Projectiles pass through walls and solid terrain. Allows activating blue gate switches from either side.
- **Spazer:** Fires three parallel beams in a spread pattern, increasing hit area.
- **Plasma Beam:** Projectiles pierce through enemies, hitting multiple targets in a line. Strongest standard beam.
- **Hyper Beam:** Acquired automatically during the Mother Brain fight. Deals 1,000 damage per shot. Cannot be toggled or unequipped. Only available during the final battle and escape sequence.

### 6.2 Charge Beam Combos (Special Attacks)

With the Charge Beam, one other beam, and Power Bombs selected, charging for 120 frames (~2 seconds) consumes 1 Power Bomb and activates a special attack:

| Combo | Required Beam | Effect | Damage per Particle |
|---|---|---|---|
| Ice Shield | Ice | 4 ice crystals orbit Samus clockwise, freeze enemies on contact | 90 |
| Wave Shield (X-Factor) | Wave | 4 purple spheres form X-pattern when stationary, wave orbit when moving | 300 |
| Spazer Shield | Spazer | 2 three-pronged projectiles rain downward | 300 |
| Plasma Shield | Plasma | 4 large green rings orbit Samus, pierce through enemies | 300 |

Only one non-Charge beam may be active for the combo to trigger.

### 6.3 Suit Upgrades

| Suit | Damage Reduction | Special Properties |
|---|---|---|
| Power Suit (default) | None (full damage) | Base suit |
| Varia Suit | Damage halved (×0.5) | Immunity to heated rooms in Norfair. Changes armor color to orange |
| Gravity Suit | Damage quartered (×0.25) | Free movement underwater and in lava. Protects against lava damage in upper Norfair. Changes armor color to purple |

Gravity Suit's damage reduction does **not** stack with Varia — Gravity alone provides ×0.25. Two exceptions: the Super Metroid's energy drain and Mother Brain's rainbow beam only receive the Varia Suit reduction, not Gravity.

**Environmental damage (per 4 frames):**

| Hazard | Power Suit | Varia | Gravity | Notes |
|---|---|---|---|---|
| Heated rooms | 1 | 0 | 0 | Norfair only. No suit reduction — Varia/Gravity grant full immunity |
| Lava (upper) | 2 | 1 | 0 | Upper Norfair. Gravity Suit grants immunity |
| Lava (lower) | 8 | 4 | 2 | Lower Norfair. Always damages, even with Gravity |
| Acid | 4 | 2 | 1 | Rare. Standard suit reduction applies |
| Spikes (weak) | 16 | 8 | 4 | Per contact |
| Spikes (strong) | 60 | 30 | 15 | Per contact |

### 6.4 Movement Upgrades

| Upgrade | Location | Effect |
|---|---|---|
| Morph Ball | Brinstar | Transform into a ball to fit through 1-tile passages |
| Bombs | Crateria | Lay bombs in Morph Ball form. Break bomb blocks. Enable bomb jumping |
| Spring Ball | Maridia | Jump while in Morph Ball form |
| Hi-Jump Boots | Norfair | Increases jump height by ~65% |
| Speed Booster | Norfair | Enables speed state after sustained dash. Breaks Speed Booster blocks. Enables Shinespark (§4.5) |
| Space Jump | Maridia | Chain spin jumps indefinitely for sustained flight |
| Screw Attack | Lower Norfair | Spin jumps deal massive damage (2,000 per frame) and destroy Screw Attack blocks |

### 6.5 Utility Upgrades

| Upgrade | Location | Effect |
|---|---|---|
| Grapple Beam | Norfair | Fires an electric tether to Grapple points. Samus swings from the point. Deals 20 damage to enemies. Can be used on Draygon's destroyed turrets for an instant kill |
| X-Ray Scope | Brinstar | Reveals hidden passages, breakable blocks, and items within line of sight. Samus is stationary while scanning |

### 6.6 Sub-Weapons

| Weapon | Damage | Notes |
|---|---|---|
| Missiles | 100 | Standard projectile. Opens red doors (5 hits) |
| Super Missiles | 300 | Slower, stronger projectile with small blast. Opens green doors (1 hit). Knocks Samus back slightly on fire |
| Bombs | 30 | Morph Ball only. 3-second fuse. Max 3 active. Propels Samus upward on detonation |
| Power Bombs | 200 | Morph Ball only. Screen-wide explosion. Opens yellow doors. Can hit twice on large enemies. Reveals hidden passages |

### 6.7 Expansions & Totals

| Expansion | Per Pickup | Count | Maximum |
|---|---|---|---|
| Missile Expansion | +5 | 46 | 230 |
| Super Missile Expansion | +5 | 10 | 50 |
| Power Bomb Expansion | +5 | 10 | 50 |
| Energy Tank | +100 Energy | 14 | 1,499 (99 base + 1,400) |
| Reserve Tank | +100 Reserve | 4 | 400 |
| Unique Equipment | — | 16 | — |
| **Total Items** | | **100** | |

**Reserve Tank modes:** Reserve Tanks can be set to Auto or Manual via the pause screen. In **Auto** mode, all reserve energy is dumped into main energy when it hits zero, preventing death. In **Manual** mode, the player activates reserves from the pause screen and can partially drain them by pressing Up during the refill. Reserve Tanks only charge from energy pickups when all main Energy Tanks are full.

### 6.8 Crystal Flash (Secret Technique)

A secret emergency healing technique:

**Requirements:** ≤50 energy, empty Reserve Tanks, ≥10 Missiles, ≥10 Super Missiles, ≥11 Power Bombs.

**Activation:** In Morph Ball form, select Power Bombs, hold L + R + Down + Fire. Must be at the exact detonation position with zero vertical speed.

**Effect:** Consumes 10 Missiles, 10 Super Missiles, 10 Power Bombs. Fully restores all Energy Tanks and fills Reserve Tanks to 230. Samus is **not** invincible during the animation — enemy contact still damages her.

---

## 7. Enemies & Bosses

### 7.1 Regular Enemies

Enemies populate every area of Zebes. They respawn when Samus re-enters a room. All damage values below are for Power Suit; see §6.3 for suit damage reduction.

**Representative enemies by area:**

| Area | Enemy | HP | Contact Damage | Notes |
|---|---|---|---|---|
| Crateria | Waver | 30 | 10 | Swooping insect |
| Crateria | Alcoon | 200 | 50 | Slow, high-HP |
| Brinstar | Zeela | 30 | 10 | Crawls along surfaces |
| Brinstar | Boyon | 1,000 | 10 | Bouncing blob, very high HP |
| Brinstar | Sidehopper | 100 | 20 | Leaping enemy, aggressive |
| Norfair | Holtz | 900 | 120 | Diving fire enemy |
| Norfair | Kihunter (red) | 1,800 | 200 | Strongest standard enemy |
| Wrecked Ship | Atomic | 250 | 40 | Ghostly orb |
| Wrecked Ship | Covern | 300 | 60 | Respawns after destruction |
| Maridia | Evir | 300 | 100 | Projectile-firing foe |
| Maridia | Mochtroid | 100 | 90 | Weak Metroid clone, freezable |
| Tourian | Metroid | 500 | 12/frame | Latches onto Samus, drains energy. Freeze with Ice Beam, then 5 Missiles or 1 Super Missile to kill. Escape with 3 Power Bombs |
| Tourian | Space Pirate | 500 | 15 | Final-area pirate variant |

### 7.2 Bosses

Bosses are unique encounters that guard key progression points or upgrades. All bosses drop items when their projectiles/minions are destroyed.

**Mini-Bosses:**

| Boss | Area | HP | Key Attacks | Weakness / Strategy |
|---|---|---|---|---|
| Bomb Torizo | Crateria | 800 | Arm slash, sonic beam, bomb-like projectiles | Missiles to the chest. Projectiles can be shot for item drops |
| Spore Spawn | Brinstar | 960 | Swinging motion, ceiling spores (4 dmg Power Suit) | Missiles/Supers to exposed core. Core opens periodically. Takes double damage from charged shots. Speeds up as HP drops |
| Crocomire | Norfair | N/A | Charge attack, plasma fireballs | Cannot be killed by damage. Push back by shooting its open mouth until it falls into lava |
| Botwoon | Maridia | 3,000 | Charge attack, green fireballs | Target the head. Moves in serpentine patterns through wall holes |
| Golden Torizo | Lower Norfair | 13,500 | Arm slash, sonic beam, bomb projectiles | Stronger Torizo variant. Super Missiles to the chest. Catches missiles thrown at it and throws them back |

**Main Bosses:**

| Boss | Area | HP | Key Attacks | Weakness / Strategy |
|---|---|---|---|---|
| Kraid | Brinstar | 1,000 | Thorn projectiles from belly, fingernail boomerangs | Missiles or Super Missiles into open mouth. Platform up to be level with his head. Three Super Missiles to the mouth ends the fight quickly |
| Phantoon | Wrecked Ship | 2,500 | Blue flame projectiles, figure-eight flame patterns | Only vulnerable when eye opens briefly. Missiles/Supers to the eye. Using a Super Missile triggers an aggressive flame attack phase |
| Draygon | Maridia | 6,000 | Wall turret shots, grab attack, goop projectiles | Super Missiles to orange belly. **Alternate strategy:** Destroy wall turrets, let Draygon grab Samus, then Grapple Beam the sparking turret wreckage to electrocute Draygon (instant kill) |
| Ridley | Lower Norfair | 18,000 | Fireballs, tail stab, claw grab, swooping charges | Missiles/Supers/Charged Plasma to body. Tail grab drains energy rapidly. Most damaging prolonged fight in the game |

**Final Boss — Mother Brain (three phases):**

| Phase | HP | Key Attacks | Notes |
|---|---|---|---|
| MB1 (Brain in Tank) | 3,000 | Rinkas (energy rings), wall turrets | Destroy the glass tank first, then damage the exposed brain |
| MB2 (Mechanical Body) | 18,000 | Eye laser (120 dmg), energy rings (80 dmg), bombs (160 dmg), red beam (400 dmg), rainbow beam (600 dmg) | After depleting HP, Mother Brain fires the rainbow beam. The baby Metroid intervenes, drains Mother Brain, and transfers energy + the Hyper Beam to Samus before being killed |
| MB3 (Weakened) | 36,000 | Same as MB2 but can be stunlocked | Hyper Beam deals 1,000 per hit; 36 shots to destroy. MB3 can be perma-stunned with continuous fire |

All MB damage values listed are for Power Suit. The rainbow beam ignores Gravity Suit — only Varia Suit provides reduction (halved to 300).

### 7.3 Enemy Drops

Most enemies share a common drop table when destroyed:

| Drop | Probability | Recovery |
|---|---|---|
| Nothing | ~40% | — |
| Small Energy | ~15% | 5 energy |
| Large Energy | ~15% | 20 energy |
| Missiles | ~15% | 2 missiles |
| Super Missiles | ~8% | 1 super missile |
| Power Bombs | ~7% | 1 power bomb |

Drop probabilities vary by enemy. Some enemies have modified tables (e.g., enemies in Tourian have higher energy drop rates). Farming is viable by repeatedly re-entering rooms.

---

## 8. Stations & World Services

| Station Type | Function | Map Symbol |
|---|---|---|
| Save Station | Saves game progress. Does **not** restore health or ammo | S |
| Energy Recharge | Fully restores energy (not ammo). Blue-colored rooms with arm cannon sockets. Not present in the Wrecked Ship | — |
| Missile Recharge | Fully restores Missiles, Super Missiles, and Power Bombs | — |
| Map Station | Reveals the map for the current area (unexplored rooms shown as outlines) | M |
| Gunship | Saves game, fully restores all energy and ammo | Located at the Landing Site in Crateria |

---

## 9. UI & HUD

### 9.1 HUD Layout

The HUD occupies a horizontal bar across the top of the screen (the gameplay area is below, with a thin black border at the top).

**Left section:**
- Energy counter (numerical, e.g., "0087")
- Energy Tank indicators: row of pink squares (full) or gray squares (empty), one per collected tank

**Center section:**
- Currently selected sub-weapon icon and ammo count
- Additional weapon icons appear as they are collected (Missiles, Super Missiles, Power Bombs, Grapple Beam, X-Ray Scope)

**Right section:**
- Mini-map showing Samus's position within the current area grid

### 9.2 HUD States

- **Normal gameplay:** Full HUD visible
- **Low energy alarm:** When energy ≤29, a rapid beeping alarm sounds and the energy counter flashes. This alarm is a key narrative trigger (the baby Metroid recognizes Samus by this sound)
- **Pause screen (Start):** Full area map with collected items marked, room layouts, and station locations
- **Item screen:** Toggle to equipment sub-screen from pause to enable/disable beams, suits, and movement upgrades individually

### 9.3 Map System

Each area has its own map grid. Rooms are color-coded:
- **Pink:** Explored rooms
- **Blue outlines:** Revealed by Map Station but not yet visited
- **Blinking dot:** Samus's current position

Item dots appear on the map for rooms containing uncollected items (visible only after the room has been entered).

---

## 10. Engine & Presentation Systems

### 10.1 Save System

Three save file slots. Progress is saved at Save Stations or the Gunship (§8). Save data records Samus's position, all collected items, defeated bosses, opened doors, and play time. No auto-save or checkpoint system — death returns to last save with all progress since lost.

### 10.2 Difficulty

There is no difficulty selection. The game has a single fixed difficulty. Challenge scales through world design — later areas have more dangerous enemies and more complex navigation.

### 10.3 Camera

The camera follows Samus with smooth scrolling. In large rooms, the camera pans to keep Samus roughly centered. In small rooms (1 screen), the camera is fixed. Doors trigger a screen-transition scroll to the adjacent room. The camera does not reveal rooms ahead of Samus — exploration is blind until a room is entered.

### 10.4 Music System

Each area has a distinct music theme that plays on a loop. Music changes are triggered by:
- Entering a new area (via elevator or transition)
- Boss encounters (unique boss themes)
- Scripted events (Ceres escape, Tourian countdown, ending)
- The Wrecked Ship plays a muted, eerie theme while unpowered; a different theme plays after Phantoon's defeat

The low-energy alarm overlays on top of the current music track.

---

## 11. Open Questions / Unverified

- **Exact enemy drop tables:** Individual enemy drop probabilities exist in the ROM but full verified tables for all ~80 enemy types are only partially documented in public sources. The speedrun wiki covers key enemies.
- **Damage rounding:** The game rounds down fractional damage. Edge cases where Gravity Suit reduces damage to 0 have been observed but the full list of such interactions is not exhaustively documented.
- **Crocomire HP:** Crocomire is defeated by knockback into lava, not by depleting an HP pool. Some sources list a large HP value but the fight mechanic is purely positional — the HP value (if any) doesn't affect gameplay.
- **Phantoon HP:** Community sources report values between 2,500 and 3,000. The 2,500 figure is more commonly cited in speedrun contexts.
- **Golden Torizo HP:** Reported as 13,500 in some sources and 2,700 in others; the discrepancy likely stems from different damage scaling interpretations. The speedrun community uses the larger figure.

---

## 12. References

### Speedrun & Datamined Sources
- [Super Metroid Speedrunning Wiki — Damage](https://wiki.supermetroid.run/Damage)
- [Super Metroid Speedrunning Wiki — Damage Sources](https://wiki.supermetroid.run/Damage_Sources)
- [Super Metroid Speedrunning Wiki — Enemies](https://wiki.supermetroid.run/Enemies)
- [Super Metroid Speedrunning Wiki — Shinespark](https://wiki.supermetroid.run/Shinespark)
- [Super Metroid Speedrunning Wiki — Charge Beam Combos](https://wiki.supermetroid.run/Charge_Beam_Combos)
- [Super Metroid Speedrunning Wiki — Control Schemes](https://wiki.supermetroid.run/Control_Schemes)
- [Super Metroid Speedrunning Wiki — Mother Brain](https://wiki.supermetroid.run/Mother_Brain)
- [Super Metroid Speedrunning Wiki — Spore Spawn](https://wiki.supermetroid.run/Spore_Spawn)

### Community Wikis
- [Wikitroid (Metroid Fandom Wiki)](https://metroid.fandom.com/wiki/)
- [Metroid Wiki (Metroidwiki.org)](https://www.metroidwiki.org/)
- [StrategyWiki — Super Metroid](https://strategywiki.org/wiki/Super_Metroid)

### Guides & Walkthroughs
- [Metroid Recon — Super Metroid](https://metroid.retropixel.net/games/metroid3/)
- [Omega Metroid — Super Metroid Walkthrough](https://omegametroid.com/super-metroid-walkthrough/)
- [GameFAQs — Super Metroid Guides](https://gamefaqs.gamespot.com/snes/588741-super-metroid/faqs)
- [Insectoid — Super Metroid Guide](http://insectoid.budwin.net/nintendo/smtrd/)

### Tools & Calculators
- [Super Metroid Damage Calculator (bearythick.com)](https://bearythick.com/)
- [Metroid Database — Damage Data](https://metroiddatabase.com/wp-content/uploads/Super-Metroid/smdamage.txt)
