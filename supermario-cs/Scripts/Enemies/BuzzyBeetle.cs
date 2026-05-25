using Godot;

namespace SuperMario;

public partial class BuzzyBeetle : CharacterBody2D, IStompable, IStarHittable
{
    public void OnStomped(PlayerController _) => QueueFree();
    public void OnHitByStar(PlayerController _) => QueueFree();
}
