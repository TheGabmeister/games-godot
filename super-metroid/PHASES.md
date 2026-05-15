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
- Test with 3-4 connected rooms using placeholder tilesets to validate transitions in all directions

### Assets

**Sprites**
- Door sprites: blue, red, gray (closed and opened states)

**VFX**
- Door transition scroll effect

**Audio**
- Door open SFX, door close SFX

---

## Phase 3.2 — World Infrastructure

All interactive world elements beyond doors — destructible blocks, the item acquisition system, service stations, and elevators. Tested in debug rooms.

- Block types:
  - Shot Block: cleared by any beam or missile
  - Bomb Block: cleared by Bombs or Power Bombs
  - Crumble Block: collapses shortly after Samus stands on it
  - Missile Block: cleared by Missiles or Super Missiles
- Item acquisition system: Chozo Statue pedestals and freestanding item orbs. Pickup triggers a fanfare, brief animation, and item description overlay
- Collectible items: Energy Tank (+100 energy), Missile Expansion (+5 missiles)
- Item persistence: collected items stay collected across room transitions
- Elevator transitions between areas
- Gate switches: blue (any beam shot toggles)
- Energy Recharge Station: fully restores energy (not ammo). Blue-colored room with arm cannon sockets
- Test all blocks, items, stations, and elevators in debug rooms

### Assets

**Sprites**
- Samus: item acquisition pose, elevator ride animation
- Chozo Statue (inactive, holding item)
- Block sprites: Shot Block, Bomb Block, Crumble Block (intact, crumbling, gone), Missile Block
- Energy Tank orb, Missile Expansion orb
- Energy Recharge sockets
- Gate switches: blue (inactive/active)
- Elevator platform

**VFX**
- Item acquisition glow/fanfare overlay
- Crumble Block disintegration particles
- Elevator movement

**Audio**
- Item acquisition fanfare
- Energy Recharge SFX
- Elevator SFX
- Gate switch activation SFX

**UI**
- Item acquisition overlay (item name, brief description)

---

## Phase 4 — Weapons, Suits & Equipment

The full beam upgrade system, heavy ordnance, suit upgrades, and charge combos — everything that expands Samus's combat arsenal. Tested in debug rooms with target enemies.

- Beam upgrade system: multiple beams equipped simultaneously, effects and damage stack per the beam combination table. Spazer and Plasma Beam are mutually exclusive
  - Ice Beam: 30 damage, freezes enemies into temporary platforms
  - Wave Beam: 50 damage, projectiles pass through walls and solid terrain. Activates blue gate switches from either side
  - Spazer: 40 damage, fires three parallel beams in a spread pattern
  - Plasma Beam: 150 damage uncharged, 450 charged. Projectiles pierce through enemies, hitting multiple targets in a line. Completes the full beam combination damage table (Ice + Wave + Plasma = 300 uncharged, 900 charged)
  - Charge Beam pickup (system built in Phase 2, item placed now)
- Charge Beam Combos (special attacks): with Charge Beam + one other beam + Power Bombs selected, charge for 120 frames (~2 seconds). Consumes 1 Power Bomb. Only one non-Charge beam may be active:
  - Ice Shield: 4 ice crystals orbit Samus, freeze on contact (90 dmg per particle)
  - Wave Shield (X-Factor): 4 purple spheres in X-pattern stationary, wave orbit when moving (300 dmg per particle)
  - Spazer Shield: 2 three-pronged projectiles rain downward (300 dmg per particle)
  - Plasma Shield: 4 large green rings orbit Samus, pierce through enemies (300 dmg per particle)
