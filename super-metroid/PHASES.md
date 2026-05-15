# Super Metroid — Phased Implementation Plan

---

## Phase 1 — Core Movement & Camera

Samus's full movement suite on a test stage, establishing the physics foundation everything else builds on.

- Walking (D-Pad left/right) and running/dashing (hold Dash button for increased speed)
- Variable-height jumping: ~3 tiles full press, shorter taps for shorter jumps
- Spin jump: initiated by jumping while moving horizontally; Samus somersaults. Cannot fire beams during spin (can fire missiles/supers once acquired)
- Crouching: press Down to lower profile, can aim forward and diagonally upward
- Morph Ball: press Down twice from standing (once from crouching) to enter ball form (~1 tile diameter); press Up to exit. Mid-air morph: press Down twice while airborne, horizontal velocity preserved if Jump is held
- Wall Jump: while spin-jumping against a wall, press away then press Jump to kick off. Chainable between two walls or on a single wall with precise timing. Available from the start — no upgrade required
- Gravity and terrain collision: solid tiles, slopes, one-way platforms
- Camera: smooth scrolling in large rooms, Samus roughly centered. Fixed camera in single-screen rooms. Room boundary constraints prevent camera from revealing adjacent rooms

### Assets

**Sprites**
- Samus (Power Suit): walk cycle, run cycle, crouch, stand, spin jump, fall, Morph Ball roll
- Placeholder tileset: solid blocks, slopes, one-way platforms

**Audio**
- Footstep SFX (walk, run — surface-dependent)
- Jump SFX, landing SFX
- Morph Ball transform SFX, Morph Ball roll SFX

---

## Phase 2 — Combat, Enemies & HUD

Real-time combat integrated into movement — beam firing in 8 directions, Missiles, Bombs, the enemy damage/drop framework, and the gameplay HUD.

- Power Beam: fire in 8 directions (left, right, up, diagonal-up-left/right, diagonal-down-left/right, down while airborne). 20 damage uncharged. L/R shoulder buttons for diagonal aiming
- Charge Beam: hold Fire for 2 seconds, release for 3× damage (60). Pseudo Screw Attack aura during charged spin jumps (200 contact damage)
- Missiles: sub-weapon, 100 damage. Cycle selection with Select button. Ammo-limited
- Bombs: Morph Ball only. 3-second fuse, maximum 3 active simultaneously, 30 damage. Explosion propels Morph Ball Samus upward (bomb jump). Sequential bomb placements enable Infinite Bomb Jump for unlimited vertical height
- Cancel Item button (X) to deselect sub-weapon and return to beam
- Enemy framework: HP pool, contact damage to Samus (Power Suit values), invincibility frames on hit, knockback. Enemies respawn when Samus re-enters a room
- Enemy drop system: destroyed enemies randomly drop small energy (5 HP), large energy (20 HP), Missiles (2), Super Missiles (1), or Power Bombs (1). Drop probabilities weighted per enemy type (~40% nothing, ~15% small energy, ~15% large energy, ~15% Missiles, ~8% Super Missiles, ~7% Power Bombs as baseline)
- First enemies: Waver (30 HP, 10 contact damage, swooping), Zeela (30 HP, 10 dmg, crawls along surfaces), Sidehopper (100 HP, 20 dmg, aggressive leaping)
- Damage to Samus: contact damage depletes energy, starting at 99. Death when energy reaches 0
- HUD bar across top of screen:
  - Left: energy counter (numerical, e.g. "0087"), Energy Tank indicators (pink = full, gray = empty)
  - Center: selected sub-weapon icon + ammo count. Icons appear as weapons are collected
  - Right: mini-map stub (placeholder grid)
- Low energy alarm: when energy ≤29, rapid beeping alarm sounds, energy counter flashes

### Assets

**Sprites**
- Samus: aim-up pose, diagonal aim poses, firing animations (standing, crouching, airborne, spin)
- Samus: damage flash, knockback
- Power Beam projectile, Charge Beam projectile (larger), charge-up glow effect
- Missile projectile
- Bomb (placed, fuse, explosion)
- Waver, Zeela, Sidehopper — idle, movement, death animations
- Small energy drop, large energy drop, Missile drop, Super Missile drop, Power Bomb drop

**VFX**
- Beam impact spark
- Missile explosion
- Bomb explosion radius
- Charge Beam glow buildup on arm cannon
- Pseudo Screw Attack aura (charged spin jump)
- Enemy death burst
- Samus damage flash

