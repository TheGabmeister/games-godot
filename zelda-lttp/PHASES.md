# The Legend of Zelda: A Link to the Past — Phased Implementation Plan

Systems-focused plan derived from [SPEC.md](SPEC.md). Builds every gameplay system with minimal representative content, then expands with full dungeon/overworld content in later phases.

---

## Phase 1 — Movement & Camera

Core traversal: the foundation every other system depends on.

- 8-directional walking with subpixel accumulator (cardinal 1.5 px/frame alternating 2-1, diagonal 1.0 px/frame constant)
- Terrain speed modifiers: tall grass and shallow water slow to 1.25 px/frame (pattern 2-1-1-1), stairs to 0.6875 px/frame (1-1-1-0-1-1-0)
- Automatic ledge hops with 20-frame initiation delay
- Push/pull objects: push statues and blocks (cardinal 1-1-1-0 pattern), pull levers
- Lift/throw: pick up pots and bushes (no gloves required), throw for 2 damage on contact; slowed to 1.25 px/frame while carrying
- Context-sensitive A button: read signs, open chests (item held above head)
- Top-down camera: smooth scrolling on overworld; screen-by-screen snap transitions reserved for dungeon rooms (Phase 6)
- Debug level: small outdoor area with grass patches, dirt paths, ledges to hop, pushable statues, pots, bushes, readable signs, 2 chests

### Assets

**Sprites**
- Link: 8-direction walk cycle, push/pull, lift/carry/throw, ledge hop, idle
- Objects: pot, bush, pushable statue, sign, chest (closed/open)

**Tilemaps**
- Debug outdoor tileset: grass, dirt, path, ledge tiles, shallow water

**Audio**
- Footstep SFX (grass, dirt, stone, shallow water)
- Pot/bush lift SFX, throw SFX, shatter SFX
- Chest open SFX
- Sign read SFX

---

## Phase 2 — Melee Combat & Health

Sword combat and the hearts system — Link can fight, take damage, and die.

- Sword slash: B tap, standard arc in facing direction
- Spin attack: hold B for ~30 frames, release for 360° arc; one damage class higher than slash
- 4 sword tiers with progressive damage (subclass 1): Fighter's Sword 2, Master Sword 4, Tempered Sword 8, Golden Sword 16; each tier doubles the previous
- Sword beam: ranged projectile at full health, Master Sword and above (testable via debug sword swap; normal Master Sword acquisition in Phase 17)
- Damage class / subclass lookup table (16 classes × 8 subclasses) — full ROM table from SPEC §1
- Thrown object damage: 2 (uses separate damage application route from melee)
- Hearts: 3 starting hearts, 1 heart = 0x08 internal, partial hearts for fractional damage, max 20 hearts
- Heart Container pickup: +1 max heart (used by bosses in Phase 7)
- Heart Piece pickup: collectible quarter-heart. 4 pieces = 1 Heart Container (auto-converts on 4th piece). Counter tracked internally. 24 total in world (placed in Phase 19).
- Low-health warning: audible beep plays continuously at ≤1 heart remaining
- Shield passive blocking: Fighter's Shield auto-blocks arrows and rocks when Link faces the projectile; no button press
- Armor/mail passive defense: Green Mail (default, no reduction); damage intake governed by bump class table (10 classes × 3 mail tiers — full table in enemies.md). Blue/Red Mail items deferred to dungeon content (Phases 18/19)
- Invincibility frames: 58 frames (~0.97s) after taking damage, sprite blinks; recoil/knockback on separate timer preventing input
- Death: game over screen on 0 HP
- Link starts pre-equipped: Fighter's Sword, Fighter's Shield, Green Mail
- HUD: life meter (heart rows, "LIFE" label, top-right)
- Debug level update: add 2 breakable pots for throw-damage testing, 2 target dummies (stationary, varying subclasses) for damage verification

### Assets

**Sprites**
- Link: sword slash (4 directions), spin attack charge + release, sword beam projectile, damage recoil, invincibility blink, death animation
- Fighter's Sword, Fighter's Shield
- Heart Container pickup
- Heart Piece pickup (quarter-heart sprite)

**VFX**
- Sword slash arc, spin attack arc, sword beam trail
- Damage flash on enemies, recoil knockback

**Audio**
- Sword slash SFX, spin charge SFX, spin release SFX, sword beam SFX
- Shield block SFX
- Link damage SFX, death SFX
- Low-health warning beep (repeating)
- Heart Container pickup fanfare, Heart Piece pickup SFX (4th piece triggers Heart Container fanfare)
- Game over jingle

**UI**
- Life meter (hearts row with partial-fill states)
- Game over screen

---

## Phase 3 — Enemy AI & Drops

Enemies populate the world, fight back, and drop items on death.

- 8 AI behavioral archetypes per SPEC §6:
  - Patrol (walks fixed route, attacks on contact) — test: Green Soldier, HP 4, bump 0x01
  - Charge-on-sight (idles then rushes) — test: Rope, HP 4, bump 0x01
  - Ranged (fires projectiles) — test: Octorok, HP 2, bump 0x01
  - Erratic (unpredictable bouncing) — test: Keese, HP 1, bump 0x00
  - Stationary-until-triggered (dormant until approached) — test: Armos Statue, HP 8, bump 0x01
  - Invulnerable hazard (cannot be destroyed) — test: Spark, bump 0x03
- Phasing archetype (appear/disappear, teleport) deferred to Phase 9 (first needed for Poe)
- Thief archetype (steal items/shields on contact, must be recoverable or replaceable) deferred to Phase 14 (first needed for Pikit)
- Bump damage system: each enemy has a bump class (0x00–0x09), damage per class per mail tier defined in bump table
- Prize pack drop system: 8 packs (0–7), each with a cycling 8-item sequence and per-pack drop rate (0%, 50%, or 100%). Kill counter advances per group. Special rules: stunned kill → Green Rupee; dash kill → 0% drop rate (dash not built yet — wired in Phase 10)
- Pickups from drops and environment (grass, pots): Green Rupee (1), Blue Rupee (5), Red Rupee (20), Heart, Small Magic Jar, Large Magic Jar, Bombs, Arrows
- Rupee wallet: tracks up to 999
- HUD: rupee counter (Rupee icon + value), bomb counter, arrow counter — below equipped-item box, top-left
- Debug level update: place 6 test enemies in outdoor area; grass patches yield random pickups when cut (sword)

### Assets

**Sprites**
- Green Soldier (sword, patrol walk cycle, attack)
- Octorok (4-way, idle, spit rock projectile)
- Keese (flapping, erratic flight)
- Rope (idle, charge lunge)
- Armos Statue (dormant, activated hop)
- Spark (orbiting movement along walls)
- Pickups: Green/Blue/Red Rupee, Heart, Small/Large Magic Jar, Bomb bundle, Arrow bundle

**VFX**
- Enemy death poof, pickup sparkle

**Audio**
- Enemy hit SFX, enemy death SFX
- Rupee pickup SFX, heart pickup SFX, bomb pickup SFX, arrow pickup SFX
- Armos activation SFX

