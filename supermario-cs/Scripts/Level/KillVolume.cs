using Godot;

namespace SuperMario;

public partial class KillVolume : Area2D
{
    public override void _Ready()
    {
        BodyEntered += OnBodyEntered;
    }

    private void OnBodyEntered(Node2D body)
    {
        if (body is PlayerController player)
            player.KillPlayer();
    }
}