**Audio**
- Power Beam fire SFX, Charge Beam charge-up SFX, Charge Beam release SFX
- Missile launch SFX
- Bomb place SFX, Bomb explode SFX
- Enemy hit SFX, enemy death SFX
- Samus damage SFX
- Low energy alarm beep (looping)
- Sub-weapon cycle SFX

**UI**
- HUD bar: energy counter, Energy Tank pips, weapon icon slots, ammo counter, mini-map frame

---

## Phase 3.1 — Room Transitions & Doors

The structural backbone of the Metroidvania world — rooms as self-contained areas connected by doors with scrolling transitions.

- Room-based world system: each room is a self-contained scene. Rooms define their own tile layout, collision, camera bounds, and enemy placements
- GameManager tracks current room and handles room transitions
- Door system:
  - Door node placed at room edges with a target room + target door reference
  - Samus enters door → brief entry animation → screen scrolls/fades → new room loads → Samus exits at target door
  - Blue doors: open with any weapon, always re-openable
  - Red doors: 5 Missiles or 1 Super Missile to open, permanently become blue
  - Gray doors: locked until a room condition is met (e.g., all enemies killed). Cannot be opened by weapons
- Door state persistence: opened red doors stay blue across room transitions
- Test with 3–4 connected rooms using placeholder tilesets to validate transitions in all directions

### Assets

**Sprites**
- Door sprites: blue, red, gray (closed and opened states)

**VFX**
- Door transition scroll effect

**Audio**
- Door open SFX, door close SFX

---

## Phase 3.2 — Blocks, Items & Stations

Interactive world elements — destructible blocks, item pickups, and service stations that form the progression loop.

- Block types:
  - Shot Block: cleared by any beam or missile
  - Bomb Block: cleared by Bombs or Power Bombs
  - Crumble Block: collapses shortly after Samus stands on it
- Item acquisition system: Chozo Statue pedestals and freestanding item orbs. Pickup triggers a fanfare, brief animation, and item description overlay
- Collectible items: Energy Tank (+100 energy), Missile Expansion (+5 missiles)
- Item persistence: collected items stay collected across room transitions
- Energy Recharge Station: fully restores energy (not ammo). Blue-colored room with arm cannon sockets
- Test with existing test rooms — place blocks, items, and stations to validate all interactions

### Assets

**Sprites**
- Samus: item acquisition pose
- Chozo Statue (inactive, holding item)
- Block sprites: Shot Block, Bomb Block, Crumble Block (intact, crumbling, gone)
- Energy Tank orb, Missile Expansion orb
- Energy Recharge sockets

**VFX**
- Item acquisition glow/fanfare overlay
- Crumble Block disintegration particles

**Audio**
- Item acquisition fanfare
- Energy Recharge SFX

**UI**
- Item acquisition overlay (item name, brief description)

---

## Phase 3.3 — Crateria & Elevators

The first real level — Crateria area with room layouts, the Gunship, elevators, a new enemy, and area music.

- Elevator transitions between areas (Crateria ↔ Brinstar)
- Gunship at Landing Site: fully restore all energy and ammo (save functionality added in Phase 8)
- Crateria area:
  - Landing Site with Gunship (starting area, rain, rocky surface)
  - Descent through rocky caves
  - Path to Brinstar elevator
  - Energy Recharge Station
  - Missile Expansion and Energy Tank placements (subset)
- Early Brinstar stub: Morph Ball acquisition room (Chozo Statue pedestal)
- New Crateria enemy: Alcoon (200 HP, 50 dmg, slow, high-HP)

### Assets

**Sprites**
- Samus: elevator ride animation
- Alcoon — idle, movement, death animations
- Gunship (exterior, Landing Site)
- Elevator platform

**Tilemaps**
- Crateria tileset: surface terrain (rain-weathered rock, cave walls, metal platforms), interior caves
- Early Brinstar tileset: jungle overgrowth, organic cave walls (stub for Morph Ball room)

**VFX**
- Rain effect (Crateria surface)
- Elevator movement

**Audio**
- Crateria music theme (surface), Crateria music theme (caves)
- Elevator SFX

---

## Phase 3.4 — Bomb Torizo Boss

The first boss fight — a Chozo Statue that comes to life, gating progression with a gray door lock.

