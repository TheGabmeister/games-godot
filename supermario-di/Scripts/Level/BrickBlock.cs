using Godot;

namespace SMB;

[Meta(typeof(IAutoNode))]
public partial class BrickBlock : StaticBody2D, IBumpable
{
    [Export] public Bumpable Bumpable;

    [Dependency] public IScoreAwarder ScoreAwarder => this.DependOn<IScoreAwarder>();
    [Dependency] public SfxManager Sfx => this.DependOn<SfxManager>();
    [Dependency] public GameRules Rules => this.DependOn<GameRules>();

    public override void _Notification(int what) => this.Notify(what);

    public override void _Ready()
    {
    }

    public void OnBumped(PlayerController player)
    {
        if (player.CanBreakBricks)
        {
            ScoreAwarder.AwardScore(Rules.BrickBreakScore);
            Sfx.PlayBlockBreak();
            QueueFree();
            return;
        }
        Sfx.PlayBlockBump();
        Bumpable.Bump();
    }
}
