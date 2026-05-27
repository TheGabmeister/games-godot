using Godot;

namespace SMB;

public partial class Hammer : Area2D
{
    [Export] public Node2D Visual;
    [Export] public float HorizontalSpeed = 220f;
    [Export] public float InitialUpSpeed = 520f;
    [Export] public float Gravity = 1400f;
    [Export] public float SpinSpeed = 18f;

    private int _facing = 1;
    private Vector2 _velocity;
    private float _spinT;

    public void Init(Vector2 position, int facing)
    {
        GlobalPosition = position;
        _facing = facing;
        _velocity = new Vector2(_facing * HorizontalSpeed, -InitialUpSpeed);
    }

    public override void _Ready()
    {
        BodyEntered += OnBodyEntered;
    }

    public override void _PhysicsProcess(double delta)
    {
        float dt = (float)delta;
        _velocity.Y += Gravity * dt;
        GlobalPosition += _velocity * dt;
        _spinT += dt * SpinSpeed;
        Visual.Rotation = _spinT;
    }

    private void OnBodyEntered(Node2D body)
    {
        if (body is PlayerController player)
            player.TakeDamage();
    }
}
