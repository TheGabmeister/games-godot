using System;
using Godot;

namespace SMB;

public partial class BrickBlock : StaticBody2D, IBumpable
{
    [Export] public Bumpable Bumpable;

    public event Action<int> ScoreEarned;

    public static BrickBlock Create(Vector2 globalPosition)
    {
        var scene = GD.Load<PackedScene>(Config.BrickBlockScenePath);
        var bb = scene.Instantiate<BrickBlock>();
        bb.GlobalPosition = globalPosition;
        return bb;
    }

    public void OnBumped(PlayerController player)
    {
        if (player.CanBreakBricks)
        {
            ScoreEarned?.Invoke(Constants.BrickBreakScore);
            QueueFree();
            return;
        }
        Bumpable.Bump();
    }
}
