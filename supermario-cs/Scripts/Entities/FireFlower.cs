using System;
using Godot;

namespace SuperMario;

public partial class FireFlower : Area2D, IScoreEventSource
{
    public event Action<int> ScoreEarned;
    public event Action<string, Vector2> TextPopupRequested;

    private bool _collected;

    public override void _Ready()
    {
        BodyEntered += OnBodyEntered;
    }

    private void OnBodyEntered(Node2D body)
    {
        if (_collected || body is not PlayerController player) return;
        _collected = true;
        ScoreEarned?.Invoke(Constants.MushroomScore);
        TextPopupSpawner.Spawn(this, Constants.MushroomScore.ToString(), GlobalPosition);
        player.ApplyFireFlower();
        QueueFree();
    }
}
