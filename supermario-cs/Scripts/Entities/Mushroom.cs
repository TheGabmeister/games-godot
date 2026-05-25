using System;
using Godot;

namespace SuperMario;

public partial class Mushroom : CharacterBody2D, IScoreEventSource
{
    public event Action<int> ScoreEarned;
    public event Action<string, Vector2> TextPopupRequested;

    [Export] public Area2D PickupTrigger;

    private bool _collected;

    public override void _Ready()
    {
        PickupTrigger.BodyEntered += OnPickedUp;
    }

    private void OnPickedUp(Node2D body)
    {
        if (_collected || body is not PlayerController player) return;
        _collected = true;
        ScoreEarned?.Invoke(Constants.MushroomScore);
        TextPopupSpawner.Spawn(this, Constants.MushroomScore.ToString(), GlobalPosition);
        player.ApplyMushroom();
        QueueFree();
    }
}
