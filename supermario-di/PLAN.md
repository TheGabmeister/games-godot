# AutoInject Conversion Plan

## Goal

Use AutoInject as the main dependency boundary for the game. Keep the code simple: no unit tests required, no interface-only ceremony, and concrete dependencies are fine when they are clearer.

## Installed

- AutoInject runtime source is installed at `Addons/AutoInject/src`.
- AutoInject docs, license, and icon are installed at `Addons/AutoInject`.
- `supermario-cs.csproj` references:
  - `Chickensoft.GodotNodeInterfaces` 3.0.10
  - `Chickensoft.Introspection` 3.0.2
  - `Chickensoft.Introspection.Generator` 3.0.2

The downloaded AutoInject repo had an empty `Chickensoft.AutoInject/src`, so the runtime source was copied from its `Chickensoft.AutoInject.Tests/src` folder. `Chickensoft.GodotNodeInterfaces` 3.0.10 is used because it matches this project's `Godot.NET.Sdk/4.6.2`.

## Executed So Far

- `GameInstance` is now the root provider for `GameInstance`, `MusicManager`, and `SfxManager`.
- `GameMode` is now the session provider for `GameMode`, `SaveData`, `TextSpawner`, `IScoreAwarder`, and `ICoinCollector`.
- `LevelManager` has been replaced by `LevelScope`. Keep the level root concept, but not the manager name.
- `GameServices` and the static global service lookup were removed.
- HUD, main menu, pickups, blocks, player, projectiles, and key enemy spawners now use AutoInject dependencies.
- Factory methods for spawned pickups and blocks now only receive spawn position.
- `SfxManager` now loads every WAV in `Sfx/` and exposes named methods for gameplay sounds.
- The old `Constants` grab-bag has been removed. `PhysicsLayers` remains in code for named bit masks.
- Combined score/game rules live in `Resources/GameRules.tres`.
- Shared player movement/size tuning lives in `Resources/PlayerTuning.tres`.
- Local prefab tuning lives on exported scene properties in the relevant `.tscn` files.

## Current Scope Model

- `GameInstance`: app/root scope. Owns long-lived audio services and scene boot flow.
- `GameMode`: session scope. Owns campaign progress, save data, HUD, text popups, current level, and current player.
- `LevelScope`: level scope. Owns level start/goal/marker references and provides the level boundary.
- Entities, pickups, projectiles, and UI: dependents. They request the concrete services they need.

## Tuning Sources

- `Scripts/_Core/PhysicsLayers.cs`: named collision bit masks used by runtime-spawned nodes and physics queries.
- `Resources/GameRules.tres`: starting lives, coins per life, score values.
- `Resources/PlayerTuning.tres`: player speed, gravity, jump, sizes, invulnerability, stomp, and fireball limit.
- Scene files: prefab-local tuning like Bullet Bill speed, Hammer Bro timing, fireball physics, block bump animation, and moving platform settings.

## AutoInject Pattern

Every AutoInject node should have metadata and notification forwarding:

```csharp
[Meta(typeof(IAutoNode))]
public partial class SomeNode : Node
{
    public override void _Notification(int what) => this.Notify(what);
}
```

Providers implement `IProvide<T>` and call `this.Provide()` once their values are ready:

```csharp
[Meta(typeof(IAutoNode))]
public partial class LevelScope : Node2D, IProvide<LevelScope>
{
    public override void _Notification(int what) => this.Notify(what);

    LevelScope IProvide<LevelScope>.Value() => this;

    public override void _Ready()
    {
        this.Provide();
    }
}
```

Dependents use `[Dependency]`:

```csharp
[Dependency] public SfxManager Sfx => this.DependOn<SfxManager>();
```

## SFX Coverage

`SfxManager` should remain the only place that knows direct `res://Sfx/*.wav` paths.

Current named sounds:

- `Block_Break.wav`
- `Block_Bump.wav`
- `Coin.wav`
- `Fireball.wav`
- `Flagpole.wav`
- `GameOver.wav`
- `Kick.wav`
- `OneUp.wav`
- `Pipe.wav`
- `PlayerDeath.wav`
- `PlayerJump.wav`
- `PlayerJump_Big.wav`
- `PlayerPower_Down.wav`
- `PlayerPower_Up.wav`
- `PlayerStomp.wav`
- `StageClear.wav`
- `Warning.wav`

If new gameplay events are added, inject `SfxManager` and call a named method instead of loading audio streams in the gameplay class.

## Remaining Cleanup

- Convert simple child-node wiring to AutoConnect where it improves clarity:
  - `PlayerController`: `Visual`, `CollisionShape2D`, `Blinker`, `Muzzle`
  - `Hud`: label exports
  - `MainMenuController` and `GameOverController`: buttons
- Consider replacing static `Config` scene/resource paths with a `GameConfig : Resource` provided by `GameInstance`.
- Consider a dedicated spawn service if `GameMode` grows too much more level-spawning logic.
- Keep gameplay interfaces like `IBumpable`, `IStompable`, `IFireballHittable`, and `IStarHittable`; they are behavior contracts, not DI scaffolding.

## Manual Checks

No unit tests are required. Use these quick play checks:

- Boot reaches main menu.
- Start game loads world 1-1.
- Coin pickup updates score, coins, text popup, and coin sound.
- Start-game pipe, jump, fireball, stomp, shell kick, power-up, power-down, death, and one-up sounds play.
- Block bump and block break sounds play.
- Bullet Bill warning sound plays when cannons fire.
- Flagpole/stage-clear and game-over sounds play at transitions.
- Enemy spawning and projectile spawning still work.
- Level completion and player death still transition correctly.
