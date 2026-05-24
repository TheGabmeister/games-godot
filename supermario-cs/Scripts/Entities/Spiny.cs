using Godot;

namespace SuperMario;

public partial class Spiny : CharacterBody2D, IFireballHittable, IStarHittable
{
    public FireballReaction OnHitByFireball() { QueueFree(); return FireballReaction.Defeated; }
    public void OnHitByStar(PlayerController _) => QueueFree();
}
