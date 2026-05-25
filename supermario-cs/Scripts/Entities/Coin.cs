using System;
using Godot;

namespace SuperMario;

public partial class Coin : Area2D, IScoreEventSource, ITextPopupEventSource
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
        if (_collected || body is not PlayerController) return;
        _collected = true;
        ScoreEarned?.Invoke(Constants.CoinValue);
        TextPopupRequested?.Invoke("+" + Constants.CoinValue, GlobalPosition);
        QueueFree();
    }
}
