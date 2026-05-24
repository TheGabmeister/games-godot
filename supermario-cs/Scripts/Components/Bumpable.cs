using Godot;

namespace supermariocs.Components;

public partial class Bumpable : Node
{
    [Export] public Node2D Visual;

    private bool _bumping;
    private Vector2 _basePosition;

    public override void _Ready()
    {
        if (Visual != null) _basePosition = Visual.Position;
    }

    public void Bump()
    {
        if (_bumping || Visual == null) return;
        _bumping = true;
        var tween = Visual.CreateTween();
        var up = _basePosition + new Vector2(0, -Constants.BlockBumpDistance);
        tween.TweenProperty(Visual, "position", up, Constants.BlockBumpDuration * 0.5f);
        tween.TweenProperty(Visual, "position", _basePosition, Constants.BlockBumpDuration * 0.5f);
        tween.Finished += () => _bumping = false;
    }
}