- Bomb Torizo arena room in Crateria (Chozo Statue comes to life when Bombs are grabbed)
- Bomb Torizo mini-boss: 800 HP. Attacks: arm slash, sonic beam, bomb-like projectiles. Weakness: Missiles to chest. Projectiles can be shot for item drops
- Gray door lock on arena: doors seal when fight begins, unlock on defeat

### Assets

**Sprites**
- Chozo Statue (Bomb Torizo — active, attack frames)

**Audio**
- Bomb Torizo boss theme
- Chozo Statue activation SFX

---

**Vertical slice checkpoint — Samus explores Crateria and reaches early Brinstar, acquires Morph Ball and Bombs, defeats Bomb Torizo, collects Energy Tanks and Missile Expansions, and navigates blue and red doors. The full explore → acquire → return → progress loop is playable.**

---

## Phase 4 — Brinstar: Beam System, Major Bosses & Inventory

Full Brinstar with all sub-regions, the beam stacking system, Super Missiles, Power Bombs, the first suit upgrade, two bosses, and the pause/map/equipment screens.

- Full Brinstar area: Blue, Green, Pink, Red sub-regions with distinct tilesets
- Beam upgrade system: multiple beams equipped simultaneously, effects and damage stack per the beam combination table. Spazer and Plasma Beam are mutually exclusive (Plasma deferred to Phase 7)
  - Ice Beam: 30 damage, freezes enemies into temporary platforms
  - Wave Beam: 50 damage, projectiles pass through walls and solid terrain. Activates blue gate switches from either side
  - Spazer: 40 damage, fires three parallel beams in a spread pattern
  - Charge Beam pickup (system built in Phase 2, item placed in Brinstar)
- Super Missiles: 300 damage, slower projectile with small blast, slight recoil knockback on Samus. Opens green doors (1 hit → permanent blue)
- Power Bombs: 200 damage, Morph Ball only, screen-wide explosion. Opens yellow doors (1 hit → permanent blue). Can hit twice on large enemies. Reveals hidden passages
- Green doors, yellow doors
- Gate switches: blue (any beam shot), green (1 Super Missile, from switch side only)
- Block types: Missile Block (Missiles/Supers), Super Missile Block (Super Missiles only), Power Bomb Block (Power Bombs only)
- Varia Suit: damage halved (×0.5), immunity to heated rooms, armor color changes to orange
- Super Missile Expansion (+5), Power Bomb Expansion (+5) collectibles
- Reserve Tank collectible (+100 reserve energy). Reserve Tank modes on equipment screen: Auto (dumps all reserve into main energy when main hits 0) and Manual (player activates from pause screen, press Up to stop partial drain). Reserves only charge from energy pickups when all main tanks are full
- Missile Recharge Station: fully restores Missiles, Super Missiles, and Power Bombs
- Map Station: reveals map for current area (unexplored rooms shown as blue outlines). Map symbol: M
- X-Ray Scope: reveals hidden passages, breakable blocks, and items within line of sight. Samus stationary while scanning
- Spore Spawn mini-boss: 960 HP. Swings in figure-8 pattern, spawns ceiling spores (4 damage Power Suit). Core opens periodically — vulnerable to Missiles/Supers. Takes double damage from charged shots. Speeds up as HP drops below thresholds
- Kraid boss: 1,000 HP. Thorn projectiles from belly, fingernail boomerangs. Vulnerability: Missiles or Super Missiles into open mouth. Three Super Missiles to the mouth ends fight quickly. Multi-screen-tall arena
- New enemies: Boyon (1,000 HP, 10 dmg, bouncing blob)
- Pause screen (Start):
  - Full area map: room grid color-coded (pink = explored, blue outline = revealed by Map Station, blinking dot = Samus position). Item dots for rooms with uncollected items (visible after room entered)
  - Equipment sub-screen: toggle individual beams, suits, and movement upgrades on/off. Reserve Tank auto/manual toggle
- Etecoon creatures in Brinstar: in-game Wall Jump tutorial (mechanic available since Phase 1, Etecoons demonstrate the technique to the player)

### Assets

