using Godot;

namespace SuperMario;

public partial class ScorePopup : Node2D
{
    [Export] public Label Label;
    [Export] public float RiseDistance = 32f;
    [Export] public float Duration = 0.8f;

    public static void Spawn(Node levelRoot, Vector2 position, int points)
    {
        if (levelRoot == null) return;
        var popup = new ScorePopup();
        popup.GlobalPosition = position;
        var label = new Label
        {
            Text = "+" + points,
            Position = new Vector2(-24, -16)
        };
        popup.Label = label;
        popup.AddChild(label);
        levelRoot.AddChild(popup);
        popup.Animate();
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
