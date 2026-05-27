using Godot;

namespace SMB;

public partial class Bumpable : Node
{
    [Export] public Node2D Visual;
    [Export] public float Distance = 8f;
    [Export] public float Duration = 0.18f;

    private bool _bumping;
    private Vector2 _basePosition;

    public override void _Ready()
    {
        _basePosition = Visual.Position;
    }

    public void Bump()
    {
        if (_bumping) return;
        _bumping = true;
        var tween = Visual.CreateTween();
        var up = _basePosition + new Vector2(0, -Distance);
        tween.TweenProperty(Visual, "position", up, Duration * 0.5f);
        tween.TweenProperty(Visual, "position", _basePosition, Duration * 0.5f);
        tween.Finished += () => _bumping = false;
    }
}
