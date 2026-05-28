using Godot;

namespace SMB;

[Meta(typeof(IAutoNode))]
public partial class Blooper : CharacterBody2D, IStompable, IFireballHittable, IStarHittable
{
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

        var bob = Mathf.Sin(_t * Constants.BlooperBobSpeed) * Constants.BlooperBobStrength;
        var v = toPlayer * Constants.BlooperSpeed;
        v.Y += bob;
        Velocity = v;
        MoveAndSlide();
    }

    public void OnStomped(PlayerController _) => QueueFree();
    public FireballReaction OnHitByFireball() { QueueFree(); return FireballReaction.Defeated; }
    public void OnHitByStar(PlayerController _) => QueueFree();
}
