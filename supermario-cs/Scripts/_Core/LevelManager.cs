using System;
using Godot;

namespace SMB;

public partial class LevelManager : Node2D
{
    [Export] public Marker2D PlayerStart;
    [Export] public GoalTrigger GoalTrigger;

    public override void _Ready()
    {
        if (PlayerStart == null)
            throw new InvalidOperationException($"{nameof(LevelManager)} requires {nameof(PlayerStart)} to be assigned in the editor.");

        if (GoalTrigger == null)
            throw new InvalidOperationException($"{nameof(LevelManager)} requires {nameof(GoalTrigger)} to be assigned in the editor.");
    }
}
