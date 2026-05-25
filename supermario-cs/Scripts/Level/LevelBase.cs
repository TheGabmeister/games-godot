using System;
using System.Collections.Generic;
using Godot;

namespace SuperMario;

public partial class LevelBase : Node2D
{
    public event Action<int> ScoreEarned;
    public event Action<string, Vector2> TextPopupRequested;

    [Export] public Marker2D PlayerStart;
    [Export] public GoalTrigger GoalTrigger;

    private readonly HashSet<Node> _wiredEventSources = new();

    public override void _Ready()
    {
        if (PlayerStart == null)
            throw new InvalidOperationException($"{nameof(LevelBase)} requires {nameof(PlayerStart)} to be assigned in the editor.");

        if (GoalTrigger == null)
            throw new InvalidOperationException($"{nameof(LevelBase)} requires {nameof(GoalTrigger)} to be assigned in the editor.");

        WireEventSources(this);
    }

    private void OnChildEnteredTree(Node child)
    {
        WireEventSources(child);
    }

    private void WireEventSources(Node root)
    {
        if (!_wiredEventSources.Add(root)) return;
        root.ChildEnteredTree += OnChildEnteredTree;

        if (root is IScoreEventSource scoreSource)
            scoreSource.ScoreEarned += points => ScoreEarned?.Invoke(points);

        if (root is ITextPopupEventSource textPopupSource)
            textPopupSource.TextPopupRequested += (text, worldPosition) =>
                TextPopupRequested?.Invoke(text, worldPosition);

        foreach (var child in root.GetChildren())
            WireEventSources(child);
    }
}
