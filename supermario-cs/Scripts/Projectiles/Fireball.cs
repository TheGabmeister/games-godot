using Godot;

namespace SMB;

public partial class Fireball : CharacterBody2D
{
    [Export] public Area2D HitArea;
    [Export] public float Speed = 400f;
    [Export] public float Gravity = 1400f;
    [Export] public float BounceForce = -500f;
    [Export] public float MaxFallSpeed = 700f;

    private PlayerController _owner;
    private int _facing = 1;
    private bool _destroyed;
    private Vector2 _velocity;

    public virtual void Init(Vector2 position, int facing, PlayerController owner)
    {
        GlobalPosition = position;
        _facing = facing;
        _owner = owner;
        _velocity = new Vector2(_facing * Speed, 0f);
    }

    public override void _Ready()
    {
        HitArea.BodyEntered += OnHit;
    }

    public override void _PhysicsProcess(double delta)
    {
        if (_destroyed) return;
        float dt = (float)delta;
        _velocity.Y += Gravity * dt;
        if (_velocity.Y > MaxFallSpeed)
            _velocity.Y = MaxFallSpeed;
        _velocity.X = _facing * Speed;
        Velocity = _velocity;
        MoveAndSlide();
        _velocity = Velocity;

        for (int i = 0; i < GetSlideCollisionCount(); i++)
        {
            var col = GetSlideCollision(i);
            var n = col.GetNormal();
            if (n.Y < -0.9f)
            {
                _velocity.Y = BounceForce;
            }
            else if (Mathf.Abs(n.X) > 0.9f)
            {
                Destroy(true);
                return;
            }
        }
    }

    private void OnHit(Node2D body)
    {
        if (_destroyed) return;
        if (body is not IFireballHittable target) return;
        var reaction = target.OnHitByFireball();
        switch (reaction)
        {
            case FireballReaction.Defeated:
                Destroy(false);
                break;
            case FireballReaction.Blocked:
                Destroy(true);
                break;
        }
    }

    private void Destroy(bool _playHitSfx)
    {
        if (_destroyed) return;
        _destroyed = true;
        _owner.NotifyFireballDestroyed();
        QueueFree();
    }

    public override void _ExitTree()
    {
        if (!_destroyed)
        {
            _destroyed = true;
            _owner.NotifyFireballDestroyed();
        }
    }
}
