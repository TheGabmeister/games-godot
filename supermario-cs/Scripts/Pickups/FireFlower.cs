using Godot;

namespace SMB;

public partial class FireFlower : Area2D
{
    private bool _collected;

    public override void _Ready()
    {
        BodyEntered += OnBodyEntered;
    }

    private void OnBodyEntered(Node2D body)
    {
        if (_collected || body is not PlayerController player) return;
        _collected = true;
        Bus<EV_ScoreEarned>.Emit(new EV_ScoreEarned { value = Constants.MushroomScore });
        Bus<EV_Pickup_FireFlower>.Emit(new EV_Pickup_FireFlower { player = player });
        Bus<EV_TextSpawn>.Emit(new EV_TextSpawn { text = Constants.MushroomScore.ToString(), position = GlobalPosition });
        QueueFree();
    }
}
