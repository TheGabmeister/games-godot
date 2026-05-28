# AutoInject Conversion Plan

## Goal

Move this project away from static service lookup and manual dependency wiring, using AutoInject providers and dependents instead. Keep it simple: no unit tests, no mock-first interfaces, and concrete classes are fine when they make the code easier to follow.

## Current Install

- AutoInject runtime source is installed at `Addons/AutoInject/src`.
- AutoInject docs, license, and icon are installed at `Addons/AutoInject`.
- `supermario-cs.csproj` references AutoInject's required packages:
  - `Chickensoft.GodotNodeInterfaces` 3.0.10
  - `Chickensoft.Introspection` 3.0.2
  - `Chickensoft.Introspection.Generator` 3.0.2

AutoInject source in the downloaded folder was empty under `Chickensoft.AutoInject/src`, so the runtime source was copied from the local repo's `Chickensoft.AutoInject.Tests/src` folder, where the actual `Chickensoft.AutoInject` namespace files are present.

`Chickensoft.GodotNodeInterfaces` 3.0.10 is used because it targets `GodotSharp >= 4.6.2`, matching this project's `Godot.NET.Sdk/4.6.2`.

## Basic Pattern

Every AutoInject node should:

```csharp
using Chickensoft.AutoInject;
using Chickensoft.Introspection;

[Meta(typeof(IAutoNode))]
public partial class SomeNode : Node
{
    public override void _Notification(int what) => this.Notify(what);
}
```

Provider nodes implement `IProvide<T>` and call `this.Provide()` once their values are ready:

```csharp
[Meta(typeof(IAutoNode))]
public partial class GameMode : Node, IProvide<GameMode>
{
    public override void _Notification(int what) => this.Notify(what);

    GameMode IProvide<GameMode>.Value() => this;

    public void OnReady()
    {
        this.Provide();
    }
}
```

Dependent nodes use `[Dependency]` properties and read them after `OnResolved()`:

```csharp
[Dependency] public GameMode GameMode => this.DependOn<GameMode>();

public void OnResolved()
{
    GameMode.AwardScore(Constants.CoinValue);
}
```

## Phase 1: Make Root Services Providers

Convert `GameInstance` first because it owns the long-lived services.

- Add `[Meta(typeof(IAutoNode))]` and `_Notification`.
- Implement providers for:
  - `GameInstance`
  - `MusicManager`
  - `SfxManager`
- Move `_Ready()` body to `OnReady()` or call `this.Provide()` at the end of `_Ready()`.
- Keep the autoload as-is in `project.godot`.

Suggested provider list:

```csharp
public partial class GameInstance : Node,
    IProvide<GameInstance>,
    IProvide<MusicManager>,
    IProvide<SfxManager>
```

## Phase 2: Make Session Services Providers

Convert `GameMode` next because it owns the current session, level, HUD, text spawner, score, coins, lives, and level loading.

- Add `[Meta(typeof(IAutoNode))]` and `_Notification`.
- Implement providers for:
  - `GameMode`
  - `SaveData`
  - `TextSpawner`
  - `IScoreAwarder` or concrete `GameMode`
  - `ICoinCollector` or concrete `GameMode`
- Call `this.Provide()` after `TextSpawner` and the first level are created.
- Prefer concrete `GameMode` dependencies unless an existing interface is already cleaner.

This lets coins, blocks, pickups, enemies, projectiles, and UI ask for the session directly instead of reaching through `GameServices`.

## Phase 3: Replace `GameServices` Calls

Replace static helpers gradually.

- Replace `PlayMusic(sound)` with a dependency on `MusicManager` or `GameInstance`.
- Replace `PlaySfx(sound)` with a dependency on `SfxManager` or `GameInstance`.
- Replace `GetGameMode()` with `[Dependency] public GameMode GameMode => this.DependOn<GameMode>();`.
- Replace `SpawnText(...)` with `[Dependency] public TextSpawner TextSpawner => this.DependOn<TextSpawner>();`.

Start with the small files that only call one helper:

- `Coin`
- `Mushroom`
- `FireFlower`
- `Starman`
- `OneUp`
- `BulletBillCannon`
- `KoopaTroopa`
- `KoopaParatroopa`
- `HammerBro`

After these are converted, remove `global using static SMB.GameServices;` from `Scripts/_Core/GlobalUsings.cs`.

## Phase 4: Stop Passing Dependencies Through Factory Methods

Several spawned objects currently receive dependencies in `Create(...)` methods. Convert those to dependency lookup.

- `Coin.Create(globalPosition, scoreAwarder, coinCollector)` becomes `Coin.Create(globalPosition)`.
- `QuestionBlock.Create(globalPosition, scoreAwarder, coinCollector)` becomes `QuestionBlock.Create(globalPosition)`.
- `BrickBlock.Create(globalPosition, scoreAwarder)` becomes `BrickBlock.Create(globalPosition)`.
- `Mushroom.Create(globalPosition, scoreAwarder)` becomes `Mushroom.Create(globalPosition)`.
- `Starman.Create(globalPosition, scoreAwarder)` becomes `Starman.Create(globalPosition)`.
- `FireFlower.Create(globalPosition, scoreAwarder)` becomes `FireFlower.Create(globalPosition)`.

The spawned node must be added under `GameMode` or `LevelManager` so it has a provider ancestor before it resolves dependencies.

## Phase 5: Use AutoConnect For Node References

After dependency injection is working, replace simple `GetNode` calls with `[Node]`.

Good first candidates:

- `PlayerController` fields: `Visual`, `CollisionShape2D`, `Blinker`, `Muzzle`
- `GameOverController` continue button
- `MainMenuController` start button
- `LevelManager` assigned child nodes, if the scene paths are stable

Keep exported fields where designer assignment is clearer than path-based lookup.

## Phase 6: Cleanup

Once the conversion builds and the game flow still works:

- Delete `Scripts/_Core/GameServices.cs`.
- Delete `global using static SMB.GameServices;`.
- Remove constructor/factory parameters that only existed to pass services around.
- Keep existing gameplay interfaces like `IBumpable`, `IStompable`, and `IFireballHittable`; they describe gameplay behavior, not dependency wiring.

## Manual Checks

No unit tests are required. Use these quick play checks after each phase:

- Boot reaches main menu.
- Start game loads world 1-1.
- Coin pickup updates score, coins, and text popup.
- Mushroom, fire flower, starman, and one-up still apply effects.
- Enemy spawning and projectile spawning still work.
- Level completion and player death still transition correctly.
