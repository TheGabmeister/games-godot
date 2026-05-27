using Godot;

namespace SMB;

public partial class TextPopup : Node2D
{
    private const float RiseDistance = 32f;
    private const float Duration = 0.8f;

    public void Initialize(string text)
    {
        var label = new Label
        {
            Text = text,
            Position = new Vector2(-24, -16)
        };
        AddChild(label);
    }

    public void Play()
    {
        Animate();
    }

    private void Animate()
    {
        var tween = CreateTween();
        tween.SetParallel(true);
        tween.TweenProperty(this, "position", Position + new Vector2(0, -RiseDistance), Duration);
        tween.TweenProperty(this, "modulate:a", 0f, Duration);
        tween.Chain().TweenCallback(Callable.From(QueueFree));
    }
}
