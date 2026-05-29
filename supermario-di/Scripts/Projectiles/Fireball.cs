using Godot;

namespace SMB;

[Meta(typeof(IAutoNode))]
public partial class Fireball : CharacterBody2D
{
    [Export] Area2D _hitArea;
    [Export] float _speed = 400f;
    [Export] float _gravity = 1400f;
    [Export] float _bounceForce = -500f;
    [Export] float _maxFallSpeed = 700f;

    [Dependency] public SfxManager Sfx => this.DependOn<SfxManager>();
    PlayerController _owner;
    int _facing = 1;
    bool _destroyed;
    Vector2 _velocity;

    

    public override void _Notification(int what) => this.Notify(what);

    public virtual void Init(Vector2 position, int facing, PlayerController owner)
    {
        GlobalPosition = position;
        _facing = facing;
        _owner = owner;
        _velocity = new Vector2(_facing * _speed, 0f);
    }

    public override void _Ready()
    {
        _hitArea.BodyEntered += OnHit;
    }

    public override void _PhysicsProcess(double delta)
    {
        if (_destroyed) return;
        float dt = (float)delta;
        _velocity.Y += _gravity * dt;
        if (_velocity.Y > _maxFallSpeed)
            _velocity.Y = _maxFallSpeed;
        _velocity.X = _facing * _speed;
        Velocity = _velocity;
        MoveAndSlide();
        _velocity = Velocity;

        for (int i = 0; i < GetSlideCollisionCount(); i++)
        {
            var col = GetSlideCollision(i);
            var n = col.GetNormal();
            if (n.Y < -0.9f)
            {
                _velocity.Y = _bounceForce;
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

    private void Destroy(bool playHitSfx)
    {
        if (_destroyed) return;
        _destroyed = true;
        if (playHitSfx)
            Sfx.PlayBlockBump();
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
