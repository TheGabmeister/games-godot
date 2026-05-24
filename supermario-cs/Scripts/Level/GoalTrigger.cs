using Godot;

namespace SuperMario;

public partial class GoalTrigger : Area2D
{
    [Signal] public delegate void ReachedEventHandler();

    private bool _triggered;

    public override void _Ready()
    {
        BodyEntered += OnBodyEntered;
    }

    private void OnBodyEntered(Node2D body)
    {
        if (_triggered) return;
        if (body is not PlayerController) return;
        _triggered = true;
        CallDeferred(MethodName.EmitReached);
    }

    private void EmitReached()
    {
        EmitSignal(SignalName.Reached);
    }
}
