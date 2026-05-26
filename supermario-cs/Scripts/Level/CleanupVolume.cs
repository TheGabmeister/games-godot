using Godot;

namespace SMB;

public partial class CleanupVolume : Area2D
{
    public override void _Ready()
    {
        BodyEntered += OnBodyEntered;
    }

    private void OnBodyEntered(Node2D body)
    {
        if (body is PlayerController player)
        {
            player.KillPlayer();
            return;
        }
        body.QueueFree();
    }
}
