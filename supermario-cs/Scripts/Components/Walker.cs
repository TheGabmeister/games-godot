using Godot;

namespace SMB;

public partial class Walker : Node
{
    [Export] public CharacterBody2D Body;
    [Export] public float Speed = 80f;
    [Export] public bool TurnAtCliffs = false;
    [Export] public float BounceForce = 0f;
    [Export] public float Gravity = 1200f;
    [Export] public float MaxFallSpeed = 600f;
    [Export] public float CliffProbeOffsetY = 8f;
    [Export(PropertyHint.Layers2DPhysics)] public uint CliffProbeMask = 0;

    public int Direction = -1;

    public override void _PhysicsProcess(double delta)
    {
        float dt = (float)delta;

        var v = Body.Velocity;
        v.Y += Gravity * dt;
        if (v.Y > MaxFallSpeed) v.Y = MaxFallSpeed;
        v.X = Direction * Speed;

        Body.Velocity = v;
        bool wasGrounded = Body.IsOnFloor();
        Body.MoveAndSlide();
        v = Body.Velocity;

        bool grounded = Body.IsOnFloor();

        if (Body.IsOnWall())
            Direction = -Direction;

        if (TurnAtCliffs && grounded)
        {
            var probe = Body.GlobalPosition
                + new Vector2(Direction * 18f, CliffProbeOffsetY);
            var space = Body.GetWorld2D().DirectSpaceState;
            var q = PhysicsRayQueryParameters2D.Create(probe, probe + new Vector2(0, 24));
            q.CollisionMask = CliffProbeMask;
            var hit = space.IntersectRay(q);
            if (hit.Count == 0)
                Direction = -Direction;
        }

        if (BounceForce != 0f && grounded && !wasGrounded)
        {
            v.Y = BounceForce;
        }

        Body.Velocity = v;
    }
}
