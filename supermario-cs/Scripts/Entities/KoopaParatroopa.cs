using Godot;

namespace SuperMario;

public partial class KoopaParatroopa : CharacterBody2D, IStompable, IFireballHittable, IStarHittable
{
    [Export] public KoopaColor Color = KoopaColor.Green;
    [Export] public PackedScene GroundKoopaScene;
    [Export] public float HoverAmplitude = 64f;
    [Export] public float HoverSpeed = 2f;

    private Vector2 _origin;
    private float _t;

    public override void _Ready()
    {
        _origin = GlobalPosition;
    }

    public override void _PhysicsProcess(double delta)
    {
        _t += (float)delta;
        var pos = _origin;
        pos.Y += Mathf.Sin(_t * HoverSpeed) * HoverAmplitude;
        GlobalPosition = pos;
    }

    public void OnStomped(PlayerController _)
    {
        SpawnGroundKoopa();
        QueueFree();
    }

    public FireballReaction OnHitByFireball() { QueueFree(); return FireballReaction.Defeated; }
    public void OnHitByStar(PlayerController _) => QueueFree();

    private void SpawnGroundKoopa()
    {
        if (GroundKoopaScene == null) return;
        var koopa = GroundKoopaScene.Instantiate<Node2D>();
        koopa.GlobalPosition = GlobalPosition;
        var parent = (Node)GameManager.Instance?.CurrentLevel ?? GetParent();
        parent.AddChild(koopa);
    }
}
