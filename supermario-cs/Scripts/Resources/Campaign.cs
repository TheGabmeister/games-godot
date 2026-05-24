using Godot;

namespace SuperMario;

[GlobalClass]
public partial class Campaign : Godot.Resource
{
    [Export] public LevelDefinition[] Levels { get; set; }
}
