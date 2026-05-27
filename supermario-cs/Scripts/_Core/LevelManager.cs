using System;
using Godot;

namespace SMB;

public partial class LevelManager : Node2D
{
    [Export] public Marker2D PlayerStart;
    [Export] public GoalTrigger GoalTrigger;
    [Export] private Node _markerRoot;

    public Godot.Collections.Array<Node> Markers => _markerRoot.GetChildren();

    public override void _Ready()
    {
        if (PlayerStart == null)
            throw new InvalidOperationException($"{nameof(LevelManager)} requires {nameof(PlayerStart)} to be assigned in the editor.");

        if (GoalTrigger == null)
            throw new InvalidOperationException($"{nameof(LevelManager)} requires {nameof(GoalTrigger)} to be assigned in the editor.");

        if (_markerRoot == null)
            throw new InvalidOperationException($"{nameof(LevelManager)} requires {nameof(_markerRoot)} to be assigned in the editor.");
    }
}
