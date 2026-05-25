using System;
using Godot;

namespace SuperMario;

public partial class BrickBlock : StaticBody2D, IBumpable, IScoreEventSource
{
    public event Action<int> ScoreEarned;

    [Export] public Bumpable Bumpable;

    public void OnBumped(PlayerController player)
    {
        if (player.CanBreakBricks)
        {
            ScoreEarned?.Invoke(Constants.BrickBreakScore);
            QueueFree();
            return;
        }
        Bumpable.Bump();
    }
}
