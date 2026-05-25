using Godot;

namespace SuperMario;

public static class TextPopupSpawner
{
    public static void Spawn(Node root, string text, Vector2 worldPosition)
    {
        var popup = new TextPopup();

        popup.Initialize(text);
        root.AddChild(popup);
        popup.GlobalPosition = worldPosition;
        popup.Play();
    }
}
