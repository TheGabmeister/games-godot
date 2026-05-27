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
        Bus<EV_ScoreEarned>.Emit(new EV_ScoreEarned { value = ScoreValue });
        Bus<EV_Pickup_Coin>.Emit(new EV_Pickup_Coin { value = CoinValue });
        Bus<EV_TextSpawn>.Emit(new EV_TextSpawn { text = ScoreValue.ToString(), position = GlobalPosition });
        QueueFree();
    }
}