**UI**
- Rupee counter, bomb counter, arrow counter (HUD bottom-left area)

---

## Phase 4 — Items & Inventory

The Y-button item framework and first ranged weapons — Link can equip and use items from a menu.

- Y-button item slot: one item assigned at a time, used with Y during gameplay
- Inventory screen (Start button): item grid showing all collected Y-items, navigate with D-Pad, highlight to assign to Y
- Equipment panel (right side of inventory): displays current Sword, Shield, Mail, Gloves icons (read-only)
- Pendant/Crystal tracker on inventory screen (empty for now — populated in Phase 7)
- Item pickup: hold item above head with fanfare
- Bow & Arrows: ranged projectile, damage class 0x6 (4 damage subclass 1), consumes 1 arrow per shot, 30 starting capacity
- Boomerang: stun + retrieve items, damage class 0x0 (1 damage or stun), returns to Link after throw
- Bombs: place on ground, explodes after short fuse, damage class 0x8 (4 damage), destroys cracked/bomb-able walls, 10 starting capacity
- Bomb-able walls: cracked wall tiles that break on bomb explosion, revealing passages
- Link pre-equipped: Phase 2 starter gear + Bow (30 arrows), Boomerang, Bombs (10)
- HUD: equipped Y-item icon box (top-left, shows currently selected item)
- Debug level update: add bomb-able wall revealing a hidden room, distant targets for Bow practice, out-of-reach Rupee for Boomerang retrieval

### Assets

**Sprites**
- Link: Y-item use animation (generic hold-out), bow draw/release, boomerang throw/catch, bomb place
- Arrow projectile, Boomerang projectile (blue), Bomb (placed, fuse, explosion)
- Cracked wall (intact, destroyed)

**VFX**
- Bomb explosion, arrow impact, boomerang trail

**Audio**
- Item pickup fanfare (major item held above head)
- Arrow fire SFX, boomerang throw SFX, boomerang return SFX
- Bomb place SFX, bomb fuse tick, bomb explosion SFX
- Inventory screen open/close SFX, cursor move SFX, item equip SFX

**UI**
- Inventory screen: item grid, equipment panel, pendant/crystal tracker (placeholder)
- Equipped Y-item HUD box (top-left)

---

## Phase 5 — Magic System

The magic meter and first magic-consuming items — resource management layer on top of combat.

- Magic meter: 0x80 (128) max, vertical green bar on HUD
- Consumption per item use (base cost): Lamp 4, Fire Rod 8, Ice Rod 8
- Pickups: Small Magic Jar restores 0x10 (1/8 meter), Large Magic Jar restores 0x40 (1/2 meter)
- Green Potion: restores full meter (bottle system in Phase 12; for now, test via debug pickup)
- 1/2 Magic upgrade: deferred to Phase 16 (Mad Batter)
- Lamp: lights torches (one at a time, stays lit), illuminates dark rooms; 4 magic per torch
- Fire Rod: fireball projectile, 8 magic per shot; damage class 0xB (8 damage or burn/incinerate effect)
- Ice Rod: ice projectile, 8 magic per shot; damage class 0xC (8 damage or freeze effect)
- Special damage effects: burn (enemy catches fire, instant kill on susceptible targets), freeze (enemy encased in ice, can be shattered with Hammer — Hammer in Phase 15)
- Link pre-equipped: Lamp, Fire Rod, Ice Rod (added to Phase 4 inventory)
- HUD: magic meter bar (vertical, left of equipped-item box, labeled "1/2" after upgrade — visual placeholder for now)
- Debug level update: add dark room (screen goes dark without Lamp, torches to light), fire-vulnerable and ice-vulnerable test enemies

### Assets

**Sprites**
- Lamp flame (held out), torch (unlit/lit states)
- Fire Rod: fireball projectile
- Ice Rod: ice projectile
- Frozen enemy overlay, burning enemy overlay

**VFX**
- Fireball trail + impact explosion, ice crystal trail + freeze burst
- Dark room fog/overlay (screen-wide darkness, circle of light around Link with Lamp)
- Torch ignite flare

**Audio**
- Lamp light SFX
- Fire Rod whoosh SFX, fireball impact SFX
- Ice Rod crystallize SFX, freeze SFX
- Magic jar pickup SFX
- Magic depleted warning SFX (attempt to use item with insufficient magic)

---

## Phase 6 — Dungeon Framework

Room-based dungeon structure with keys, puzzles, and collectibles — the second half of the core gameplay loop.

- Room-by-room screen transitions (instant snap, no smooth scroll between dungeon rooms)
- Locked doors: require Small Key to open (key consumed on use)
- Small Keys: consumable, dungeon-specific, cannot be transferred between dungeons
- Big Key: opens boss door and all large treasure chests in current dungeon
- Boss door: sealed until Big Key used; also seals shut when boss fight begins, reopens on boss defeat
- Dungeon Map: collectible item, reveals full room layout on dungeon map screen
- Compass: collectible item, marks chest locations and boss position on dungeon map
- Dungeon map screen (X button while in dungeon): room grid with visited rooms highlighted, chest icons (with Compass), boss skull icon (with Compass), Link's position marker
- Treasure chests: small (any item/key), large (requires Big Key to open, contains dungeon Key Item)
- Puzzle elements:
  - Floor switches (step on to trigger door open or event)
  - Crystal switches (hit to toggle all orange/blue barrier blocks dungeon-wide)
  - Push-block puzzles (push blocks onto switches or into holes)
  - Torch puzzles (light all torches in room to open door — uses Lamp from Phase 5)
  - Pit/hole tiles (Link falls to room below, loses 1/2 heart)
- Debug level update: 5-room test dungeon — (1) entry room with enemies and Small Key chest, (2) push-block puzzle room with floor switch, (3) dark room with torch puzzle, (4) locked door → Big Key chest room with crystal switch, (5) boss room (boss door, sealed on entry). Place Dungeon Map and Compass in rooms 1 and 2.

### Assets

**Sprites**
- Dungeon door (locked, unlocked, boss door, sealed boss door)
- Small Key, Big Key, Dungeon Map, Compass (in-world and inventory icons)
- Treasure chest (small, large — closed/open variants)
- Floor switch (up/pressed), crystal switch (orange/blue states)
- Orange barrier block, blue barrier block
- Pit/hole tile

**Tilemaps**
- Dungeon interior tileset: stone walls, floor, torch sconces, door frames, pit edges

**Audio**
- Door unlock SFX, boss door open SFX
- Key pickup SFX, Dungeon Map pickup jingle, Compass pickup jingle
- Floor switch press SFX, crystal switch toggle SFX
- Pit fall SFX
- Dungeon ambient track (test dungeon)

**UI**
- Dungeon map screen (room grid, chest/boss icons, Link marker)

---

## Phase 7 — First Boss & Dungeon Rewards

Multi-phase boss framework and the first complete boss fight — validates the full dungeon loop from entrance to reward.

