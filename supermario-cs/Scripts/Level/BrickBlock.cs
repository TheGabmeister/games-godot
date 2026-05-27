using Godot;

namespace SMB;

public partial class BrickBlock : StaticBody2D, IBumpable
{
    [Export] public Bumpable Bumpable;
    [Export] public int BreakScore = 50;

    public override void _Ready()
    {
    }

    public void OnBumped(PlayerController player)
    {
        if (player.CanBreakBricks)
        {
            Bus<EV_ScoreEarned>.Emit(new EV_ScoreEarned { value = BreakScore });
            QueueFree();
            return;
        }
        Bumpable.Bump();
    }
}
