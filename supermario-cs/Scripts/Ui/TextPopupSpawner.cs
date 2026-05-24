using System;
using Godot;

namespace SuperMario;

public static class TextPopupSpawner
{
    public static event Action<string, Vector2> TextPopupRequested;

    static TextPopupSpawner()
    {
        TextPopupRequested += Spawn;
    }

    public static void EmitTextPopupRequested(string text, Vector2 worldPosition) =>
        TextPopupRequested?.Invoke(text, worldPosition);

    private static void Spawn(string text, Vector2 worldPosition)
    {
        var root = GameSession.Instance.CurrentLevel;
        var popup = new TextPopup();

        popup.Initialize(text);
        root.AddChild(popup);
        popup.GlobalPosition = worldPosition;
        popup.Play();
    }
}
