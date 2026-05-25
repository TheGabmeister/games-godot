using Godot;

namespace SuperMario;

public partial class TextPopupSpawner : Node2D
{
    public static TextPopupSpawner Instance { get; private set; }

    public override void _EnterTree()
    {
        Instance = this;
    }

    public override void _ExitTree()
    {
        if (Instance == this) Instance = null;
    }

    public static void Spawn(string text, Vector2 worldPosition)
    {
        if (Instance == null)
            throw new System.InvalidOperationException($"{nameof(TextPopupSpawner)} requires an active instance.");

        Instance.SpawnPopup(text, worldPosition);
    }

    private void SpawnPopup(string text, Vector2 worldPosition)
    {
        var popup = new TextPopup();

        popup.Initialize(text);
        AddChild(popup);
        popup.GlobalPosition = worldPosition;
        popup.Play();
    }
}
