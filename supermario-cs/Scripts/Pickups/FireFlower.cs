using Godot;

namespace SMB;

public partial class FireFlower : Area2D
{
    [Export] public int ScoreValue = 1000;

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
        Bus<EV_Pickup_FireFlower>.Emit();
        Bus<EV_TextSpawn>.Emit(new EV_TextSpawn { text = ScoreValue.ToString(), position = GlobalPosition });
        QueueFree();
    }
}
