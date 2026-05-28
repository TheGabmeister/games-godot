using Godot;

namespace SMB;

[Meta(typeof(IAutoNode))]
public partial class BulletBillCannon : Node2D
{
    [Export] public PackedScene BulletBillScene;
    [Export] public int Facing = -1;
    [Export] public float FireInterval = Constants.BulletBillCannonFireInterval;

    private float _t;

    [Dependency] public GameMode GameMode => this.DependOn<GameMode>();
    [Dependency] public SfxManager Sfx => this.DependOn<SfxManager>();

    public override void _Notification(int what) => this.Notify(what);

    public override void _PhysicsProcess(double delta)
    {
        _t += (float)delta;
        if (_t < FireInterval) return;
        _t = 0f;
        Fire();
    }

    private void Fire()
    {
        var bb = BulletBillScene.Instantiate<BulletBill>();
        bb.Init(GlobalPosition, Mathf.Sign(Facing) == 0 ? -1 : (int)Mathf.Sign(Facing));
        Sfx.PlayWarning();
        GameMode.CurrentLevel.AddChild(bb);
    }
}
