using System;
using Godot;

namespace SMB;

public partial class Mushroom : CharacterBody2D
{
    [Export] public Area2D PickupTrigger;

    private IScoreAwarder _scoreAwarder;
    private bool _collected;

    public static Mushroom Create(Vector2 globalPosition, IScoreAwarder scoreAwarder)
    {
        var scene = GD.Load<PackedScene>(Config.MushroomScenePath);
        var m = scene.Instantiate<Mushroom>();
        m.GlobalPosition = globalPosition;
        m.Initialize(scoreAwarder);
        return m;
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
        _scoreAwarder.AwardScore(Constants.MushroomScore);
        SpawnText(Constants.MushroomScore.ToString(), GlobalPosition);
        player.ApplyMushroom();
        QueueFree();
    }

    private void EnsureInitialized()
    {
        if (_scoreAwarder == null)
            throw new InvalidOperationException($"{nameof(Mushroom)} requires a score service before it enters the tree.");
    }
}
