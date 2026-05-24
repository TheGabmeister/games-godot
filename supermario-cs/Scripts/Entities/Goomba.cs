using Godot;

namespace SuperMario;

public partial class Goomba : CharacterBody2D, IStompable, IFireballHittable, IStarHittable
{
    public void OnStomped(PlayerController _) => QueueFree();
    public FireballReaction OnHitByFireball() { QueueFree(); return FireballReaction.Defeated; }
    public void OnHitByStar(PlayerController _) => QueueFree();
}