- Boss framework: HP pool, phase transitions triggered by HP thresholds, unique attack patterns per phase, vulnerability windows, invincibility during transitions
- Boss arena uses Phase 6 boss door (seals on entry, reopens on defeat)
- Boss defeat sequence: explosion animation, Heart Container drop, Pendant/Crystal appears
- Pendant/Crystal reward: collected items tracked on inventory screen pendant/crystal tracker (extends Phase 4 inventory)
- Armos Knights (Eastern Palace boss):
  - 6 statues, 48 HP each, bump class 0x01 (1/2 heart contact)
  - Phases: stationary formation → rotating clockwise → contract/expand cycle → row movement → final red knight (HP resets to full when last knight turns red)
  - Bow weakness: 16 damage per arrow (3 arrows per knight); sword slash deals standard damage
  - No RNG — deterministic patterns
- Debug level update: Armos Knights placed in test dungeon boss room. On defeat: Heart Container + Pendant of Courage

### Assets

**Sprites**
- Armos Knight (6 variants: idle statue, hopping, red-tinted final form)
- Pendant of Courage (in-world, inventory icon)
- Boss explosion sequence

**VFX**
- Boss defeat explosion chain, Heart Container descend sparkle, Pendant appear flash

**Audio**
- Boss intro fanfare (doors seal)
- Boss battle music
- Boss defeat explosion SFX
- Boss clear fanfare + Pendant acquisition jingle
- Heart Container pickup fanfare (reuse from Phase 2)

**UI**
- Pendant/Crystal tracker on inventory screen (now functional — shows collected Pendants)

---

**Vertical slice checkpoint — Link can walk a test overworld area, enter a 5-room dungeon, solve push-block and torch puzzles, use sword/bow/bombs/lamp, fight Armos Knights through 5 phases, and receive a Heart Container + Pendant of Courage. HUD displays hearts, magic, rupees, bombs, arrows, and equipped item. Inventory screen allows item equipping. No NPCs, no dialogue, no shops, no saving — those systems begin in Phase 8.**

---

## Phase 8 — Dialogue & NPCs

Text display and NPC interaction — the game can now communicate story, hints, and instructions to the player.

- Text box: bottom-of-screen panel, character-by-character text reveal, advance with button press, auto-close after final page
- NPC dialogue: face NPC + press A to trigger; non-branching (no dialogue choices)
- Sign reading: face sign + press A, displays text box
- Telepathic messages: distinct visual treatment (telepathy portrait frame, different text box background), triggered by story events or proximity to Telepathy Tiles
- NPC sprites: idle + facing-player reaction
- Debug level update: add 3 NPCs to test area — villager (generic dialogue), sage (telepathic hint), shopkeeper (placeholder text, functional shop in Phase 11)

### Assets

**Sprites**
- Generic villager NPC (idle, face directions)
- Sage NPC (Sahasrahla-style)
- Shopkeeper NPC (behind counter)

**VFX**
- Telepathy portrait overlay frame

**Audio**
- Text character appear SFX (blip per character)
- Text advance SFX (page turn)
- Telepathy open SFX (distinct chime)

**UI**
- Text box panel (bottom of screen, semi-transparent background)
- Telepathy text box variant (portrait frame + different background)

---

## Phase 9 — Light World Overworld

The full Light World overworld — Link can explore Hyrule as a connected world.

- Light World tilemap: ~16×16 screen grid covering all regions:
  - Hyrule Castle (central), Kakariko Village (west), Lost Woods (northwest), Death Mountain (north), Eastern Palace area (east), Desert of Mystery (southwest), Great Swamp (south), Lake Hylia (southeast), Sanctuary and Graveyard (north-center), Zora's River (northeast)
- Smooth camera scrolling across overworld screens
- Screen-edge transitions to cave/building interiors
- Terrain: cuttable grass (drops pickups), shallow water (slows movement), deep water (impassable barrier — traversable after Phase 10 Flippers), sand, mountain paths, liftable rocks (visual only — lifting mechanics in Phase 15 Power Glove)
- Cave entrances: transition to small interior rooms (fairy fountains, item caves, passage caves)
- NPC placement in Kakariko Village and key overworld locations
- Environmental: opening rain sequence (darker palette + rain sprite overlay during Hyrule Castle rescue; clears after reaching Sanctuary)
- Overworld map screen (X button on overworld): full world map with Link position marker; shows Light World (Dark World variant added in Phase 14)
- Phasing AI archetype (deferred from Phase 3): enemies appear/disappear or teleport on a timer, invulnerable while invisible. Extends Phase 3 enemy framework. Needed for Poe (Graveyard) and Wizzrobe (Phase 18 dungeons).
- Enemies: populate per-region using archetypes from Phase 3 + Phasing — Soldiers near Castle/Kakariko, Octoroks in fields, Vultures in desert, Tektites and Lynels on Death Mountain, Poes in Graveyard

### Assets

**Sprites**
- Region-specific enemies not yet built: Vulture (HP 6, bump 0x03), Buzzblob (HP 3, bump 0x01), Leever (HP 4, bump 0x01), Geldman (HP 4, bump 0x03), Tektite (HP 4, bump 0x05), Lynel (HP 24, bump 0x06), Poe (HP 8, bump 0x05), Zora (HP 8, bump 0x01)
- Kakariko Village NPCs (villagers, shopkeepers, sick boy, library scholar)
- Overworld objects: liftable rocks (light green, heavy dark — visual distinction only until Phase 15)

**Tilemaps**
- Light World overworld tileset: grass, trees, water, sand, mountain, castle walls, village buildings, bridges, paths
- Cave/interior tileset: stone walls, fairy fountain pool, torches
- Kakariko Village building interiors

**VFX**
- Rain overlay (sprite layer), rain-darkened palette
- Cave entrance transition (fade to black)

**Audio**
- Light World overworld theme
- Kakariko Village theme (if distinct) or shared overworld
- Cave/interior ambient track
- Rain ambient SFX loop
- Rain stop transition

**UI**
- Overworld map screen (full Light World, Link position marker)

---

## Phase 10 — Extended Movement

Pegasus Boots dash and Flippers swimming — two new movement modes gated by passive items.

