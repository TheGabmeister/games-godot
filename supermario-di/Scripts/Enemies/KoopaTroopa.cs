using Godot;

namespace SMB;

[Meta(typeof(IAutoNode))]
public partial class KoopaTroopa : CharacterBody2D, IStompable, IFireballHittable, IStarHittable
{
    [Export] public KoopaColor Color = KoopaColor.Green;
    [Export] public PackedScene ShellScene;
    [Export] public Walker Walker;

    [Dependency] public GameMode GameMode => this.DependOn<GameMode>();

    public override void _Notification(int what) => this.Notify(what);

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
        GameMode.CurrentLevel.AddChild(shell);
    }
}
