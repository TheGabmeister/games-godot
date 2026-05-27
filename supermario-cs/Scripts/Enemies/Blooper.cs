using Godot;

namespace SMB;

public partial class Blooper : CharacterBody2D, IStompable, IFireballHittable, IStarHittable
{
    [Export] public float Speed = 90f;
    [Export] public float BobSpeed = 4f;
    [Export] public float BobStrength = 24f;

    private float _t;

    public override void _PhysicsProcess(double delta)
    {
        float dt = (float)delta;
        _t += dt;
        var player = (Node2D)GetTree().GetFirstNodeInGroup("player");
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
