using Godot;

namespace SuperMario;

public partial class Coin : Area2D
{
    private bool _collected;

    public override void _Ready()
    {
        BodyEntered += OnBodyEntered;
    }

    private void OnBodyEntered(Node2D body)
    {
        if (_collected || body is not PlayerController) return;
        _collected = true;
        GameSession.Current.Events.EmitScoreEarned(Constants.CoinValue);
        GameSession.Current.Events.EmitTextPopupRequested("+" + Constants.CoinValue, GlobalPosition);
        QueueFree();
    }
}
