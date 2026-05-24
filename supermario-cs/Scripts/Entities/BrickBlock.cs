using Godot;
using supermariocs.Autoloads;
using supermariocs.Components;
using supermariocs.Interfaces;
using supermariocs.Player;

namespace supermariocs.Entities;

public partial class BrickBlock : StaticBody2D, IBumpable
{
    [Export] public Bumpable Bumpable;

    public void OnBumped(PlayerController player)
    {
        if (player.CanBreakBricks)
        {
            GameManager.Instance?.State?.AddScore(Constants.BrickBreakScore);
            QueueFree();
            return;
        }
        Bumpable?.Bump();
    }
}
