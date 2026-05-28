using Godot;

namespace SMB;

public partial class Coin : Area2D
{
    [Export] public int ScoreValue = 200;
    [Export] public int CoinValue = 1;

    private bool _collected;

    public override void _Ready()
    {
        BodyEntered += OnBodyEntered;
    }

    private void OnBodyEntered(Node2D body)
    {
        if (_collected) return;
        _collected = true;
        PlaySfx(_clip);
        Events.EmitCoinPickedUp(ScoreValue, CoinValue, GlobalPosition);
        QueueFree();
    }
}
