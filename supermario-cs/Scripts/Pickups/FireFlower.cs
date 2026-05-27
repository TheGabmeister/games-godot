using System;
using Godot;

namespace SMB;

public partial class FireFlower : Area2D
{
    private IScoreAwarder _scoreAwarder;
    private bool _collected;

    public static FireFlower Create(Vector2 globalPosition, IScoreAwarder scoreAwarder)
    {
        var scene = GD.Load<PackedScene>(Config.FireFlowerScenePath);
        var f = scene.Instantiate<FireFlower>();
        f.GlobalPosition = globalPosition;
        f.Initialize(scoreAwarder);
        return f;
    }

    public void Initialize(IScoreAwarder scoreAwarder)
    {
        _scoreAwarder = scoreAwarder ?? throw new ArgumentNullException(nameof(scoreAwarder));
    }

    public override void _Ready()
    {
        EnsureInitialized();
        BodyEntered += OnBodyEntered;
    }

    private void OnBodyEntered(Node2D body)
    {
        if (_collected || body is not PlayerController player) return;
        _collected = true;
        _scoreAwarder.AwardScore(Constants.MushroomScore);
        SpawnText(Constants.MushroomScore.ToString(), GlobalPosition);
        player.ApplyFireFlower();
        QueueFree();
    }

    private void EnsureInitialized()
    {
        if (_scoreAwarder == null)
            throw new InvalidOperationException($"{nameof(FireFlower)} requires a score service before it enters the tree.");
    }
}
