using Godot;

namespace SMB;

[Meta(typeof(IAutoNode))]
public partial class Hitbox : Area2D
{
    [Export] public Node OwnerNode;

    public override void _Ready()
    {
        BodyEntered += OnBodyEntered;
    }

    private void OnBodyEntered(Node2D body)
    {
        if (body is not PlayerController player) return;

        if (player.IsStarInvincible)
        {
            if (OwnerNode is IStarHittable star)
                star.OnHitByStar(player);
            return;
        }

        if (OwnerNode is IStompable && player.Velocity.Y > 0f)
            return;

        if (player.IsInvulnerable) return;
        player.TakeDamage();
    }
}
