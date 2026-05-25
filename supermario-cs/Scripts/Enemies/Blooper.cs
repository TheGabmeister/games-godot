using Godot;

namespace SuperMario;

public partial class Blooper : CharacterBody2D, IStompable, IFireballHittable, IStarHittable
{
    private float _t;

    public override void _PhysicsProcess(double delta)
    {
        float dt = (float)delta;
        _t += dt;
        var player = (Node2D)GetTree().GetFirstNodeInGroup("player");
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
