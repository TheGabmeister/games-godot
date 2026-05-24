using Godot;

namespace supermariocs.Resources;

[GlobalClass]
public partial class LevelDefinition : Godot.Resource
{
    [Export] public string Name { get; set; } = "";
    [Export] public PackedScene LevelScene { get; set; }
    [Export] public AudioStream MusicTrack { get; set; }
    [Export] public float TimeLimit { get; set; } = 400f;
}
