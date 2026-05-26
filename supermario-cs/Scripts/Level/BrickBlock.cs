using Godot;

namespace SMB;

public partial class BrickBlock : StaticBody2D, IBumpable
{
    [Export] public Bumpable Bumpable;

    private GameEvents _events;

    public static BrickBlock Create(Vector2 globalPosition, GameEvents events)
    {
        var scene = GD.Load<PackedScene>(Config.BrickBlockScenePath);
        var bb = scene.Instantiate<BrickBlock>();
        bb.GlobalPosition = globalPosition;
        bb._events = events;
        return bb;
    }

    public void OnBumped(PlayerController player)
    {
        if (player.CanBreakBricks)
        {
            _events.EmitScoreEarned(Constants.BrickBreakScore);
            QueueFree();
            return;
        }
        Bumpable.Bump();
    }
}
