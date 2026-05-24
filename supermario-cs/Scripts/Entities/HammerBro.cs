using Godot;
using supermariocs.Autoloads;
using supermariocs.Interfaces;
using supermariocs.Player;

namespace supermariocs.Entities;

public partial class HammerBro : CharacterBody2D, IStompable, IFireballHittable, IStarHittable
{
    [Export] public PackedScene HammerScene;

    private Vector2 _velocity;
    private float _shuffleT;
    private float _jumpT;
    private float _throwT;
    private int _direction = -1;

    public override void _PhysicsProcess(double delta)
    {
        float dt = (float)delta;

        _velocity.Y += Constants.Gravity * dt;
        if (_velocity.Y > Constants.MaxFallSpeed) _velocity.Y = Constants.MaxFallSpeed;

        _shuffleT += dt;
        if (_shuffleT >= Constants.HammerBroShuffleInterval)
        {
            _shuffleT = 0f;
            _direction = -_direction;
        }
        _velocity.X = _direction * Constants.HammerBroShuffleSpeed;

        if (IsOnFloor())
        {
            _jumpT += dt;
            if (_jumpT >= Constants.HammerBroJumpInterval)
            {
                _jumpT = 0f;
                _velocity.Y = Constants.HammerBroJumpForce;
            }
        }

        _throwT += dt;
        if (_throwT >= Constants.HammerBroThrowInterval)
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
        if (HammerScene == null) return;
        var player = GetTree().GetFirstNodeInGroup("player") as Node2D;
        int facing = (player != null && player.GlobalPosition.X < GlobalPosition.X) ? -1 : 1;
        var hammer = HammerScene.Instantiate<Hammer>();
        hammer.Init(GlobalPosition + new Vector2(0, -32), facing);
        var parent = (Node)GameManager.Instance?.CurrentLevel ?? GetParent();
        parent.AddChild(hammer);
    }

    public void OnStomped(PlayerController _) => QueueFree();
    public FireballReaction OnHitByFireball() { QueueFree(); return FireballReaction.Defeated; }
    public void OnHitByStar(PlayerController _) => QueueFree();
}
