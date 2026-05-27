using Godot;

namespace SMB;

public partial class MovingPlatform : AnimatableBody2D
{
    [Export] public MovingPlatformAxis Axis = MovingPlatformAxis.Horizontal;
    [Export] public float Distance = 160f;
    [Export] public float Speed = 80f;

    private Vector2 _origin;
    private int _direction = 1;

    public override void _Ready()
    {
        _origin = Position;
        SyncToPhysics = true;
    }

    public override void _PhysicsProcess(double delta)
    {
        var step = (float)delta * Speed * _direction;
        Vector2 next = Position;
        if (Axis == MovingPlatformAxis.Horizontal) next.X += step;
        else next.Y += step;

        var travel = Axis == MovingPlatformAxis.Horizontal ? next.X - _origin.X : next.Y - _origin.Y;
        if (Mathf.Abs(travel) >= Distance)
        {
            travel = Mathf.Sign(travel) * Distance;
            _direction = -_direction;
            if (Axis == MovingPlatformAxis.Horizontal) next.X = _origin.X + travel;
            else next.Y = _origin.Y + travel;
        }
        Position = next;
    }
}
