using Godot;

namespace SMB;

public partial class BrickBlock : StaticBody2D, IBumpable
{
    [Export] public Bumpable Bumpable;

    private IScoreAwarder _scoreAwarder;

    public static BrickBlock Create(Vector2 globalPosition, IScoreAwarder scoreAwarder)
    {
        var scene = GD.Load<PackedScene>(Config.BrickBlockScenePath);
        var bb = scene.Instantiate<BrickBlock>();
        bb.GlobalPosition = globalPosition;
        bb._scoreAwarder = scoreAwarder;
        return bb;
    }

    public override void _Ready()
    {
    }

    public void OnBumped(PlayerController player)
    {
        if (player.CanBreakBricks)
        {
            _scoreAwarder.AwardScore(Constants.BrickBreakScore);
            QueueFree();
            return;
        }
        Bumpable.Bump();
    }
}
