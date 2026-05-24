using Godot;
using supermariocs.Autoloads;
using supermariocs.Components;
using supermariocs.Enums;
using supermariocs.Interfaces;
using supermariocs.Player;

namespace supermariocs.Entities;

public partial class KoopaTroopa : CharacterBody2D, IStompable, IFireballHittable, IStarHittable
{
    [Export] public KoopaColor Color = KoopaColor.Green;
    [Export] public PackedScene ShellScene;
    [Export] public Walker Walker;

    public override void _Ready()
    {
        if (Walker != null)
            Walker.TurnAtCliffs = Color == KoopaColor.Red;
    }

    public void OnStomped(PlayerController _)
    {
        SpawnShell();
        QueueFree();
    }

    public FireballReaction OnHitByFireball() { QueueFree(); return FireballReaction.Defeated; }

    public void OnHitByStar(PlayerController _) => QueueFree();

    private void SpawnShell()
    {
        if (ShellScene == null) return;
        var shell = ShellScene.Instantiate<Node2D>();
        shell.GlobalPosition = GlobalPosition;
        var parent = (Node)GameManager.Instance?.CurrentLevel ?? GetParent();
        parent.AddChild(shell);
    }
}
