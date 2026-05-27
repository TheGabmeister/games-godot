using System;
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
        bb.Initialize(scoreAwarder);
        return bb;
    }

    public void Initialize(IScoreAwarder scoreAwarder)
    {
        _scoreAwarder = scoreAwarder ?? throw new ArgumentNullException(nameof(scoreAwarder));
    }

    public override void _Ready()
    {
        EnsureInitialized();
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

    private void EnsureInitialized()
    {
        if (_scoreAwarder == null)
            throw new InvalidOperationException($"{nameof(BrickBlock)} requires a score service before it enters the tree.");
    }
}
