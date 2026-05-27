using Godot;

namespace SMB;

public partial class Podoboo : Area2D, IStarHittable
{
    [Export] public float JumpSpeed = 520f;
    [Export] public float Gravity = 1200f;
    [Export] public float RestDuration = 1f;

    private float _t;
    private float _vy;
    private Vector2 _basePos;
    private bool _resting = true;

    public override void _Ready()
    {
        _basePos = GlobalPosition;
        BodyEntered += OnBodyEntered;
    }

    public override void _PhysicsProcess(double delta)
    {
        float dt = (float)delta;
        if (_resting)
        {
            _t += dt;
            if (_t >= RestDuration)
            {
                _t = 0f;
                _resting = false;
                _vy = -JumpSpeed;
                GlobalPosition = _basePos;
            }
            return;
        }
        _vy += Gravity * dt;
        GlobalPosition += new Vector2(0, _vy * dt);
        if (GlobalPosition.Y >= _basePos.Y && _vy > 0f)
        {
            _resting = true;
            GlobalPosition = _basePos;
        }
    }

    private void OnBodyEntered(Node2D body)
    {
        if (body is PlayerController player && !player.IsStarInvincible)
            player.TakeDamage();
    }

    public void OnHitByStar(PlayerController _) => QueueFree();
}
