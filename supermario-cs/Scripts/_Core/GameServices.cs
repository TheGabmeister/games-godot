using System;
using Godot;

namespace SMB;

public static class GameServices
{
    public static GameInstance GetGameInstance()
    {
        if (Engine.GetMainLoop() is not SceneTree tree)
            throw new InvalidOperationException($"{nameof(GetGameInstance)} requires an active scene tree.");

        return tree.Root.GetNode<GameInstance>(nameof(GameInstance));
    }

    public static GameMode GetGameMode()
    {
        var gameMode = GetGameInstance().CurrentSession;
        if (gameMode == null)
            throw new InvalidOperationException($"{nameof(GetGameMode)} requires an active game session.");

        return gameMode;
    }

    public static void PlayMusic(AudioStream sound)
    {
        GetGameInstance().Music.Play(sound);
    }

    public static void PlaySfx(AudioStream sound)
    {
        GetGameInstance().Sfx.Play(sound);
    }
}
