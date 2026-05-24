using Godot;

namespace supermariocs.Components;

public partial class Lifetime : Node
{
    [Export] public float Duration = 3f;

    public override void _Ready()
    {
        var timer = GetTree().CreateTimer(Duration);
        timer.Timeout += () =>
        {
            var parent = GetParent();
            if (parent != null && IsInstanceValid(parent))
                parent.QueueFree();
        };
    }
}
