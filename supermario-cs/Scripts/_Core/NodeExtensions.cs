using System;
using Godot;

namespace SuperMario;

public static class NodeExtensions
{
    public static GameInstance GetGameInstance(this Node node)
    {
        var tree = node.GetTree();
        if (tree == null)
            throw new InvalidOperationException($"{nameof(GetGameInstance)} requires a node inside the scene tree.");

        return tree.Root.GetNode<GameInstance>(nameof(GameInstance));
    }

    public static GameMode GetGameMode(this Node node)
    {
        var gameMode = node.GetGameInstance().CurrentSession;
        if (gameMode == null)
            throw new InvalidOperationException($"{nameof(GetGameMode)} requires an active game session.");

        return gameMode;
    }

    public static GameEvents GetGameEvents(this Node node)
    {
        return node.GetGameMode().Events;
    }

    public static void SpawnText(this Node node, string text, Vector2 worldPosition)
    {
        node.GetGameMode().TextSpawner.SpawnText(text, worldPosition);
    }

    public static void PlaySfx(this Node node, AudioStream sound)
    {
        node.GetGameInstance().Sfx.Play(sound);
    }

    public static void PlayMusic(this Node node, AudioStream sound)
    {
        node.GetGameInstance().Music.Play(sound);
    }
}
