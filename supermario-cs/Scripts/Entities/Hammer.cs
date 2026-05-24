using Godot;
using supermariocs.Player;

namespace supermariocs.Entities;

public partial class Hammer : Area2D
{
    [Export] public Node2D Visual;

    private int _facing = 1;
    private Vector2 _velocity;
    private float _spinT;

    public void Init(Vector2 position, int facing)
    {
        GlobalPosition = position;
        _facing = facing;
        _velocity = new Vector2(_facing * Constants.HammerHorizontalSpeed, -Constants.HammerInitialUpSpeed);
    }

    public override void _Ready()
    {
        BodyEntered += OnBodyEntered;
    }

    public override void _PhysicsProcess(double delta)
    {
        float dt = (float)delta;
        _velocity.Y += Constants.HammerGravity * dt;
        GlobalPosition += _velocity * dt;
        _spinT += dt * Constants.HammerSpinSpeed;
        if (Visual != null) Visual.Rotation = _spinT;
    }

    private void OnBodyEntered(Node2D body)
    {
        if (body is PlayerController player)
            player.TakeDamage();
    }
}