- Super Missiles: 300 damage, slower projectile with small blast, slight recoil knockback on Samus
- Power Bombs: 200 damage, Morph Ball only, screen-wide explosion. Can hit twice on large enemies. Reveals hidden passages
- Green doors: 1 Super Missile to open, permanently become blue
- Yellow doors: 1 Power Bomb to open, permanently become blue
- Green gate switches: 1 Super Missile, from switch side only
- Super Missile Block: cleared only by Super Missiles
- Power Bomb Block: cleared only by Power Bombs
- Varia Suit: damage halved (×0.5), immunity to heated rooms, armor color changes to orange
- Gravity Suit: damage quartered (×0.25). Free movement underwater and in lava. Protects against upper Norfair lava damage. Armor color changes to purple. Does not stack with Varia — Gravity alone provides ×0.25. Exceptions: Super Metroid energy drain and Mother Brain rainbow beam only receive Varia reduction
- X-Ray Scope: reveals hidden passages, breakable blocks, and items within line of sight. Samus stationary while scanning
- Crystal Flash: secret emergency heal. Requirements: ≤50 energy, empty Reserve Tanks, ≥10 Missiles, ≥10 Super Missiles, ≥11 Power Bombs. Activation: Morph Ball, Power Bombs selected, hold L + R + Down + Fire at detonation position with zero vertical speed. Consumes 10M + 10SM + 10PB. Fully restores Energy Tanks, fills Reserve to 230. Samus is not invincible during animation
- Super Missile Expansion (+5), Power Bomb Expansion (+5) collectibles
- Reserve Tank collectible (+100 reserve energy). Reserve Tank modes on equipment screen: Auto (dumps all reserve into main energy when main hits 0) and Manual (player activates from pause screen, press Up to stop partial drain). Reserves only charge from energy pickups when all main tanks are full
- Missile Recharge Station: fully restores Missiles, Super Missiles, and Power Bombs
- Test all weapons, suits, and equipment in debug rooms against target enemies

### Assets

**Sprites**
- Samus (Varia Suit): full sprite set (recolor to orange with bulky shoulders)
- Samus (Gravity Suit): full sprite set (recolor to purple)
- Ice Beam projectile (with freeze impact), Wave Beam projectile (wavy, phase-through), Spazer projectile (triple spread), Plasma Beam projectile (piercing, green)
- Charge Beam Combo particles: Ice Shield crystals, Wave Shield spheres, Spazer Shield pronged projectiles, Plasma Shield rings
- Super Missile projectile (larger, blast effect)
- Power Bomb explosion (screen-wide, expanding ring)
- Crystal Flash animation (Samus rising in light sphere, suitless silhouette)
- Door sprites: green, yellow (closed and opened states)
- Gate switches: green (inactive/active)
- Block sprites: Super Missile Block, Power Bomb Block
- Reserve Tank orb, Super Missile Expansion orb, Power Bomb Expansion orb
- Missile Recharge Station
- X-Ray Scope sweep overlay
- Chozo Statues for beam/suit/item pickups

**VFX**
- Ice Beam freeze effect on enemy (ice encasement, shatter on thaw)
- Wave Beam wall-phase shimmer
- Plasma Beam pierce-through trail
- Power Bomb expanding ring explosion
- Charge Beam Combo orbital particle effects (per combo type)
- Crystal Flash light sphere, energy restoration cascade
- X-Ray Scope scanning cone/sweep

**Audio**
- Ice Beam fire SFX, freeze SFX, thaw/shatter SFX
- Wave Beam fire SFX (phasing sound)
- Spazer fire SFX
- Plasma Beam fire SFX
- Charge Beam Combo activation SFX (per combo type)
- Super Missile launch SFX, Super Missile impact SFX
- Power Bomb place SFX, Power Bomb explosion SFX
- Crystal Flash activation SFX, energy restore SFX
- Gate switch activation SFX
- X-Ray Scope hum SFX

**UI**
- Super Missile icon, Power Bomb icon, X-Ray Scope icon for HUD weapon slots

---

## Phase 5 — Movement & Environment

All movement upgrades from Hi-Jump Boots through Space Jump, plus environmental hazard systems — heat, lava, acid, water physics, and quicksand. Tested in purpose-built debug rooms.

- Hi-Jump Boots: increases jump height by ~65%
- Speed Booster: after dashing on flat ground for ~36 tiles, Samus enters blue/flashing speed state. Destroys Speed Booster blocks and most enemies on contact
- Speed Booster Block type
- Shinespark: while in Speed Booster state, press Down to store charge. Charge lasts 180 frames (~3 seconds). Press Jump while stationary, then input direction within 28-frame window (frames 2-30):
  - No input / Up: vertical launch
  - Forward: horizontal launch (facing direction)
  - Diagonal (hold Aim-Up before Jump): diagonal launch
  - No downward Shinespark
  - Energy cost: 1 per frame during flight. Minimum 30 energy to activate. 70-frame crash animation on collision
  - Aerial Shinespark: while spin-jumping with stored charge, release Jump → press Up → hold Jump + direction
