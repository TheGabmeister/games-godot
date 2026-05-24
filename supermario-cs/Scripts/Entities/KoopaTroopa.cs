using Godot;

namespace SuperMario;

public partial class KoopaTroopa : CharacterBody2D, IStompable, IFireballHittable, IStarHittable
{
    [Export] public KoopaColor Color = KoopaColor.Green;
    [Export] public PackedScene ShellScene;
    [Export] public Walker Walker;

    public override void _Ready()
    {
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
        var shell = ShellScene.Instantiate<Node2D>();
        shell.GlobalPosition = GlobalPosition;
        var parent = (Node)GameManager.Instance.CurrentLevel;
        parent.AddChild(shell);
    }
}
