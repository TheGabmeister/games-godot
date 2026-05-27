using Godot;

namespace SMB;

public partial class BrickBlock : StaticBody2D, IBumpable
{
    [Export] public Bumpable Bumpable;

    private GameEvents _events;

    public static BrickBlock Create(Vector2 globalPosition)
    {
        var scene = GD.Load<PackedScene>(Config.BrickBlockScenePath);
        var bb = scene.Instantiate<BrickBlock>();
        bb.GlobalPosition = globalPosition;
        return bb;
    }

    public override void _Ready()
    {
        _events = GetGameEvents();
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
