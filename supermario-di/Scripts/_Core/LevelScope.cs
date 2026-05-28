using System;
using System.Collections.Generic;
using Godot;

namespace SMB;

[Meta(typeof(IAutoNode))]
public partial class LevelScope : Node2D,
    IProvide<LevelScope>,
    IProvide<GoalTrigger>
{
    [Export] public Marker2D PlayerStart;
    [Export] public GoalTrigger GoalTrigger;
    [Export] private Node _markerRoot;

    public IReadOnlyList<Node> Markers => _markers;

    private readonly List<Node> _markers = new();

    public override void _Notification(int what) => this.Notify(what);

    LevelScope IProvide<LevelScope>.Value() => this;
    GoalTrigger IProvide<GoalTrigger>.Value() => GoalTrigger;

    public override void _Ready()
    {
        if (PlayerStart == null)
            throw new InvalidOperationException($"{nameof(LevelScope)} requires {nameof(PlayerStart)} to be assigned in the editor.");

        if (GoalTrigger == null)
            throw new InvalidOperationException($"{nameof(LevelScope)} requires {nameof(GoalTrigger)} to be assigned in the editor.");

        if (_markerRoot == null)
            throw new InvalidOperationException($"{nameof(LevelScope)} requires {nameof(_markerRoot)} to be assigned in the editor.");

        _markers.Clear();
        foreach (var child in _markerRoot.GetChildren())
            _markers.Add(child);

        this.Provide();
    }
}
