using Godot;

namespace supermariocs.Resources;

[GlobalClass]
public partial class Campaign : Godot.Resource
{
    [Export] public LevelDefinition[] Levels { get; set; }
}
