using Godot;

namespace SMB;

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

        if (OwnerNode is IStompable stompable && IsPlayerStomping(player))
        {
            if (player.TryStomp(stompable))
                return;
        }

        if (player.IsInvulnerable) return;
        player.TakeDamage();
    }

    private bool IsPlayerStomping(PlayerController player)
    {
        var ownerNode2D = (Node2D)OwnerNode;
        if (player.Velocity.Y <= 0f) return false;
        return player.GlobalPosition.Y < ownerNode2D.GlobalPosition.Y - Constants.StompTopTolerance / 2f;
    }
}