- Mockball technique: press Down to morph during landing frames of a jump at dash speed. Preserves running speed in Morph Ball form. Enables early sequence breaks
- Grapple Beam: fires electric tether to designated Grapple points. Samus swings from the attachment point. Deals 20 damage to enemies on contact
- Grapple Block type
- Space Jump: chain spin jumps indefinitely by pressing Jump at the apex of each spin. Unlimited vertical and horizontal flight
- Screw Attack: spin jumps deal 2,000 damage per frame and destroy Screw Attack blocks. Combined with Space Jump, Samus becomes a flying weapon that destroys most enemies on contact
- Screw Attack Block type
- Spring Ball: jump while in Morph Ball form. Jump height matches bipedal jump (affected by Hi-Jump Boots)
- Environmental damage system (damage per 4 frames):
  - Heated rooms: 1 (Power Suit), 0 (Varia), 0 (Gravity). Norfair only — Varia/Gravity grant full immunity
  - Lava (upper): 2 / 1 / 0. Gravity Suit grants immunity
  - Lava (lower Norfair extreme): 8 / 4 / 2. Always damages even with Gravity Suit
  - Acid: 4 / 2 / 1. Standard suit reduction
  - Spikes (weak): 16 / 8 / 4 per contact
  - Spikes (strong): 60 / 30 / 15 per contact
- Water physics: without Gravity Suit, drastically reduced movement speed and jump height. Cannot Space Jump or Speed Boost underwater. Gravity Suit removes all water penalties
- Quicksand: Samus sinks, must morph and bomb-jump or use specific exits
- Test all movement upgrades and environmental systems in debug rooms

### Assets

**Sprites**
- Samus: Speed Booster run (blue flash overlay), Shinespark launch poses (vertical, horizontal, diagonal), Shinespark crash
- Samus: Grapple Beam swing animation
- Samus: Space Jump chain animation, Screw Attack spin (energy crackling overlay), Spring Ball jump
- Samus: underwater movement variants (sluggish without Gravity Suit, normal with)
- Speed Booster speed-line overlay
- Grapple Beam tether (extending, attached, retracting)
- Grapple point (ceiling anchor)
- Speed Booster Block, Grapple Block, Screw Attack Block
- Hi-Jump Boots, Speed Booster, Grapple Beam, Space Jump, Screw Attack, Spring Ball pickup orbs
- Grapple Beam icon for HUD weapon slot

**VFX**
- Speed Booster afterimage trail
- Shinespark launch flash, flight trail, collision impact burst
- Grapple Beam electricity arc on tether
- Space Jump spin trail
- Screw Attack electric crackling aura
- Heat shimmer/distortion in heated rooms
- Lava surface bubbling, lava splash on contact
- Water surface refraction, underwater ambient particles
- Quicksand sinking effect
- Environmental damage flash on Samus (heat/lava/acid tint)

**Audio**
- Speed Booster activation SFX (building whoosh), sustained speed SFX
- Shinespark charge store SFX, Shinespark launch SFX, Shinespark collision SFX
- Grapple Beam fire SFX, attach SFX, swing SFX, release SFX
- Space Jump chain SFX
- Screw Attack buzz/crackle SFX
- Spring Ball bounce SFX
- Lava sizzle SFX, heat damage tick SFX
- Water entry SFX, water exit SFX, underwater ambient loop
- Quicksand sinking SFX

---

## Phase 6 — Enemies, Bosses & UI

All remaining enemies and boss fights built in test arenas, plus the pause/map/equipment screens, the boss gate system, and the Mother Brain finale sequence.

