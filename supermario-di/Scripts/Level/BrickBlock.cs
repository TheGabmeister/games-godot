using Godot;

namespace SMB;

[Meta(typeof(IAutoNode))]
public partial class BrickBlock : StaticBody2D, IBumpable
{
    [Export] public Bumpable Bumpable;

    [Dependency] public IScoreAwarder ScoreAwarder => this.DependOn<IScoreAwarder>();
    [Dependency] public SfxManager Sfx => this.DependOn<SfxManager>();

    public override void _Notification(int what) => this.Notify(what);

    public static BrickBlock Create(Vector2 globalPosition)
    {
        var scene = GD.Load<PackedScene>(Config.BrickBlockScenePath);
        var bb = scene.Instantiate<BrickBlock>();
        bb.GlobalPosition = globalPosition;
        return bb;
    }

    public override void _Ready()
    {
    }

    public void OnBumped(PlayerController player)
    {
        if (player.CanBreakBricks)
        {
            ScoreAwarder.AwardScore(Constants.BrickBreakScore);
            Sfx.PlayBlockBreak();
            QueueFree();
            return;
        }
        Sfx.PlayBlockBump();
        Bumpable.Bump();
    }
}
