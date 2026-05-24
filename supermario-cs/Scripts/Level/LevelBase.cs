using Godot;

namespace SuperMario;

public partial class LevelBase : Node2D
{
    [Export] public Marker2D PlayerStart;
    [Export] public GoalTrigger GoalTrigger;
}
