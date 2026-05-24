using Godot;

namespace SuperMario;

public partial class KoopaShell : CharacterBody2D, IStompable, IStarHittable
{
    [Export] public Walker Walker;
    [Export] public float KickSpeed = 280f;

    private bool _moving;

    public override void _Ready()
    {
        if (Walker != null) Walker.Speed = 0f;
    }

    public void OnStomped(PlayerController player)
    {
        if (Walker == null) return;
        if (_moving)
        {
            Walker.Speed = 0f;
            _moving = false;
        }
        else
        {
            Walker.Speed = KickSpeed;
            Walker.Direction = player.GlobalPosition.X < GlobalPosition.X ? 1 : -1;
            _moving = true;
        }
    }

    public void OnHitByStar(PlayerController _) => QueueFree();
}
