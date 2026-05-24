using Godot;

namespace SuperMario;

public partial class LevelBase : Node2D
{
    [Export] private NodePath _playerStartPath;
    [Export] private NodePath _goalTriggerPath;

    public Marker2D PlayerStart { get; private set; }
    public GoalTrigger GoalTrigger { get; private set; }

    public override void _Ready()
    {
        PlayerStart = GetNode<Marker2D>(_playerStartPath);
        GoalTrigger = GetNode<GoalTrigger>(_goalTriggerPath);
    }
}
