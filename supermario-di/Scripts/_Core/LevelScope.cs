using System;
using Godot;

namespace SMB;

[Meta(typeof(IAutoNode))]
public partial class LevelScope : Node2D,
    IProvide<LevelScope>,
    IProvide<GoalTrigger>
{
    [Export] public Marker2D PlayerStart;
    [Export] public GoalTrigger GoalTrigger;

    public override void _Notification(int what) => this.Notify(what);

    LevelScope IProvide<LevelScope>.Value() => this;
    GoalTrigger IProvide<GoalTrigger>.Value() => GoalTrigger;

    public override void _Ready()
    {
        if (PlayerStart == null)
            throw new InvalidOperationException($"{nameof(LevelScope)} requires {nameof(PlayerStart)} to be assigned in the editor.");

        if (GoalTrigger == null)
            throw new InvalidOperationException($"{nameof(LevelScope)} requires {nameof(GoalTrigger)} to be assigned in the editor.");

        this.Provide();
    }
}
