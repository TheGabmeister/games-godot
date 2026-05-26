using Godot;

namespace SuperMario;

public partial class TextSpawner : Node2D
{
    public void SpawnText(string text, Vector2 worldPosition)
    {
        var popup = new TextPopup();

        popup.Initialize(text);
        AddChild(popup);
        popup.GlobalPosition = worldPosition;
        popup.Play();
    }
}
