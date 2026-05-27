using System;
using Godot;

namespace SMB;

public partial class Starman : CharacterBody2D
{
    [Export] public Area2D PickupTrigger;

    private IScoreAwarder _scoreAwarder;
    private bool _collected;

    public static Starman Create(Vector2 globalPosition, IScoreAwarder scoreAwarder)
    {
        var scene = GD.Load<PackedScene>(Config.StarmanScenePath);
        var s = scene.Instantiate<Starman>();
        s.GlobalPosition = globalPosition;
        s.Initialize(scoreAwarder);
        return s;
    }

    public void Initialize(IScoreAwarder scoreAwarder)
    {
        _scoreAwarder = scoreAwarder ?? throw new ArgumentNullException(nameof(scoreAwarder));
    }

    public override void _Ready()
    {
        EnsureInitialized();
        PickupTrigger.BodyEntered += OnPickedUp;
    }

    private void OnPickedUp(Node2D body)
    {
        if (_collected || body is not PlayerController player) return;
        _collected = true;
        _scoreAwarder.AwardScore(Constants.StarmanPickupScore);
        SpawnText(Constants.StarmanPickupScore.ToString(), GlobalPosition);
        player.ApplyStarman();
        QueueFree();
    }

    private void EnsureInitialized()
    {
        if (_scoreAwarder == null)
            throw new InvalidOperationException($"{nameof(Starman)} requires a score service before it enters the tree.");
    }
}