- All remaining enemies: Alcoon (200 HP, 50 dmg, slow, high-HP), Boyon (1,000 HP, 10 dmg, bouncing blob), Holtz (900 HP, 120 dmg, diving fire enemy), Kihunter red variant (1,800 HP, 200 dmg, strongest standard enemy), Atomic (250 HP, 40 dmg, ghostly orb), Covern (300 HP, 60 dmg, respawns after destruction), Evir (300 HP, 100 dmg, projectile-firing), Mochtroid (100 HP, 90 dmg, weak Metroid clone, freezable with Ice Beam), Metroid (500 HP, 12 dmg per frame, latches and drains — freeze with Ice Beam then 5 Missiles or 1 Super Missile to kill, escape grab with 3 Power Bombs), Tourian Space Pirate (500 HP, 15 dmg), Fireflea (ambient), Beetom (damages every 64 frames), Cacatac (stationary, projectile), Mini-Kraid (400 HP), Shaktool (300 HP, digging)
- Bomb Torizo mini-boss: 800 HP. Arm slash, sonic beam, bomb-like projectiles. Weakness: Missiles to chest. Projectiles can be shot for item drops. Gray door lock on arena: doors seal when fight begins, unlock on defeat
- Spore Spawn mini-boss: 960 HP. Swings in figure-8 pattern, spawns ceiling spores (4 damage Power Suit). Core opens periodically — vulnerable to Missiles/Supers. Takes double damage from charged shots. Speeds up as HP drops below thresholds
- Kraid boss: 1,000 HP. Thorn projectiles from belly, fingernail boomerangs. Vulnerability: Missiles or Super Missiles into open mouth. Three Super Missiles to the mouth ends fight quickly. Multi-screen-tall arena
- Crocomire mini-boss: cannot be killed by depleting HP. Push backward by shooting its open mouth with beams/missiles until it falls into lava behind it. Attacks: charge, plasma fireballs
- Phantoon boss: 2,500 HP. Semi-transparent most of fight, phases in briefly. Blue flame projectiles, figure-eight flame patterns. Only vulnerable when eye opens. Hitting Phantoon with a Super Missile triggers an aggressive multi-flame attack phase
- Botwoon mini-boss: 3,000 HP. Moves in serpentine patterns through wall holes. Charge attack, green fireballs. Target the head for damage
- Draygon boss: 6,000 HP. Wall turret shots, grab attack (pins Samus), goop projectiles. Vulnerability: Super Missiles to orange belly. Alternate strategy: destroy wall turrets, let Draygon grab Samus, then fire Grapple Beam at sparking turret wreckage to electrocute Draygon (instant kill)
- Golden Torizo mini-boss: 13,500 HP. Arm slash, sonic beam, bomb projectiles. Catches thrown missiles and throws them back. Super Missiles to chest
- Ridley boss: 18,000 HP. Fireballs, tail stab, claw grab (drains energy rapidly), swooping charges. Missiles/Supers/Charged Plasma to body. Most damaging prolonged fight in the game
- Mother Brain Phase 1 (Brain in Tank): 3,000 HP. Rinkas (energy rings), wall turrets. Destroy glass tank first, then damage exposed brain
- Mother Brain Phase 2 (Mechanical Body): 18,000 HP. Eye laser (120 dmg), energy rings (80 dmg), bombs (160 dmg), red beam (400 dmg), rainbow beam (600 dmg). Rainbow beam ignores Gravity Suit — only Varia Suit halves it to 300. After HP depleted, Mother Brain fires rainbow beam
- Baby Metroid scripted sequence: baby Metroid intervenes, drains Mother Brain, transfers energy and the Hyper Beam to Samus, then is killed by Mother Brain
- Mother Brain Phase 3 (Weakened): 36,000 HP. Same attacks as MB2 but can be stunlocked with continuous fire
- Hyper Beam: 1,000 damage per shot, 36 hits to destroy MB3. Cannot be toggled or unequipped. Available only during MB3 fight and escape sequence
- Boss gate system: 4 Chozo statues track defeat of Kraid, Phantoon, Draygon, and Ridley. All four defeated opens the path to Tourian
- Eye Doors: organic barriers, shoot eye with Missiles/Supers to open. Close permanently behind Samus (one-way progression)
- Wrecked Ship power-state mechanic: rooms have unpowered (dark, inert) and powered (lit, active) variants. Defeating Phantoon restores power
- Pause screen (Start):
  - Full area map: room grid color-coded (pink = explored, blue outline = revealed by Map Station, blinking dot = Samus position). Item dots for rooms with uncollected items (visible after room entered). Station symbols (S, M)
  - Equipment sub-screen: toggle individual beams, suits, and movement upgrades on/off. Reserve Tank auto/manual toggle
- Map Station: reveals map for current area (unexplored rooms shown as blue outlines). Map symbol: M
- Test all enemies and bosses in purpose-built debug arenas

### Assets

