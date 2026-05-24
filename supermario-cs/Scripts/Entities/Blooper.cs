using Godot;
using supermariocs.Interfaces;
using supermariocs.Player;

namespace supermariocs.Entities;

public partial class Blooper : CharacterBody2D, IStompable, IFireballHittable, IStarHittable
{
    private float _t;

    public override void _PhysicsProcess(double delta)
    {
        float dt = (float)delta;
        _t += dt;
        var player = GetTree().GetFirstNodeInGroup("player") as Node2D;
        Vector2 toPlayer = Vector2.Zero;
        if (player != null)
            toPlayer = (player.GlobalPosition - GlobalPosition).Normalized();

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
