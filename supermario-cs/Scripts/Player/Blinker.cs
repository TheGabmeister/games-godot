using Godot;

namespace supermariocs.Player;

public partial class Blinker : Node
{
    [Export] public Node2D Target;
    [Export] public float Interval = 0.06f;

    private float _remaining;
    private float _accum;

    public override void _Process(double delta)
    {
        if (Target == null) return;
        if (_remaining <= 0f)
        {
            if (!Target.Visible) Target.Visible = true;
            return;
        }
        _remaining -= (float)delta;
        _accum += (float)delta;
        if (_accum >= Interval)
        {
            _accum = 0f;
            Target.Visible = !Target.Visible;
        }
        if (_remaining <= 0f)
            Target.Visible = true;
    }

    public void Start(float duration)
    {
        _remaining = duration;
        _accum = 0f;
    }

    public bool IsActive => _remaining > 0f;
}