**Sprites**
- All enemies: Alcoon, Boyon, Holtz, Kihunter (red), Atomic, Covern, Evir, Mochtroid, Metroid, Tourian Space Pirate, Fireflea, Beetom, Cacatac, Mini-Kraid, Shaktool — idle, movement, attack, death animations
- Chozo Statue (Bomb Torizo — active, attack frames)
- Spore Spawn (body, swinging vine, core open/closed, ceiling spore pods, mini spores)
- Kraid (multi-screen body, mouth open/closed, belly, fingernail projectiles, thorn projectiles)
- Crocomire (body, open mouth, recoil frames, lava death sequence, skeletal remains)
- Phantoon (body, eye open/closed, phase-in/out transparency, flame projectiles)
- Botwoon (serpentine body segments, head, green fireballs)
- Draygon (body, orange belly, grab animation, goop projectiles, wall turrets, sparking turret wreckage)
- Golden Torizo (active, attack frames, missile-catch animation, color fade as HP drops)
- Ridley (full body, fireballs, tail stab, claw grab, swooping flight, pogo tail)
- Mother Brain Phase 1: brain in glass tank, glass shattering stages, Rinkas, wall turrets
- Mother Brain Phase 2: mechanical body (T-Rex form), eye laser, energy rings, bomb projectiles, red beam, rainbow beam
- Mother Brain Phase 3: weakened body, Hyper Beam stun reaction
- Baby Metroid (floating, latching onto MB, energy transfer to Samus, death)
- Metroid (floating, latching onto Samus, freeze state, death shatter)
- Hyper Beam projectile (massive, rainbow-colored)
- Eye Door (closed with eye, eye hit reaction, open, sealing shut behind)
- 4 Chozo statues (inactive, one-by-one activation glow)
- Map Station console

**VFX**
- Spore Spawn core glow when vulnerable
- Kraid arena screen shake
- Crocomire lava death: skeleton dissolving, dramatic reveal
- Phantoon phase-in/out transparency effect, flame trail patterns
- Draygon electrocution via Grapple Beam (sparks, flash)
- Golden Torizo missile-catch flash
- Ridley fire breath cone, tail grab energy drain sparks
- Metroid latch energy drain visual (Samus flashing, energy stream)
- Mother Brain glass tank shattering (progressive cracks)
- Mother Brain rainbow beam (screen-filling, color-cycling)
- Baby Metroid energy transfer beam (Metroid → Samus)
- Hyper Beam impact (massive explosion, screen flash)
- Wrecked Ship power-on transition: lights flickering on, consoles activating
- Chozo statue activation glow (sequential)

**Audio**
- Bomb Torizo boss theme, Chozo Statue activation SFX
- Spore Spawn boss theme
- Kraid boss theme
- Crocomire boss theme
- Phantoon boss theme, Phantoon eye-open SFX, Phantoon flame burst SFX
- Botwoon boss theme (or shared mini-boss theme)
- Draygon boss theme, Draygon grab SFX, Draygon electrocution SFX
- Ridley boss theme, Ridley screech SFX, tail grab SFX, fireball SFX
- Mother Brain boss theme, glass shatter SFX, Rinka SFX, eye laser SFX, rainbow beam SFX, red beam SFX
- Baby Metroid cry SFX, energy transfer SFX, baby Metroid death SFX
- Hyper Beam fire SFX, Hyper Beam impact SFX
- Metroid screech SFX, Metroid latch SFX, Metroid freeze-shatter SFX
- Mochtroid latch SFX
- Chozo statue activation rumble SFX
- Map Station reveal SFX

**UI**
- Pause screen: area map grid, room color coding, station symbols (S, M), item dots, Samus position marker
- Equipment sub-screen: beam toggles, suit toggles, upgrade toggles, Reserve Tank mode selector
- Mother Brain Phase 2/3 health bar or damage feedback indicator

---

**Systems complete checkpoint — all of Samus's weapons, movement upgrades, suits, and equipment are functional. All enemies and bosses are battle-tested in debug arenas. The pause/map/equipment screens are operational. Ready to build the world.**

---

## Phase 7 — World Construction

All game areas built with real tilesets, room layouts, item placements, enemy placements, and area music. Boss arenas placed in their final locations. The Gunship, tutorial creatures, and narrative elements are integrated.

- Crateria area:
  - Landing Site with Gunship (starting area, rain, rocky surface). Gunship fully restores all energy and ammo (save functionality added in Phase 8)
  - Descent through rocky caves
  - Path to Brinstar elevator
  - Bomb Torizo arena room (Chozo Statue comes to life when Bombs are grabbed)
  - Boss gate: 4 Chozo statues, activated by defeating Kraid, Phantoon, Draygon, Ridley — opens path to Tourian
  - Energy Recharge Station
  - Missile Expansion and Energy Tank placements
  - Alcoon enemy placement
- Brinstar area: Blue, Green, Pink, Red sub-regions with distinct tilesets
  - Morph Ball acquisition room (Chozo Statue pedestal)
  - Chozo Statues for beam/suit/item pickups
  - Spore Spawn arena, Kraid arena
  - Etecoon creatures: in-game Wall Jump tutorial (mechanic available since Phase 1, Etecoons demonstrate the technique)
  - Energy Recharge Station, Missile Recharge Station, Map Station
  - Boyon, Beetom, Cacatac, Mini-Kraid enemy placements
  - Item placements
