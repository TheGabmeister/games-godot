using System;
using Godot;

namespace SuperMario;

public partial class Coin : Area2D, IScoreEventSource, ITextPopupEventSource
{
    public event Action<int> ScoreEarned;
    public event Action<string, Vector2> TextPopupRequested;

    private bool _collected;

    public static Coin Create(Vector2 globalPosition)
    {
        var coin = new Coin
        {
            Name = "Coin",
            GlobalPosition = globalPosition,
            CollisionLayer = Layers.PickupTrigger,
            CollisionMask = Layers.Player
        };

        var visual = new ColorRect
        {
            Name = "Visual",
            Position = new Vector2(-8f, -12f),
            Size = new Vector2(16f, 24f),
            Color = new Color(1.0f, 0.85f, 0.15f)
        };
        coin.AddChild(visual);

        var shape = new CollisionShape2D
        {
            Name = "CollisionShape2D",
            Shape = new RectangleShape2D { Size = new Vector2(16f, 24f) }
        };
        coin.AddChild(shape);

        return coin;
    }

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
