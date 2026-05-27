using Godot;

namespace SMB;

public partial class HammerBro : CharacterBody2D, IStompable, IFireballHittable, IStarHittable
{
    [Export] public PackedScene HammerScene;
    [Export] public float Gravity = 1200f;
    [Export] public float MaxFallSpeed = 600f;
    [Export] public float ShuffleSpeed = 40f;
    [Export] public float ShuffleInterval = 1.2f;
    [Export] public float JumpForce = -520f;
    [Export] public float JumpInterval = 3.5f;
    [Export] public float ThrowInterval = 2.0f;

    private Vector2 _velocity;
    private float _shuffleT;
    private float _jumpT;
    private float _throwT;
    private int _direction = -1;

    public override void _PhysicsProcess(double delta)
    {
        float dt = (float)delta;

        _velocity.Y += Gravity * dt;
        if (_velocity.Y > MaxFallSpeed) _velocity.Y = MaxFallSpeed;

        _shuffleT += dt;
        if (_shuffleT >= ShuffleInterval)
        {
            _shuffleT = 0f;
            _direction = -_direction;
        }
        _velocity.X = _direction * ShuffleSpeed;

        if (IsOnFloor())
        {
            _jumpT += dt;
            if (_jumpT >= JumpInterval)
            {
                _jumpT = 0f;
                _velocity.Y = JumpForce;
            }
        }

        _throwT += dt;
        if (_throwT >= ThrowInterval)
        {
            _throwT = 0f;
            ThrowHammer();
        }

        Velocity = _velocity;
        MoveAndSlide();
        _velocity = Velocity;
    }

    private void ThrowHammer()
    {
        var player = (Node2D)GetTree().GetFirstNodeInGroup("player");
        int facing = player.GlobalPosition.X < GlobalPosition.X ? -1 : 1;
        var hammer = HammerScene.Instantiate<Hammer>();
        hammer.Init(GlobalPosition + new Vector2(0, -32), facing);
        var parent = (Node)GetGameMode().CurrentLevel;
        parent.AddChild(hammer);
    }

    public void OnStomped(PlayerController _) => QueueFree();
    public FireballReaction OnHitByFireball() { QueueFree(); return FireballReaction.Defeated; }
    public void OnHitByStar(PlayerController _) => QueueFree();
}
