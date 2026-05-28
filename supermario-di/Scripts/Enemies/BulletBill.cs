using Godot;

namespace SMB;

public partial class BulletBill : Area2D, IStompable, IFireballHittable, IStarHittable
{
    [Export] public float Speed = 180f;

    private int _facing = 1;

    public void Init(Vector2 position, int facing)
    {
        GlobalPosition = position;
        _facing = facing;
    }

    public override void _Ready()
    {
        BodyEntered += OnBodyEntered;
    }

    public override void _PhysicsProcess(double delta)
    {
        Position += new Vector2(_facing * Speed * (float)delta, 0f);
    }

    private void OnBodyEntered(Node2D body)
    {
        if (body is PlayerController player && !player.IsStarInvincible)
            player.TakeDamage();
    }

    public void OnStomped(PlayerController _) => QueueFree();
    public FireballReaction OnHitByFireball() { QueueFree(); return FireballReaction.Defeated; }
    public void OnHitByStar(PlayerController _) => QueueFree();
}
