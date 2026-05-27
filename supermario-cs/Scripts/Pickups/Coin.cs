using Godot;

namespace SMB;

public partial class Coin : Area2D
{
    private bool _collected;

    public override void _Ready()
    {
        BodyEntered += OnBodyEntered;
    }

    private void OnBodyEntered(Node2D body)
    {
        if (_collected) return;
        _collected = true;
        Bus<EV_ScoreEarned>.Emit(new EV_ScoreEarned { value = Constants.CoinValue });
        Bus<EV_Pickup_Coin>.Emit(new EV_Pickup_Coin { value = 1 });
        Bus<EV_TextSpawn>.Emit(new EV_TextSpawn { text = Constants.CoinValue.ToString(), position = GlobalPosition });
        QueueFree();
    }
}
