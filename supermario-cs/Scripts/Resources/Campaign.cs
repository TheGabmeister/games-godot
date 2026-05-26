using Godot;

namespace SMB;

[GlobalClass]
public partial class Campaign : Godot.Resource
{
    [Export] public LevelDefinition[] Levels { get; set; }
}
