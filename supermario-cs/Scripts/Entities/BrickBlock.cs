using Godot;

namespace SuperMario;

public partial class BrickBlock : StaticBody2D, IBumpable
{
    [Export] public Bumpable Bumpable;

    public void OnBumped(PlayerController player)
    {
        if (player.CanBreakBricks)
        {
            GameManager.Instance.State.AddScore(Constants.BrickBreakScore);
            QueueFree();
            return;
        }
        Bumpable.Bump();
    }
}
