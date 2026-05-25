using Godot;

namespace SuperMario;

public partial class BulletBillCannon : Node2D
{
    [Export] public PackedScene BulletBillScene;
    [Export] public int Facing = -1;
    [Export] public float FireInterval = Constants.BulletBillCannonFireInterval;

    private float _t;

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
        var parent = (Node)GameMode.Instance.CurrentLevel;
        parent.AddChild(bb);
    }
}