**Sprites**
- Samus (Varia Suit): full sprite set (recolor to orange with bulky shoulders)
- Ice Beam projectile (with freeze impact), Wave Beam projectile (wavy, phase-through), Spazer projectile (triple spread)
- Super Missile projectile (larger, blast effect)
- Power Bomb explosion (screen-wide, expanding ring)
- Spore Spawn (body, swinging vine, core open/closed, ceiling spore pods, mini spores)
- Kraid (multi-screen body, mouth open/closed, belly, fingernail projectiles, thorn projectiles)
- Chozo Statues for beam/suit/item pickups in Brinstar
- Door sprites: green, yellow (closed and opened states)
- Gate switches: blue (inactive/active), green (inactive/active)
- Block sprites: Missile Block, Super Missile Block, Power Bomb Block
- Reserve Tank orb, Super Missile Expansion orb, Power Bomb Expansion orb
- Map Station console, Missile Recharge Station
- X-Ray Scope sweep overlay
- Etecoon creatures (Wall Jump tutorial animation)
- Boyon — idle, movement, death animations

**Tilemaps**
- Brinstar Blue tileset (metallic corridors, blue tones)
- Brinstar Green tileset (dense jungle overgrowth, organic)
- Brinstar Pink tileset (organic caves, pink rock)
- Brinstar Red tileset (red rocky caverns, Kraid's lair)

**VFX**
- Ice Beam freeze effect on enemy (ice encasement, shatter on thaw)
- Wave Beam wall-phase shimmer
- Power Bomb expanding ring explosion
- X-Ray Scope scanning cone/sweep
- Spore Spawn core glow when vulnerable
- Kraid arena screen shake

**Audio**
- Brinstar music theme (Green/jungle), Brinstar music theme (Red/Kraid area)
- Spore Spawn boss theme, Kraid boss theme
- Ice Beam fire SFX, freeze SFX, thaw/shatter SFX
- Wave Beam fire SFX (phasing sound)
- Spazer fire SFX
- Super Missile launch SFX, Super Missile impact SFX
- Power Bomb place SFX, Power Bomb explosion SFX
- Gate switch activation SFX
- Map Station reveal SFX
- X-Ray Scope hum SFX
- Etecoon chirp SFX

**UI**
- Pause screen: area map grid, room color coding, station symbols (S, M), item dots, Samus position marker
- Equipment sub-screen: beam toggles, suit toggles, upgrade toggles, Reserve Tank mode selector
- Super Missile icon, Power Bomb icon, X-Ray Scope icon for HUD weapon slots

---

## Phase 5 — Norfair: Environmental Hazards & Advanced Movement

Upper Norfair introduces environmental damage tiers, the Speed Booster/Shinespark system, the Grapple Beam, and the Crocomire boss — a pushback-only fight with no HP depletion.

- Upper Norfair area (east and west sections, Crocomire section)
- Environmental damage system (damage per 4 frames):
  - Heated rooms: 1 (Power Suit), 0 (Varia), 0 (Gravity). Norfair only — Varia/Gravity grant full immunity
  - Lava (upper): 2 / 1 / 0. Gravity Suit grants immunity
  - Acid: 4 / 2 / 1. Standard suit reduction
  - Spikes (weak): 16 / 8 / 4 per contact
  - Spikes (strong): 60 / 30 / 15 per contact
- Hi-Jump Boots: increases jump height by ~65%
- Speed Booster: after dashing on flat ground for ~36 tiles, Samus enters blue/flashing speed state. Destroys Speed Booster blocks and most enemies on contact
- Speed Booster Block type
- Shinespark: while in Speed Booster state, press Down to store charge. Charge lasts 180 frames (~3 seconds). Press Jump while stationary, then input direction within 28-frame window (frames 2–30):
  - No input / Up: vertical launch
  - Forward: horizontal launch (facing direction)
  - Diagonal (hold Aim-Up before Jump): diagonal launch
  - No downward Shinespark
  - Energy cost: 1 per frame during flight. Minimum 30 energy to activate. 70-frame crash animation on collision
  - Aerial Shinespark: while spin-jumping with stored charge, release Jump → press Up → hold Jump + direction
- Mockball technique: press Down to morph during landing frames of a jump at dash speed. Preserves running speed in Morph Ball form. Enables early sequence breaks (e.g., early Super Missiles in Brinstar without defeating Spore Spawn)
- Grapple Beam: fires electric tether to designated Grapple points. Samus swings from the attachment point. Deals 20 damage to enemies on contact. Grapple Block type
- Crocomire mini-boss: cannot be killed by depleting HP. Push backward by shooting its open mouth with beams/missiles until it falls into lava behind it. Attacks: charge, plasma fireballs
- New enemies: Holtz (900 HP, 120 dmg, diving fire enemy), Kihunter red variant (1,800 HP, 200 dmg, strongest standard enemy)
- Dachora creatures in Norfair teach Shinespark technique (in-game tutorial)

### Assets

**Sprites**
- Samus: Speed Booster run (blue flash overlay), Shinespark launch poses (vertical, horizontal, diagonal), Shinespark crash, Grapple Beam swing animation
- Speed Booster speed-line overlay
- Grapple Beam tether (extending, attached, retracting)
- Grapple point (ceiling anchor)
- Speed Booster Block, Grapple Block
- Crocomire (body, open mouth, recoil frames, lava death sequence, skeletal remains)
- Holtz, Kihunter (red) — idle, attack, movement, death animations
- Dachora creatures (Shinespark tutorial animation)
- Hi-Jump Boots, Speed Booster, Grapple Beam pickup orbs
- Grapple Beam icon for HUD weapon slot

**Tilemaps**
- Norfair Upper tileset: volcanic rock, magma channels, metal grating over lava, heat distortion areas
- Crocomire section tileset: lava pit arena, bridge

**VFX**
- Heat shimmer/distortion in heated rooms
- Lava surface bubbling, lava splash on contact
- Speed Booster afterimage trail
- Shinespark launch flash, flight trail, collision impact burst
- Grapple Beam electricity arc on tether
- Crocomire lava death: skeleton dissolving, dramatic reveal
- Environmental damage flash on Samus (heat/lava/acid tint)

**Audio**
- Upper Norfair music theme
- Crocomire boss theme
- Speed Booster activation SFX (building whoosh), sustained speed SFX
- Shinespark charge store SFX, Shinespark launch SFX, Shinespark collision SFX
- Grapple Beam fire SFX, attach SFX, swing SFX, release SFX
- Lava sizzle SFX, heat damage tick SFX
- Dachora cry SFX

---

## Phase 6 — Wrecked Ship & Maridia: Water, Flight & Two Bosses

The Wrecked Ship's power-state mechanic, Maridia's water physics, Space Jump and Screw Attack for unlimited aerial mobility, Spring Ball, and the Phantoon, Botwoon, and Draygon boss fights.

- Wrecked Ship area: all rooms dark and systems inert (enemies frozen, doors non-functional) until Phantoon is defeated. After Phantoon's death, power is restored — lights on, new enemies active, stations functional
- Phantoon boss: 2,500 HP. Semi-transparent most of fight, phases in briefly. Blue flame projectiles, figure-eight flame patterns. Only vulnerable when eye opens. Hitting Phantoon with a Super Missile triggers an aggressive multi-flame attack phase
- Gravity Suit: damage quartered (×0.25). Free movement underwater and in lava. Protects against upper Norfair lava damage. Armor color changes to purple. Does not stack with Varia — Gravity alone provides ×0.25. Exceptions: Super Metroid energy drain and Mother Brain rainbow beam only receive Varia reduction
- Water physics: without Gravity Suit, drastically reduced movement speed and jump height. Cannot Space Jump or Speed Boost underwater. Gravity Suit removes all water penalties
- Maridia area: underwater caves, sand, quicksand pits (Samus sinks, must morph and bomb-jump or use specific exits)
- Space Jump: chain spin jumps indefinitely by pressing Jump at the apex of each spin. Unlimited vertical and horizontal flight
- Screw Attack: spin jumps deal 2,000 damage per frame and destroy Screw Attack blocks. Combined with Space Jump, Samus becomes a flying weapon that destroys most enemies on contact
- Screw Attack Block type
- Spring Ball: jump while in Morph Ball form. Jump height matches bipedal jump (affected by Hi-Jump Boots)
- Botwoon mini-boss: 3,000 HP. Moves in serpentine patterns through wall holes. Charge attack, green fireballs. Target the head for damage
- Draygon boss: 6,000 HP. Wall turret shots, grab attack (pins Samus), goop projectiles. Vulnerability: Super Missiles to orange belly. Alternate strategy: destroy wall turrets, let Draygon grab Samus, then fire Grapple Beam at sparking turret wreckage to electrocute Draygon (instant kill)
- New enemies: Atomic (250 HP, 40 dmg, ghostly orb), Covern (300 HP, 60 dmg, respawns after destruction), Evir (300 HP, 100 dmg, projectile-firing), Mochtroid (100 HP, 90 dmg, weak Metroid clone, freezable with Ice Beam)
- Reserve Tank placements in Wrecked Ship and Maridia

### Assets

**Sprites**
- Samus (Gravity Suit): full sprite set (recolor to purple)
- Samus: Space Jump chain animation, Screw Attack spin (energy crackling overlay), Spring Ball jump
- Samus: underwater movement variants (sluggish without Gravity Suit, normal with)
- Phantoon (body, eye open/closed, phase-in/out transparency, flame projectiles)
- Botwoon (serpentine body segments, head, green fireballs)
- Draygon (body, orange belly, grab animation, goop projectiles, wall turrets, sparking turret wreckage)
- Atomic, Covern, Evir, Mochtroid — idle, movement, attack, death animations
- Screw Attack Block
- Space Jump, Screw Attack, Spring Ball, Gravity Suit pickup orbs

**Tilemaps**
- Wrecked Ship tileset: derelict metal corridors, broken consoles (unpowered variant: dark, inert; powered variant: lit, active displays)
- Maridia tileset: underwater rock, coral, sand floors, quicksand pits, glass tube corridors

**VFX**
- Wrecked Ship power-on transition: lights flickering on, consoles activating
- Water surface refraction, underwater ambient particles
- Quicksand sinking effect
- Space Jump spin trail
- Screw Attack electric crackling aura
- Draygon electrocution via Grapple Beam (sparks, flash)
- Phantoon phase-in/out transparency effect, flame trail patterns

**Audio**
- Wrecked Ship music (unpowered — muted, eerie), Wrecked Ship music (powered — restored)
- Maridia music theme
- Phantoon boss theme, Botwoon boss theme (or shared mini-boss theme), Draygon boss theme
- Space Jump chain SFX
- Screw Attack buzz/crackle SFX
- Spring Ball bounce SFX
- Water entry SFX, water exit SFX, underwater ambient loop
- Quicksand sinking SFX
- Phantoon eye-open SFX, Phantoon flame burst SFX
- Draygon grab SFX, Draygon electrocution SFX
- Mochtroid latch SFX

---

## Phase 7 — Lower Norfair & Tourian: Endgame

Plasma Beam completes the beam system, Ridley caps the four main bosses, the boss gate opens Tourian, and the Mother Brain three-phase finale plays out with the baby Metroid narrative climax.

- Lower Norfair area: extreme heat and lava (8 / 4 / 2 damage per 4 frames for Power/Varia/Gravity — always damages even with Gravity Suit)
- Plasma Beam: 150 damage uncharged, 450 charged. Projectiles pierce through enemies, hitting multiple targets in a line. Mutually exclusive with Spazer — only one can be active. Completes the full beam combination damage table (Ice + Wave + Plasma = 300 uncharged, 900 charged)
- Charge Beam Combos (special attacks): with Charge Beam + one other beam + Power Bombs selected, charge for 120 frames (~2 seconds). Consumes 1 Power Bomb. Only one non-Charge beam may be active:
  - Ice Shield: 4 ice crystals orbit Samus, freeze on contact (90 dmg per particle)
  - Wave Shield (X-Factor): 4 purple spheres in X-pattern stationary, wave orbit when moving (300 dmg per particle)
  - Spazer Shield: 2 three-pronged projectiles rain downward (300 dmg per particle)
  - Plasma Shield: 4 large green rings orbit Samus, pierce through enemies (300 dmg per particle)
- Crystal Flash: secret emergency heal. Requirements: ≤50 energy, empty Reserve Tanks, ≥10 Missiles, ≥10 Super Missiles, ≥11 Power Bombs. Activation: Morph Ball, Power Bombs selected, hold L + R + Down + Fire at detonation position with zero vertical speed. Consumes 10M + 10SM + 10PB. Fully restores Energy Tanks, fills Reserve to 230. Samus is not invincible during animation
- Golden Torizo mini-boss: 13,500 HP. Arm slash, sonic beam, bomb projectiles. Catches thrown missiles and throws them back. Super Missiles to chest
- Ridley boss: 18,000 HP. Fireballs, tail stab, claw grab (drains energy rapidly), swooping charges. Missiles/Supers/Charged Plasma to body. Most damaging prolonged fight in the game
- Boss gate system: 4 Chozo statues in Crateria. Defeating Kraid, Phantoon, Draygon, and Ridley activates each statue. All four statues active opens the path to Tourian
- Tourian area: linear gauntlet through Space Pirate command center
- Eye Doors: organic barriers in Tourian. Shoot eye with Missiles/Supers to open. Close permanently behind Samus (one-way progression)
- Metroid enemy: 500 HP, 12 damage per frame (latches onto Samus, drains energy continuously). Freeze with Ice Beam, then 5 Missiles or 1 Super Missile to kill. Escape grab with 3 Power Bombs
- Tourian Space Pirate: 500 HP, 15 contact damage
- Mother Brain Phase 1 (Brain in Tank): 3,000 HP. Rinkas (energy rings), wall turrets. Destroy glass tank first, then damage exposed brain
- Mother Brain Phase 2 (Mechanical Body): 18,000 HP. Eye laser (120 dmg), energy rings (80 dmg), bombs (160 dmg), red beam (400 dmg), rainbow beam (600 dmg). Rainbow beam ignores Gravity Suit — only Varia Suit halves it to 300. After HP depleted, Mother Brain fires rainbow beam
- Baby Metroid scripted sequence: baby Metroid intervenes, drains Mother Brain, transfers energy and the Hyper Beam to Samus, then is killed by Mother Brain
- Mother Brain Phase 3 (Weakened): 36,000 HP. Same attacks as MB2 but can be stunlocked with continuous fire
- Hyper Beam: 1,000 damage per shot, 36 hits to destroy MB3. Cannot be toggled or unequipped. Available only during MB3 fight and escape sequence
- Tourian skeletal remains and environmental storytelling details

### Assets

**Sprites**
- Plasma Beam projectile (piercing, green)
- Charge Beam Combo particles: Ice Shield crystals, Wave Shield spheres, Spazer Shield pronged projectiles, Plasma Shield rings
- Crystal Flash animation (Samus rising in light sphere, suitless silhouette)
- Golden Torizo (active, attack frames, missile-catch animation, color fade as HP drops)
- Ridley (full body, fireballs, tail stab, claw grab, swooping flight, pogo tail)
- 4 Chozo statues in Crateria (inactive, one-by-one activation glow)
- Eye Door (closed with eye, eye hit reaction, open, sealing shut behind)
- Metroid (floating, latching onto Samus, freeze state, death shatter)
- Tourian Space Pirate (standing, attacking, death)
- Mother Brain Phase 1: brain in glass tank, glass shattering stages, Rinkas, wall turrets
- Mother Brain Phase 2: mechanical body (T-Rex form), eye laser, energy rings, bomb projectiles, red beam, rainbow beam
- Mother Brain Phase 3: weakened body, Hyper Beam stun reaction
- Baby Metroid (floating, latching onto MB, energy transfer to Samus, death)
- Hyper Beam projectile (massive, rainbow-colored)
- Plasma Beam, Hyper Beam pickup effect (auto-acquired)

**Tilemaps**
- Lower Norfair tileset: extreme volcanic, intense lava pools, ancient Chozo architecture
- Tourian tileset: Space Pirate command center, metal corridors, organic Metroid containment tubes, Mother Brain arena

**VFX**
- Plasma Beam pierce-through trail
- Charge Beam Combo orbital particle effects (per combo type)
- Crystal Flash light sphere, energy restoration cascade
- Golden Torizo missile-catch flash
- Ridley fire breath cone, tail grab energy drain sparks
- Chozo statue activation glow (sequential)
- Metroid latch energy drain visual (Samus flashing, energy stream)
- Mother Brain glass tank shattering (progressive cracks)
- Mother Brain rainbow beam (screen-filling, color-cycling)
- Baby Metroid energy transfer beam (Metroid → Samus)
- Hyper Beam impact (massive explosion, screen flash)

**Audio**
- Lower Norfair music theme
- Tourian music theme
- Ridley boss theme, Mother Brain boss theme
- Plasma Beam fire SFX
- Charge Beam Combo activation SFX (per combo type)
- Crystal Flash activation SFX, energy restore SFX
- Ridley screech SFX, tail grab SFX, fireball SFX
- Chozo statue activation rumble SFX
- Metroid screech SFX, Metroid latch SFX, Metroid freeze-shatter SFX
- Mother Brain glass shatter SFX, Rinka SFX
- Mother Brain eye laser SFX, rainbow beam SFX, red beam SFX
- Baby Metroid cry SFX, energy transfer SFX, baby Metroid death SFX
- Hyper Beam fire SFX, Hyper Beam impact SFX

**UI**
- Mother Brain Phase 2/3 health bar or damage feedback indicator

---

## Phase 8 — Ceres Prologue, Escape, Menus & Content Completion

The Ceres Station prologue, the Zebes escape sequence, time-based endings, all menus/screens, and full placement of all 100 items across the world.

- Space Colony Ceres prologue area: dead researchers, baby Metroid container room, atmospheric derelict corridors
- Opening narration text (story setup: last Metroid, Ceres research, Ridley's attack)
- Ceres Ridley encounter: unwinnable fight (18,000 HP, station self-destructs before enough damage can be dealt). 1-minute self-destruct countdown triggers after brief engagement
- Ceres escape: Samus runs back to ship as station collapses
- 3-minute Zebes escape sequence (after Mother Brain Phase 3):
  - Escape route: Tourian → Crateria → Gunship
  - Screen shakes periodically
  - Previously locked gray doors are open
  - Hidden path to Etecoons and Dachoras room — optional rescue, acknowledged in ending (seen flying away from Zebes)
  - Timer expires: Samus dies, return to title screen
- Ending system (time-based ending images):
  - ≥10 hours: Samus in full suit, helmet on
  - 3–10 hours: Samus removes helmet
  - <3 hours: Samus in civilian clothes
  - Item collection percentage displayed on ending screen
- Title screen
- Save system: Save Station saves game progress (does not restore health or ammo). Map symbol: S. Save data records: Samus's position, all collected items, defeated bosses, opened doors, and play time. Gunship also saves (in addition to full restore). Save Stations placed in Crateria and all subsequent areas
- File select screen: 3 save file slots, item percentage, play time per file
- Controller remapping screen (Controller Setting Mode): all face/shoulder buttons remappable. D-Pad and Start fixed. Aim Diagonal Up/Down can only bind to L or R
- Game Over screen
- Full placement of all 100 items across all areas:
  - 46 Missile Expansions (230 max)
  - 10 Super Missile Expansions (50 max)
  - 10 Power Bomb Expansions (50 max)
  - 14 Energy Tanks (1,499 max energy)
  - 4 Reserve Tanks (400 max reserve): 1 each in Brinstar, Norfair, Wrecked Ship, Maridia
  - 16 unique equipment items placed per spec locations
- Item percentage tracking on file select screen (X/100 items)
- Wrecked Ship: full room-by-room power-on state transitions (Phase 6 introduced the mechanic, this phase ensures all rooms have proper unpowered/powered variants)
- Remaining enemies not introduced in earlier phases: Fireflea (Norfair), Beetom (Brinstar, damages every 64 frames), Cacatac (Brinstar), Mini-Kraid (Brinstar, 400 HP), Shaktool (Maridia, 300 HP)
- Sequence break validation: Wall Jump height accessibility, Mockball routes through Brinstar, Infinite Bomb Jump paths, early Super Missile routes
- Full area music coverage: ensure all 6 main areas + Ceres + Tourian have distinct themes with proper transition triggers (elevator, door, boss encounter, scripted event)
- Music system: area themes loop, boss themes override, Wrecked Ship switches from unpowered to powered theme after Phantoon, low energy alarm overlays on current track

### Assets

**Sprites**
- Ceres Station: dead researchers, baby Metroid in containment capsule, Ceres Ridley (reuse Ridley sprites from Phase 7)
- Samus: ending images (full suit, helmet removal, civilian clothes)
- Etecoon and Dachora escape sprites (fleeing Zebes in ending)
- Fireflea, Beetom, Cacatac, Mini-Kraid, Shaktool — idle, movement, attack, death animations
- Title screen logo
- Save Station console
- File select screen elements (save slot frames, percentage display)
- Game Over text/screen

**Tilemaps**
- Ceres Station tileset: space station corridors, research labs, containment room, collapsing hallways

**VFX**
- Ceres Station collapse effects (falling debris, explosions, flickering lights)
- Zebes escape: screen shake, background explosions, crumbling terrain
- Zebes destruction (ending cutscene: planet exploding)
- Ending reveal transitions

**Audio**
- Ceres Station music theme
- Ceres escape countdown music
- Zebes escape countdown music (3-minute timer)
- Ending theme / credits music
- Title screen music
- Countdown timer tick SFX
- Explosion SFX (Ceres, Zebes destruction)
- Save Station SFX
- File select cursor SFX
- Game Over SFX

**UI**
- Save confirmation prompt
