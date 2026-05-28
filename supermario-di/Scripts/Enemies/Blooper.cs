using Godot;

namespace SMB;

[Meta(typeof(IAutoNode))]
public partial class Blooper : CharacterBody2D, IStompable, IFireballHittable, IStarHittable
{
    [Export] public float Speed = 90f;
    [Export] public float BobSpeed = 4f;
    [Export] public float BobStrength = 24f;

    private float _t;

    [Dependency] public GameMode GameMode => this.DependOn<GameMode>();

    public override void _Notification(int what) => this.Notify(what);

    public override void _PhysicsProcess(double delta)
    {
        float dt = (float)delta;
        _t += dt;
        var player = GameMode.CurrentPlayer;
        if (player == null) return;

        var toPlayer = (player.GlobalPosition - GlobalPosition).Normalized();

        var bob = Mathf.Sin(_t * BobSpeed) * BobStrength;
        var v = toPlayer * Speed;
        v.Y += bob;
        Velocity = v;
        MoveAndSlide();
    }

    public void OnStomped(PlayerController _) => QueueFree();
    public FireballReaction OnHitByFireball() { QueueFree(); return FireballReaction.Defeated; }
    public void OnHitByStar(PlayerController _) => QueueFree();
}
