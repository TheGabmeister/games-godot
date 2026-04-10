Code Review Results
A. Duplicated Code (DRY violations)
1. Block bump animation — copy-pasted 3 times

brick_block.gd:19-27
question_block.gd:26-34
hidden_block.gd:25-33
All three have identical bump timer + sine offset + queue_redraw() logic. Should be a shared base class or helper function.

2. Tileset creation — two files that are 90% identical

terrain_tileset.gd vs underground_tileset.gd
The only difference is two color values. Everything else (image creation, atlas source, physics layer, collision polygons) is duplicated. Should be a single parameterized create_tileset(top_color, fill_color).

3. Item emergence logic — copy-pasted across mushroom, fire_flower, starman

All three items have the same _emerging / _emerge_initialized / lazy-init-on-first-tick pattern with identical math. Should be an ItemBase class.

4. Collision disable boilerplate — repeated in enemy_base, goomba, koopa_shell


collision_layer = 0
collision_mask = 0
_hitbox.set_deferred("monitoring", false)
_hitbox.set_deferred("monitorable", false)
Repeated in 3+ files. Should be a _disable_all_collision() helper on enemy_base.

5. GameManager reset — two nearly identical methods

game_manager.gd:41-52 (start_new_game)
game_manager.gd:55-63 (reset_for_title)
Same 6 variable resets, only differs in what happens after. Extract _reset_state().

6. Grow/Shrink states — mirror images of each other

grow_state.gd vs shrink_state.gd
The process_frame() methods are identical except which power state goes to which. Could share a base TransformState.

B. Performance Issues
7. load() at runtime in AudioManager

audio_manager.gd:58 and audio_manager.gd:83
load(path) performs synchronous disk I/O every time an SFX or music track plays. This will cause frame stutters. Should preload() or cache in a dictionary on first load.

8. Node2D.new() + set_script() pattern in effects_manager

effects_manager.gd:21-26, repeated 4 times
Creating bare Node2D and injecting scripts dynamically is slower than PackedScene.instantiate() and defeats editor tooling. These effects should be .tscn scenes.

9. queue_redraw() called every frame unconditionally

question_block.gd:35 — redraws every frame even when not bumping (only _pulse_time changes)
All enemy drawers (goomba_drawer, koopa_drawer, koopa_shell_drawer) call queue_redraw() every frame even when stationary/offscreen
Should be conditional: only redraw when visual state actually changed.

10. get_tree().get_nodes_in_group("player") in hot paths

koopa_shell.gd:78 — on every stomp
piranha_plant.gd _player_is_nearby() — every physics frame
Tree traversal on every call. Cache the player reference.

C. Architecture Issues
11. Player controller is a God Object
player_controller.gd handles: movement, gravity, camera management, collision shape updates, 3 timer systems, star power, invincibility, fireball management, stomp combos, death handling, power-ups, damage, pipe entry, and flagpole entry. That's too many responsibilities for one file.

12. States call private methods on controller

grow_state.gd and shrink_state.gd call player._update_collision_shape()
shrink_state.gd calls player._start_invincibility()
flagpole_state.gd reads GameManager._timer_active (private var on an autoload!)
Underscore-prefixed members are meant to be private. These should be exposed as public APIs.

13. PiranhaPlant doesn't extend EnemyBase but reimplements its interface
piranha_plant.gd duck-types the full enemy API (is_active(), is_dead(), is_dangerous(), stomp_kill(), non_stomp_kill(), shell_kill(), die()) without inheriting from enemy_base.gd. If the interface changes, this silently breaks.

14. Unused _camera field in CameraEffects
camera_effects.gd:7 — _camera is stored via register_camera() on line 40 but never read anywhere. Dead code.

D. Code Smells
15. Vector2.ZERO used as null sentinel in AudioManager
audio_manager.gd:61 — if position == Vector2.ZERO: return. What if a legitimate SFX source is at world origin? Ambiguous API.

16. Redundant else branch in CameraEffects
camera_effects.gd:24-25 — sets _shake_offset = Vector2.ZERO every frame even when no shake is active. Once the shake ends (line 22-23 handles that), this is just wasted assignment every subsequent frame.

17. Hardcoded state name strings everywhere
&"IdleState", &"JumpState", &"FallState" etc. are scattered across all state files and the controller. A rename in the scene tree silently breaks everything with no compile-time error.

18. Inconsistent queue_free() vs call_deferred("queue_free")

goomba.gd uses queue_free() directly
koopa.gd and enemy_base.gd use call_deferred("queue_free")
Should be consistent. During physics callbacks, deferred is safer.

19. Magic numbers throughout drawing code
Every _draw() method is full of unexplained pixel offsets (-8, 0.06, 192.0, 768.0, 512.0, -200.0, 500.0, etc.). The parallax controller alone has dozens. Named constants would make these self-documenting.