- **Pegasus Boots (extends Phase 1 movement):**
  - A-button dash: 29-frame charge buildup, then 4.0 px/frame cardinal speed (3.0 px/frame in tall grass)
  - Bonk: ~16-frame stun on wall/solid-object collision, Link bounces back
  - Bonk-dislodge: dashing into specific objects (trees, bookshelves, rock piles) shakes loose hidden items
  - Dash attack (poke): extends Phase 2 combat — sword level - 1 damage class (Fighter's poke 2, Master poke 2, Tempered poke 4, Golden poke 8)
  - Dash-kill enemies: forces 0% prize pack drop rate (extends Phase 3 drops)
- **Zora's Flippers (extends Phase 1 movement):**
  - Acceleration-based swimming in deep water: accel ~1/32 px/f², decel ~3/64 px/f²
  - Max speed cardinal ~0.9 px/f, button-mash cardinal 1.5 px/f
  - Deep water transitions from impassable barrier (Phase 9) to traversable terrain
  - Swimming animation replaces walking in deep water tiles
- Pre-equipped for testing: Pegasus Boots, Flippers (as passive items — no inventory slot, always active once obtained)
- Debug level update: add long corridor for dash testing, tree with hidden Rupee for bonk-dislodge, deep water pool connected to land for swim testing

### Assets

**Sprites**
- Link: dash charge (boots spark), dashing run, bonk stun recoil, poke attack (sword thrust while dashing)
- Link: swimming (4-direction swim cycle, treading water idle)
- Pegasus Boots, Flippers (inventory passive-item icons)
- Tree shake animation, bookshelf wobble animation

**VFX**
- Dash charge spark at feet, bonk impact stars
- Water splash on entry/exit, swimming wake trail

**Audio**
- Dash charge SFX (building energy), dash launch SFX
- Bonk impact SFX (comedic thud)
- Tree/bookshelf shake SFX, hidden item dislodge SFX
- Water splash SFX, swimming stroke SFX

---

## Phase 11 — Shops & Economy

Buy screen and shop inventories — rupees become spendable currency.

- Shop buy screen: browse item list, show item name + price, confirm purchase, deduct rupees, add item to inventory. Error feedback if insufficient rupees or inventory full.
- Shop NPC interaction: approach counter + press A opens buy screen (extends Phase 8 dialogue with shop-specific flow)
- Light World shop inventories per SPEC §7:
  - Kakariko General / Lake Hylia / Death Mountain: Red Potion 150, 10 Bombs 50, Heart 10
  - Witch's Hut: Red Potion 120, Green Potion 60, Blue Potion 160
  - King Zora: Flippers 500
  - Bottle Merchant: Empty Bottle 100
- Potion purchase requires an empty Bottle (Bottle system in Phase 12 — for now, potions are non-purchasable; shop displays them but grays out without Bottle)
- Dark World shops deferred to Phase 14
- Income loop validated: enemies drop rupees (Phase 3) → player spends at shops → buys consumables/equipment
- Debug level update: add shop counter NPC with Kakariko General inventory in test area

### Assets

**Sprites**
- Shop interior elements: counter, shelves, item display sprites
- Shopkeeper (behind counter, animated dialogue)

**Audio**
- Shop theme music
- Purchase confirm SFX (cha-ching)
- Purchase denied SFX (error buzz)
- Rupee deduct SFX (counter tick-down)

**UI**
- Shop buy screen: item list with names, prices, cursor, rupee balance display

---

## Phase 12 — Bottles & Consumables

The bottle system — a versatile container mechanic for potions, fairies, and creatures.

- 4 Bottles obtainable (1 per SPEC §5 location — Bottle Merchant purchase, Kakariko bar bomb wall, under bridge with Flippers, Dark World locked chest)
- Bottle stores one item at a time; using the contents empties it
- Contents:
  - Red Potion: fully restores hearts
  - Green Potion: fully restores magic meter
  - Blue Potion: fully restores hearts AND magic
  - Fairy: restores 7 hearts on use; auto-revives Link on death (restores 7 hearts, consumes Fairy, overrides game over)
  - Bee: released into world, attacks nearby enemies, then flies away
  - Golden Bee: stronger, longer duration; sellable to Bottle Merchant for 100 rupees
- Bug-Catching Net: new Y-button item, swings in arc to catch Fairies and Bees from the world
- Bottle sub-selection: selecting Bottle slot in inventory opens sub-menu to choose which of 4 bottles to assign to Y (extends Phase 4 inventory)
- Potion purchase at shops now functional: requires empty Bottle in inventory (extends Phase 11 shops — grayed-out potions become purchasable)
- Debug level update: add a fairy fountain room with catchable fairy sprites, a bee under a bush, 2 test bottles pre-placed in chests

### Assets

**Sprites**
- Bottle (empty, filled variants for each content type — icons in inventory)
- Bug-Catching Net: Link swing animation, net arc
- Fairy (floating, captured, released-revive)
- Bee (flying, attacking, Golden Bee variant)
- Potion bottle: Red, Green, Blue color variants

**VFX**
- Fairy revive sparkle burst (on death → revive transition)
- Potion drink overlay (heal flash for Red, magic swirl for Green, both for Blue)
- Bee attack buzz trail

**Audio**
- Bottle capture SFX (cork pop)
- Potion drink SFX
- Fairy revive jingle (overrides death jingle)
- Bee buzz SFX, bee attack SFX
- Net swing SFX

**UI**
- Bottle sub-selection popup within inventory screen

---

## Phase 13 — Save & Persistence

Manual save system — progress persists across sessions.

- Save data model: all collected items and equipment tiers, dungeon clear flags (which dungeons beaten), dungeon progress (opened doors, collected keys/items per dungeon), Heart Piece count, Heart Container count, bomb/arrow capacity upgrades, rupee balance, death count, world state flags (Agahnim defeated, rain cleared, etc.), magic meter upgrades
- "Save and Quit": Start → Select opens Save & Quit confirmation dialog; writes to save slot, returns to title screen
- 3 save slots: each stores independent save data
- Respawn points on continue or death:
  - Light World: player chooses from Link's House, Sanctuary, Mountain Cave
  - Dark World: Pyramid of Power (only option)
  - In dungeon: dungeon entrance (dungeon progress preserved)
- Title screen: New Game (choose slot), Continue (load from slot)
- No auto-save; power-off without saving loses progress since last save

### Assets

**Audio**
- Save confirm SFX
- Title screen / file select music
- File select cursor SFX

**UI**
- Save & Quit confirmation dialog
- Title screen: New Game / Continue / Copy / Erase file options
- File select screen: 3 slots showing name, hearts, death count

---

## Phase 14 — Dark World & World Transitions

The parallel Dark World and the warp mechanics that connect both overworlds — the game's signature structural system.

- Dark World overworld tilemap: mirrors Light World 1:1 with corrupted tileset (darker purples/browns, overcast sky, dead trees, darker water). Same dimensions and screen grid as Light World.
- Region mapping per SPEC §3: Hyrule Castle → Pyramid of Power, Kakariko → Village of Outcasts, Lost Woods → Skeleton Forest, etc.
- 9 fixed portals Light → Dark per SPEC §3 portal table (requirement gating: none for portals 1–2, Magic Hammer for 3–5, Titan's Mitt for 6–8, stake sequence for 9). Hammer/Mitt item checks wired to Phase 15 items.
- Magic Mirror: Y-button item, usable only in Dark World. Warps Link to corresponding Light World position. Leaves temporary shimmering return portal at arrival spot. Portal disappears if Mirror used again or Link moves far away. Core puzzle mechanic: warp to LW from a DW ledge → land on inaccessible LW spot → step back through portal.
- Moon Pearl: passive item. Without it, entering Dark World transforms Link into a helpless pink bunny (can't attack, can't use items, restricted movement). With Moon Pearl, Link retains human form. Moon Pearl placed in Tower of Hera (Phase 17).
- Bunny transformation: Link's sprite replaced with bunny, all action buttons except movement disabled, reverts on return to Light World via Mirror.
- World transition effect: screen wipe/flash when warping between worlds.
- Misery Mire perpetual rain: rain overlay + darker palette on the Misery Mire region. Ether Medallion (Phase 15) on specific tile clears rain and reveals dungeon entrance (Phase 18).
- Overworld map screen: extends Phase 9 — now shows Dark World when Link is in DW.
- Dark World shops: extends Phase 11 with DW inventories per SPEC §7 — General Shops (×3), Specialty near Pyramid (Red Shield 500, Bee in Bottle 10, 10 Arrows 30), Bomb Shop (30 Bombs 100, Super Bomb 100 — Super Bomb gated behind Ice Palace + Misery Mire clear flags).
- Thief AI archetype (deferred from Phase 3): enemies steal equipped item or shield on contact. Stolen shield must be re-purchased or upgraded. Extends Phase 3 enemy framework. Needed for Pikit (overworld), Like-Like (Phase 18 dungeons).
- Dark World enemies: populate per-region — Snapdragon (HP 12, bump 0x08), Hinox (HP 20, bump 0x08), Moblin (HP 4, bump 0x05), Mini Helmasaur (HP 4, bump 0x03), Pikit (HP 12, bump 0x05, Thief), etc. per enemies.md.

### Assets

**Sprites**
- Bunny Link (walk cycle, idle, damage — limited animation set)
- Magic Mirror (inventory icon, in-world held)
- Moon Pearl (inventory passive-item icon)
- Dark World overworld enemies: Snapdragon, Hinox, Moblin, Mini Helmasaur, Ropa, Pikit, Stal, Hover, Zirro (blue/red), Crab, Swimmers
- Dark World NPCs (transformed villagers, monsters acting as shopkeepers)

**Tilemaps**
- Dark World overworld tileset: corrupted grass, dead trees, dark water, purple mountain, ruined buildings, Pyramid of Power
- Village of Outcasts buildings/interiors

**VFX**
- World transition wipe/flash effect
- Portal shimmer (LW→DW warp point, Mirror return portal)
- Bunny transformation poof
- Mirror warp light beam

**Audio**
- Dark World overworld theme
- Portal warp SFX
- Mirror use SFX, mirror warp SFX
- Bunny transformation SFX
- World transition SFX (wipe/flash sound)

---

## Phase 15 — Remaining Y-Button Items

All remaining equippable items — each adds a unique mechanic using the Phase 4 Y-button framework and Phase 5 magic system.

- **Hookshot:** fires chain, grapples to objects (chests, posts, blocks), pulls Link across gaps. Damages/stuns enemies (damage class 0x7, stun-255 on subclass 1). New "hookshot-able post" and "gap" tiles for dungeons and overworld.
- **Magic Hammer:** pounds stakes/pegs flush into ground (removing obstacle), damages enemies (8 damage). Shatters frozen enemies. New "hammer stake" objects in overworld (gate portals in Phase 14) and dungeons.
- **Power Glove / Titan's Mitt (extends Phase 1 lifting):** Power Glove enables lifting light (green) rocks; Titan's Mitt enables lifting heavy (dark) rocks. Two new liftable-rock object tiers. Without gloves, rocks are immovable.
- **Cane of Somaria:** creates one pushable block (8 magic). Block can be pushed onto floor switches, or struck to split into 4 directional projectiles. Only one block at a time — creating a new one destroys the old.
- **Magic Cape:** Link becomes invisible + invulnerable. Sustained magic drain (~4 frames per tick). Passes through enemies and some hazards (bumper, spike floors). Transparent sprite.
- **Cane of Byrna:** spinning protective barrier around Link. 16 magic initial + sustained drain. Damages enemies on contact while active. Invulnerability while active.
- **Medallions (Bombos, Ether, Quake):** 32 magic each. Screen-clearing attacks affecting all on-screen enemies. Bombos: fire/burn (16 dmg, damage class 0xD). Ether: freeze (freeze or 16 dmg, class 0xE). Quake: earthquake (32 dmg or stun, class 0xF). Ether triggers Misery Mire entrance (clears rain). Quake triggers Turtle Rock entrance. Medallion acquisition requires Book of Mudora at tablets.
- **Book of Mudora:** approach Hylian tablet + use Book → read text → receive item. Ether Medallion from Death Mountain bridge tablet. Bombos Medallion from Desert cliff tablet (reached via Dark World → Mirror warp to inaccessible Light World ledge — requires Phase 14). Simple event trigger.
- **Flute:** summons bird, opens destination picker overlay with 8 Light World locations per SPEC §3. Light World only. Extends Phase 9 overworld with fast travel.
- **Shovel:** dig in designated spots to unearth buried items. Used to find the Flute. Replaced by Flute in inventory after Flute acquisition.
- **Magic Powder:** sprinkle on enemies (damage class 0xA: faerie/blob/stun/100 dmg depending on subclass), light torches, cure Anti-Fairies. 4 magic per use. Acquired by giving Mushroom (Lost Woods) to Witch.
- Debug level update: add hookshot gap with post, hammer stakes, light/dark rocks, Somaria switch puzzle, spike floor for Cape/Byrna testing, tablet monument. Pre-equip all items.

### Assets

**Sprites**
- Hookshot (chain extending, post object, Link pulled)
- Magic Hammer (Link pound animation, stake — raised/pounded)
- Power Glove, Titan's Mitt (inventory icons; Link lift animations for green/dark rocks)
- Light rock, dark rock (overworld objects, liftable/smashed)
- Cane of Somaria (block creation, block sprite, 4-projectile split)
- Magic Cape (transparent Link overlay)
- Cane of Byrna (spinning orbs around Link)
- Medallion effects: Bombos fire ring, Ether ice lightning, Quake shockwave
- Book of Mudora (held up at tablet), Hylian tablet monument
- Flute (Link playing), bird (flying, carrying Link)
- Shovel (Link digging, dirt spray)
- Mushroom, Magic Powder (sprinkle animation)

**VFX**
- Hookshot chain trail, grapple connect flash
- Hammer ground-pound impact ring
- Cape shimmer/transparency, Byrna spinning orbs glow
- Medallion screen-flash effects (fire/ice/quake full-screen)
- Flute destination picker (bird silhouette fly-in)
- Dig dirt spray, buried item emerge

**Audio**
- Hookshot fire SFX, chain rattle, retract SFX
- Hammer pound SFX, stake sink SFX
- Rock lift SFX (heavier variant for dark rocks)
- Somaria block create SFX, block shatter SFX
- Cape activate SFX, cape sustained hum, cape deactivate SFX
- Byrna activate SFX, byrna spinning hum
- Bombos roar SFX, Ether ice chime SFX, Quake rumble SFX
- Book of Mudora reading chant SFX
- Flute melody, bird screech, bird flight SFX
- Shovel dig SFX
- Magic Powder sprinkle SFX

**UI**
- Flute destination picker overlay (8 labeled locations on map)

---

## Phase 16 — Upgrade Fountains & Minigames

Optional side systems that reward exploration with permanent upgrades and Rupee income.

- **Waterfall of Wishing (extends Phase 2 shields, Phase 4 Boomerang):**
  - Throw in Fighter's Shield → receive Red Shield (blocks fireballs in addition to arrows/rocks)
  - Throw in Boomerang → receive Magical Boomerang (longer range, faster, red sprite)
  - Interaction: approach pond, prompted to throw item, fairy appears and offers upgrade
- **Pyramid Fairy (extends Phase 2 swords, Phase 4 Bow):**
  - Throw in Tempered Sword → receive Golden Sword (8× damage, highest tier)
  - Throw in Bow → receive Silver Arrows (damage class 0x9, 100 damage — required for Ganon Phase 4)
  - Access requires Super Bomb (Dark World Bomb Shop, 100 Rupees, gated behind Ice Palace + Misery Mire clear flags) to blow open Pyramid crack
  - Super Bomb: special bomb, follows Link instead of staying in place, larger explosion
- **Pond of Happiness (extends Phase 4 Bow/Bomb capacity):**
  - Throw 100 Rupees → Queen of Fairies appears, choose +5 Bombs or +5 Arrows
  - Bombs: 10 → 50 max; Arrows: 30 → 70 max
  - Repeatable until both maxed
- **1/2 Magic — Mad Batter (extends Phase 5 magic):**
  - Sprinkle Magic Powder at shrine near Dwarven Swordsmiths → Mad Batter "curses" Link
  - All magic costs halved (Lamp 2, Fire Rod 4, Ice Rod 4, Medallions 16, etc.)
  - HUD magic meter now shows "1/2" label
- **Minigames (all in Dark World Village of Outcasts or Kakariko):**
  - Treasure Chest Game (30 Rupees): 16 randomized chests, open 2, one contains Heart Piece
  - Digging Game (80 Rupees): 30-second timer, dig with Shovel (Phase 15), Heart Piece at random spot
  - Shooting Gallery (20 Rupees): 5 arrows at moving targets, payout doubles per consecutive hit (4→8→16→32→64, max 124 Rupees)
  - 15-Second Race (Kakariko, 20 Rupees): obstacle course, Heart Piece for sub-15-second clear

### Assets

**Sprites**
- Fairy Queen (Waterfall of Wishing, Pond of Happiness — rising from water)
- Mad Batter (bat creature, shrine altar)
- Super Bomb (larger bomb sprite, follows Link)
- Magical Boomerang (red variant)
- Red Shield sprite, Silver Arrow projectile sprite, Golden Sword sprite
- Minigame elements: 16 small chests (Treasure Chest Game), digging field dirt patches, shooting gallery targets (moving), race course obstacles

**VFX**
- Fountain splash + fairy rise, item upgrade flash (old → new transformation)
- Super Bomb mega-explosion, Pyramid wall crumble
- Minigame timer countdown, score popup

**Audio**
- Fountain splash SFX, fairy appear chime
- Item upgrade fanfare (sword/shield/boomerang upgrade)
- Mad Batter curse SFX, 1/2 magic jingle
- Minigame start jingle, timer tick SFX, minigame victory fanfare, minigame fail SFX
- Shooting gallery hit SFX, target break SFX
- Digging game music loop
- Race countdown SFX

**UI**
- Fountain throw prompt ("Throw item in?")
- Pond of Happiness choice ("Bombs or Arrows?")
- Minigame timer display, score/payout display

---

## Phase 17 — Content: Light World Dungeons

Full Light World dungeon content — 4 dungeons with unique room layouts, enemy rosters, puzzles, and bosses. All systems from Phases 1–16 are in place.

**New mechanic — NPC escort AI:** companion NPC follows Link, pathfinds around obstacles, waits when Link moves too far. Used for Zelda escort (below) and Thieves' Town maiden escort (Phase 18).

**Hyrule Castle Escape (Dungeon 0):**
- 3-floor descent: 1F interior → B1 basement → B2 sewers
- Dark rooms in sewers (Lamp required)
- Uncle encounter event: gives Fighter's Sword + Fighter's Shield at start
- Zelda escort: NPC follows Link through escape (escort AI, must reach Sanctuary)
- Enemies: Green Soldiers (reuse Phase 3), Blue Soldiers (HP 6, bump 0x01 — new), Rats (HP 2, bump 0x00 — new), Keese (reuse Phase 3)
- Mini-boss: Ball & Chain Guard (HP 16, bump 0x03)
- Reward: Heart Container upon delivering Zelda to Sanctuary
- Environmental: rain active throughout (darker palette, rain overlay — clears on Sanctuary arrival)

**Eastern Palace (Dungeon 1):**
- Key item: Bow (big-key chest)
- Boss: Armos Knights (reuse Phase 7 — sprites, AI, and framework already built)
- Enemies: Popo (HP 2), Stalfos (HP 4), Green Eyegore (HP 16, arrow-vulnerable), Red Eyegore (HP 8), Anti-Fairies (invulnerable hazard)
- Puzzles: switch-triggered doors, Eyegore vulnerability (only damageable when eye is open)
- Reward: Pendant of Courage

**Desert Palace (Dungeon 2):**
- Requires Book of Mudora to enter (read Hylian script at entrance)
- Key item: Power Glove (big-key chest)
- Boss: Lanmolas — 3 worms, 16 HP each, bump 0x04. Emerge from ground, scatter rocks (4 normally, 8 for last worm). First spawn fixed, subsequent random (64 positions). Bow does 4 damage per arrow (strongly favored).
- Enemies: Leever (HP 4), Geldman (HP 4), Devalant (HP 4), Beamos (invulnerable hazard)
- Puzzles: sand pit tiles, torch-lighting sequences, moving wall traps
- Reward: Pendant of Power

**Tower of Hera (Dungeon 3):**
- Accessed via Death Mountain (requires cave traversal, Old Man gives Magic Mirror en route)
- Key item: Moon Pearl (big-key chest)
- Boss: Moldorm — HP 12, bump 0x03, tail-only vulnerable (head invulnerable). Normal speed → ~33% speed increase at low HP. 20-frame invulnerability after each hit. Falling off platform resets boss HP to full.
- Enemies: Mini Moldorm (HP 3), Hardhat Beetle blue (HP 6, bump 0x05 — knockback-only, pit kills), Fire Snake (HP 3)
- Puzzles: multi-floor vertical dungeon, pit/hole tiles (fall to floor below), crystal switch block mazes
- Reward: Pendant of Wisdom

**Post-Pendant sequence:**
- 3 Pendants → Master Sword pedestal in Lost Woods: cutscene, Link draws Master Sword (2× damage tier)
- Sahasrahla event: gives Pegasus Boots after first Pendant (Eastern Palace)

**Agahnim's Tower:**
- Requires Master Sword to break magical barrier at Hyrule Castle entrance
- No key item
- Mini-boss: Ball & Chain Guard encounters (reuse from Hyrule Castle)
- Boss: Agahnim — HP 96, bump 0x04. Immune to all direct attacks. Reflect energy balls with sword or Bug-Catching Net. Cycle: energy ball → 50/50 energy or unreflectable blue ball → lightning. 16 damage per reflected hit (6 hits to win).
- Reward: Link banished to Dark World (triggers Dark World access — Phase 14 fully active)

### Assets

**Sprites**
- Zelda escort NPC (follow walk cycle)
- Uncle (lying, gives items)
- Ball & Chain Guard (chain swing, throw, walk)
- Lanmolas (3 worms: emerge, fly, rocks scatter)
- Moldorm (segmented body, head, tail — rotating movement)
- Agahnim (teleport, energy ball cast, blue ball cast, lightning strike)
- Energy ball (reflectable), blue energy ball (unreflectable)
- Dungeon-specific enemies not yet built: Popo, Stalfos, Eyegore (green/red — eye open/shut), Devalant, Beamos
- Master Sword (pedestal cutscene, sprite upgrade)
- Sahasrahla NPC

**Tilemaps**
- Hyrule Castle interior tileset (throne room, basement, sewers)
- Eastern Palace tileset
- Desert Palace tileset (sandy interiors, sand pit tiles)
- Tower of Hera tileset (multi-floor, vertical holes)
- Agahnim's Tower tileset (dark castle)

**VFX**
- Lanmolas emerge from ground + rock scatter
- Moldorm speed-up visual cue
- Agahnim teleport flash, energy ball glow trail, lightning strike flash
- Master Sword pedestal draw cutscene (light beam)

**Audio**
- Hyrule Castle escape music (rain ambiance overlay)
- Eastern Palace dungeon music
- Desert Palace dungeon music
- Tower of Hera dungeon music
- Agahnim's Tower dungeon music
- Lanmolas boss SFX (emerge rumble, rock scatter)
- Moldorm boss SFX (tail hit, speed-up chirp)
- Agahnim boss SFX (teleport, energy ball fire, reflect, lightning crack)
- Master Sword acquisition fanfare
- Pegasus Boots acquisition fanfare

---

## Phase 18 — Content: Dark World Dungeons

All 7 crystal dungeons with unique mechanics, enemies, and bosses. Each dungeon's key item was mechanically built in Phase 15 — this phase places them as rewards and designs puzzle rooms that require them.

**New dungeon mechanics (not in Phase 6 framework):**
- Ice floor sliding: Link slides in the current direction until hitting a wall or object. No directional control while sliding. (Ice Palace)
- Lava tiles: deal contact damage on touch. Cane of Somaria blocks serve as movable platforms over lava. (Turtle Rock)
- Conveyor floors: push Link in a fixed direction, change direction on a timer (96–223 frames). (Skull Woods — Mothula arena)
- Water level puzzles: drain switches lower/raise water in connected rooms, opening/closing pathways. (Swamp Palace)
- Multi-entrance dungeons: multiple overworld entry points leading to different sections of the same dungeon. (Skull Woods)

**Palace of Darkness — Crystal 1:**
- Key item: Magic Hammer. Boss: Helmasaur King (48 HP body, 17 HP mask — Hammer 1 dmg/hit or Bombs 4 dmg/hit to break mask; Phase 2 faster, tail swipe + fireball, bump 0x05).
- Must be first DW dungeon (Hammer gates remaining portals).
- Enemies: Mimics, Helmasaur minis, Dark-palette soldiers.

**Swamp Palace — Crystal 2:**
- Key item: Hookshot. Boss: Arrghus (32 HP eye, 8 HP/puff, bump 0x05 — Hookshot pulls puffs; Phase 2 eye jumps/crashes).
- Water-flooded rooms, water level drain puzzle.
- Enemies: Red/Blue Bari (HP 2), Kyameron (HP 4), Slime (HP 4), Swamola (HP 16, bump 0x07).

**Skull Woods — Crystal 3:**
- Key item: Fire Rod. Boss: Mothula (HP 32, bump 0x05 — spike projectiles every 64 frames, conveyor floors change every 96–223 frames, 10-frame double-hit window).
- Multiple outdoor-to-indoor entrances, Wallmaster grabs (HP 8, warps Link to entrance).
- Enemies: Gibdo (HP 32), Sluggula (HP 8, bump 0x06).

**Thieves' Town — Crystal 4:**
- Key item: Titan's Mitt. Boss: Blind the Thief (9 hits total, 3 phases × 3 hits — fixed 1 hit per strike regardless of weapon; decapitated heads shoot fireballs; must bomb ceiling hole for light, bump 0x05).
- Disguised as Gargoyle's Domain. Maiden NPC escort — reveal Blind by guiding NPC to light.

**Ice Palace — Crystal 5:**
- Key item: Blue Mail (~50% damage reduction — extends Phase 2 armor). Boss: Kholdstare (64 HP × 3 eyeballs, 64 HP ice shell — Fire Rod 8 shots to melt shell; ice blocks from ceiling every 128 frames; Phase 2 eyeballs bounce 45°, bump 0x07).
- Ice floor sliding physics (Link slides until hitting wall/object).
- Mini-boss: Stalfos Knight (HP 64, bump 0x05 — collapses on hit, reforms; bomb the pile to kill permanently).
- Enemies: Pengator (HP 16), Freezor (HP 16, bump 0x06).

**Misery Mire — Crystal 6:**
- Key item: Cane of Somaria. Boss: Vitreous (128 HP main eye, 48 HP/small eye — Phase 1 small eyes launch + lightning; Phase 2 main eye chases, bump 0x07).
- Ether Medallion required on entrance tile to clear magical rain and reveal door.
- Enemies: Wizzrobe (HP 2, bump 0x06 — teleport, phasing archetype), Pokey (HP 32, bump 0x06), Gibo (HP 8).

**Turtle Rock — Crystal 7:**
- Key item: Mirror Shield (blocks laser beams, reflects — extends Phase 2 shields). Boss: Trinexx (40 HP × 3 heads — fire head vulnerable to Ice Rod, ice head to Fire Rod; Phase 2 shell breaks into snake form, bump 0x07).
- Quake Medallion to open entrance (hit 3 stakes in order first).
- Cane of Somaria platforms for lava traversal.
- Enemies: Terrorpin (HP 8), Chain Chomp (HP 5, bump 0x07), Red Hardhat Beetle (HP 32).

### Assets

**Sprites**
- 7 bosses: Helmasaur King (mask on/off, tail swipe, fireball), Arrghus (eye + puffs orbiting/detached), Mothula (beam fire, wing flutter), Blind (3 phase heads, floating head fireballs), Kholdstare (ice shell, 3 eyeballs), Vitreous (main eye, swarm of small eyes, lightning), Trinexx (fire head, ice head, center head, Phase 2 snake)
- Dungeon-specific enemies not yet built: Mimics, Red/Blue Bari, Kyameron, Slime, Swamola, Gibdo, Sluggula, Pengator, Freezor, Wizzrobe, Pokey, Gibo, Terrorpin, Chain Chomp, Red Hardhat Beetle, Deadrock, Kodongo, Zazaks (blue/red), Yellow Stalfos, Floating Stalfos Head
- Stalfos Knight (collapse pile, reform, bomb-kill)
- Maiden NPCs (7 crystals — each with brief rescued dialogue)
- Like-Like (shield-eating enemy, Thief archetype from Phase 3 framework)

**Tilemaps**
- 7 dungeon tilesets: Palace of Darkness (dark stone), Swamp Palace (flooded/drained rooms), Skull Woods (forest-interior hybrid), Thieves' Town (cell/hideout), Ice Palace (ice floors, frozen walls), Misery Mire (muddy, vine-covered), Turtle Rock (lava, pipe platforms)
- Conveyor floor tiles (directional arrows)

**VFX**
- Helmasaur King mask crack/shatter
- Arrghus puff pull (Hookshot trail to puff, puff detach)
- Mothula spike projectile wave, conveyor floor direction arrows
- Blind ceiling bomb-blast light beam, head detach + float
- Kholdstare ice shell melt (Fire Rod hits), ice block fall from ceiling + 4-way shatter
- Vitreous small-eye launch, lightning bolt
- Trinexx fire breath, ice tiles, shell break, Phase 2 snake
- Stalfos Knight collapse pile, reform animation
- Ice floor slide trail
- Crystal reward acquisition (maiden freed from crystal)

**Audio**
- 7 dungeon music tracks (may share a Dark World dungeon theme with per-dungeon variations, or unique per dungeon)
- 7 boss SFX sets (unique per boss: mask crack, puff pull, spike launch, head detach, ice shatter, lightning, fire/ice breath)
- Ice floor slide SFX
- Wallmaster grab SFX, warp SFX
- Crystal acquisition fanfare (maiden freed)
- Stalfos Knight collapse SFX, reform SFX, bomb-kill SFX

---

## Phase 19 — Endgame, Heart Pieces & Secrets

The final dungeon, final boss, all 24 Heart Pieces, and hidden content throughout both worlds.

**Ganon's Tower (Dungeon 11):**
- Requires all 7 Crystals to unseal (7 Maidens break the seal — cutscene)
- Largest dungeon: combines all puzzle types from Phases 6/17/18 (push-blocks, crystal switches, torch puzzles, ice floors, Hookshot gaps, Somaria platforms, dark rooms)
- Key item: Red Mail (~75% damage reduction — extends Phase 2 armor, final tier)
- Mini-boss encounters: Armos Knights rematch, Lanmolas rematch, Moldorm rematch (reuse Phase 17 assets, original stats)
- Boss: Agahnim rematch — 3 copies appear, 2 are fakes (lighter color palette). Only real Agahnim's energy balls can be reflected. Same reflect mechanic as Phase 17.
- On Agahnim defeat: Pyramid of Power opens for final fight

**Ganon (Final Boss — Pyramid of Power):**
- HP 255 total, bump 0x09 (8 hearts Green Mail, 6 Blue, 3 Red)
- Phase 1 (Trident): throws trident boomerang-style, teleports between attacks. 12 sword hits to advance.
- Phase 2 (Firebats): spins trident summoning ring of firebats. 12 hits to advance.
- Phase 3 (Teleport): alternates top/bottom positions, 50% spiral fire attack. Each hit triggers ground stomp removing floor tiles (pit hazard). 4 stomps to advance.
- Phase 4 (Final): torches in room must stay lit (Fire Rod). Ganon only visible when torches are lit. Only Silver Arrows deal real damage — 24 damage each, 4 arrows to kill. All other weapons deal 0 in this phase.
- On defeat: Triforce acquisition, ending sequence

**24 Heart Pieces (full placement):**
- 12 Light World locations per SPEC §5 (Lost Woods bush pit, Kakariko Well bomb wall, Thieves' Hideout, 15-Second Race reward, Swamp Ruins drain, Sanctuary dash rocks, Desert Cave bomb wall, Desert Palace ridge, Zora's Falls, Spectacle Rock cave, Spectacle Rock top via Mirror, Lumberjack Tree post-Agahnim)
- 12 Dark World locations per SPEC §5 (Pyramid right side, Digging Game, Treasure Chest Game, Stake Field, Haunted Grove Mirror, Ice Lake Mirror, Ghostly Garden, Skull Woods Cape past bumper, Misery Mire left cave, Misery Mire Mirror ridge, Turtle Rock invisible path, Turtle Rock Mirror ledge)
- Each Heart Piece verifies correct item gate (e.g., Spectacle Rock requires Dark World access + Mirror; Skull Woods requires Magic Cape; etc.)

**Secret caves & hidden content:**
- Fairy Fountains: full-heal caves placed throughout both worlds (at least 6 LW, 4 DW)
- Spike Cave (Cane of Byrna location — Death Mountain DW)
- Magic Cape cave (Graveyard — dash into tombstone)
- Ice Rod cave (east of Lake Hylia — bomb wall)
- Secret rooms behind bomb-able walls in all dungeons (retroactive: add hidden rooms to Phase 17/18 dungeons)
- Hidden Rupee caches, Rupee Men (2 NPCs, 300 Rupees each)
- Chris Houlihan Room (45 Blue Rupees — secret failsafe room accessed via specific dash sequence)

**Ending sequence:**
- Triforce wish cutscene, world restoration montage, credits roll

### Assets

**Sprites**
- Ganon: 4-phase animations (trident throw/spin, teleport, firebat ring, spiral fire, ground stomp, torch-darkness form)
- Ganon's trident (thrown projectile, spinning), firebats (ring formation, individual)
- Silver Arrow impact on Ganon (unique hit flash)
- Red Mail (inventory icon, Link palette swap — red tunic)
- Agahnim clone variants (real + 2 fakes — lighter palette)
- Triforce (assembled, glowing)
- Ending sequence characters (Zelda, King, Sages, villagers restored)

**Tilemaps**
- Ganon's Tower tileset (multi-floor, reuses elements from prior dungeon tilesets + unique dark tower elements)
- Pyramid of Power boss arena (destructible floor tiles for Phase 3 stomps)
- Secret cave interiors, fairy fountain variants
- Chris Houlihan Room (small room with 45 blue Rupee sprites)

**VFX**
- Ganon teleport smoke, trident throw trail, firebat ring formation, spiral fire pattern
- Floor tile crumble (Phase 3 stomp), pit reveal
- Silver Arrow hit flash (unique golden impact)
- Triforce glow, wish sequence light, world restoration montage transitions
- 7 Maidens seal-break cutscene (Ganon's Tower entrance)

**Audio**
- Ganon's Tower dungeon music
- Ganon boss battle music (unique final boss theme)
- Ganon Phase transition SFX (rumble, roar)
- Trident throw SFX, firebat screech SFX, spiral fire whoosh, floor stomp SFX
- Silver Arrow hit SFX (distinct from normal arrow)
- Ganon defeat roar + explosion chain
- Triforce acquisition fanfare
- Ending/credits music
- Staff roll theme
