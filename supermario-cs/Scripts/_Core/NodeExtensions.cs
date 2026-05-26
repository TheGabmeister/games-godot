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
}