20. Level layouts hardcoded as code, not data
Pit positions, platform positions, stair coordinates are all baked into GDScript methods like _get_pits() returning raw Vector2i arrays. A data-driven approach (dictionaries, resources, or even JSON) would be more maintainable and make it possible to add levels without writing code.

E. Minor but Noticeable
21. _player_spawn set but never read in level_base.gd — dead variable.

22. Unused @onready vars in pause_menu.gd — _panel and _label are cached but never referenced.

23. const P := preload("res://scripts/color_palette.gd") appears in 21 files — not a bug, but if this were an autoload instead, every drawer file would be one line shorter.

24. Format string "%06d" in HUD and time warning threshold 100 are magic values.

What I'd prioritize if cleaning this up:
Priority	Issue	Impact
1	Extract block bump base class (#1)	Eliminates 3-way duplication
2	Parameterize tileset creation (#2)	Eliminates near-identical file
3	Cache load() in AudioManager (#7)	Prevents frame stutters
4	Convert effects to .tscn scenes (#8)	Cleaner, faster, debuggable
5	Extract _reset_state() in GameManager (#5)	Quick win
6	Make private methods public where states need them (#12)	Fixes encapsulation
7	Remove dead code (#14, #21, #22)	Quick cleanup
8	Conditional queue_redraw() (#9)	Performance with many entities
Let me know which ones you want to tackle, or if you want me to dig deeper into any specific area.





move_and_slide() is called twice per frame in the run path because the helper API is inconsistent. player_controller.gd (line 122), player_controller.gd (line 139), run_state.gd (line 18), run_state.gd (line 23), run_state.gd (line 26). This is the sharpest “senior dev will call this out” item: movement helpers should either only mutate velocity or own the whole move step, not both.

Level boot and run-state ownership is split across UI, level scripts, and GameManager, which makes the flow harder to reason about. title_screen.gd (line 30), game_manager.gd (line 41), level_base.gd (line 33), level_base.gd (line 60), level_1_2.gd (line 27), level_1_2.gd (line 38). Public-review criticism here would be “too many places can start/reset a run.”

Several scripts reach directly into autoload internals instead of going through a public API. level_base.gd (line 60), level_1_2.gd (line 38), flagpole_state.gd (line 31), pipe_enter_state.gd (line 53), pipe_enter_state.gd (line 55), pipe_enter_state.gd (line 75). Seniors usually dislike “private-by-convention” members being depended on across systems.

Combat/item interaction is heavily duck-typed and parent-dependent. player_controller.gd (line 117), player_controller.gd (line 240), player_controller.gd (line 277), fireball.gd (line 48), koopa_shell.gd (line 147). The repeated has_method(...) plus area.get_parent() pattern works, but it’s brittle and makes contracts implicit.

GameManager has misleading API boundaries: a getter mutates global state, and callers bypass its life-management helpers. game_manager.gd (line 140), game_manager.gd (line 147), player_controller.gd (line 250), koopa_shell.gd (line 175). A senior reviewer will absolutely notice get_next_level_scene() changing world/level and random scripts doing GameManager.lives += 1.

AudioManager loads assets at play time instead of caching them once. audio_manager.gd (line 55), audio_manager.gd (line 58), audio_manager.gd (line 80), audio_manager.gd (line 83). That’s a classic performance/code-quality critique.

The timer/HUD path does more work than needed by emitting every frame even when the displayed second has not changed. game_manager.gd (line 30), game_manager.gd (line 38), hud.gd (line 31). It’s not huge, but it’s the kind of easy optimization reviewers point out.

There are several always-redrawing nodes that could be gated better. question_block.gd (line 24), question_block.gd (line 36), flagpole.gd (line 76), flagpole.gd (line 77), parallax_controller.gd (line 19), player_drawer.gd (line 25). The worst-looking one is the flagpole, which redraws every frame even when totally idle.

Copy-paste is showing up in a few core systems and will get harder to maintain as the project grows. question_block.gd (line 24), brick_block.gd (line 19), hidden_block.gd (line 25), mushroom.gd (line 27), fire_flower.gd (line 24), starman.gd (line 26), terrain_tileset.gd (line 8), underground_tileset.gd (line 9). Reviewers will read this as “prototype code that hasn’t been consolidated yet.”

Some low-level polish issues make the repo look less finished than it is: magic collision numbers and dead leftovers. kill_zone.gd (line 5), kill_zone.gd (line 6), level_base.gd (line 16), level_1_2.gd (line 13), question_block.gd (line 4), pause_menu.gd (line 3), level_complete.gd (line 3). None of these are severe, but they are the sort of lines seniors mention in review comments.