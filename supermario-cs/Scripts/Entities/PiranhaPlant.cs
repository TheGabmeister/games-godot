using Godot;

namespace SuperMario;

public partial class PiranhaPlant : Node2D, IFireballHittable, IStarHittable
{
    [Export] public Node2D Visual;
    [Export] public Area2D Hitbox;
    [Export] public float EmergeHeight = 32f;
    [Export] public float EmergeDuration = 1.5f;
    [Export] public float HideDuration = 1.5f;
    [Export] public float ProximityRadius = 80f;

    private float _t;
    private bool _hidden = true;
    private Vector2 _basePos;
    private Vector2 _hiddenPos;
    private Vector2 _emergedPos;

    public override void _Ready()
    {
        _basePos = Visual.Position;
        _hiddenPos = _basePos;
        _emergedPos = _basePos - new Vector2(0, EmergeHeight);
        Visual.Position = _hiddenPos;

        Hitbox.BodyEntered += OnBodyEntered;
        Hitbox.Monitoring = false;
    }

    public override void _PhysicsProcess(double delta)
    {
        _t += (float)delta;
        if (_hidden)
        {
            if (_t < HideDuration) return;
            if (PlayerNearby()) return;
            _hidden = false;
            _t = 0f;
            Hitbox.Monitoring = true;
        }
        else
        {
            if (_t < EmergeDuration) return;
            _hidden = true;
            _t = 0f;
            Hitbox.Monitoring = false;
        }
        Visual.Position = _hidden ? _hiddenPos : _emergedPos;
    }

    private bool PlayerNearby()
    {
        var p = (Node2D)GetTree().GetFirstNodeInGroup("player");
        return p.GlobalPosition.DistanceTo(GlobalPosition) < ProximityRadius;
    }

    private void OnBodyEntered(Node2D body)
    {
        if (body is PlayerController player && !player.IsStarInvincible)
            player.TakeDamage();
    }

    public FireballReaction OnHitByFireball() { QueueFree(); return FireballReaction.Defeated; }
    public void OnHitByStar(PlayerController _) => QueueFree();
}