- Upper Norfair area (east and west sections):
  - Heated rooms, lava pools
  - Crocomire arena (lava pit, bridge)
  - Dachora creatures: in-game Shinespark tutorial
  - Holtz, Kihunter red, Fireflea enemy placements
  - Station and item placements
- Wrecked Ship area:
  - Unpowered/powered room variants (all rooms have both states)
  - Phantoon arena
  - Atomic, Covern enemy placements (post-Phantoon)
  - Reserve Tank, item placements
- Maridia area:
  - Underwater caves, sand, quicksand pits, glass tube corridors
  - Botwoon arena, Draygon arena (with wall turrets)
  - Evir, Mochtroid, Shaktool enemy placements
  - Reserve Tank, item placements
- Lower Norfair area:
  - Extreme heat and lava zones, ancient Chozo architecture
  - Golden Torizo arena, Ridley arena
  - Reserve Tank, item placements
- Tourian area:
  - Linear gauntlet through Space Pirate command center
  - Eye Doors placed for one-way progression
  - Metroid and Tourian Space Pirate enemy placements
  - Mother Brain arena
  - Skeletal remains and environmental storytelling details
  - Baby Metroid scripted sequence placed
- All elevator connections between areas
- Full area music coverage: all 6 main areas + Tourian with distinct themes and proper transition triggers (elevator, door, boss encounter, scripted event)
- Music system: area themes loop, boss themes override, Wrecked Ship switches from unpowered to powered theme after Phantoon, low energy alarm overlays on current track

### Assets

**Sprites**
- Gunship (exterior, Landing Site)
- Etecoon creatures (Wall Jump tutorial animation)
- Dachora creatures (Shinespark tutorial animation)
- Tourian skeletal remains

**Tilemaps**
- Crateria tileset: surface terrain (rain-weathered rock, cave walls, metal platforms), interior caves
- Brinstar Blue tileset (metallic corridors, blue tones)
- Brinstar Green tileset (dense jungle overgrowth, organic)
- Brinstar Pink tileset (organic caves, pink rock)
- Brinstar Red tileset (red rocky caverns, Kraid's lair)
- Norfair Upper tileset: volcanic rock, magma channels, metal grating over lava, heat distortion areas
- Crocomire section tileset: lava pit arena, bridge
- Wrecked Ship tileset: derelict metal corridors, broken consoles (unpowered variant: dark, inert; powered variant: lit, active displays)
- Maridia tileset: underwater rock, coral, sand floors, quicksand pits, glass tube corridors
- Lower Norfair tileset: extreme volcanic, intense lava pools, ancient Chozo architecture
- Tourian tileset: Space Pirate command center, metal corridors, organic Metroid containment tubes, Mother Brain arena

**VFX**
- Rain effect (Crateria surface)

**Audio**
- Crateria music theme (surface), Crateria music theme (caves)
- Brinstar music theme (Green/jungle), Brinstar music theme (Red/Kraid area)
- Upper Norfair music theme
- Lower Norfair music theme
- Wrecked Ship music (unpowered — muted, eerie), Wrecked Ship music (powered — restored)
- Maridia music theme
- Tourian music theme
- Etecoon chirp SFX, Dachora cry SFX

---

## Phase 8 — Bookends & Completion

The Ceres Station prologue, the Zebes escape sequence, time-based endings, all menus/screens, the save system, and full item audit.

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
  - 3-10 hours: Samus removes helmet
  - <3 hours: Samus in civilian clothes
  - Item collection percentage displayed on ending screen
- Title screen
- Save system: Save Station saves game progress (does not restore health or ammo). Map symbol: S. Save data records: Samus's position, all collected items, defeated bosses, opened doors, and play time. Gunship also saves (in addition to full restore). Save Stations placed in all areas
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
- Sequence break validation: Wall Jump height accessibility, Mockball routes through Brinstar, Infinite Bomb Jump paths, early Super Missile routes

### Assets

**Sprites**
- Ceres Station: dead researchers, baby Metroid in containment capsule, Ceres Ridley (reuse Ridley sprites from Phase 6)
- Samus: ending images (full suit, helmet removal, civilian clothes)
- Etecoon and Dachora escape sprites (fleeing Zebes in ending)
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
