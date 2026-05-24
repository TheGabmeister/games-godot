using Godot;

namespace SuperMario;

public partial class BrickBlock : StaticBody2D, IBumpable
{
    [Export] public Bumpable Bumpable;

    public void OnBumped(PlayerController player)
    {
        if (player.CanBreakBricks)
        {
            GameSession.Current.Events.EmitScoreEarned(Constants.BrickBreakScore);
            QueueFree();
            return;
        }
        Bumpable.Bump();
    }
}
