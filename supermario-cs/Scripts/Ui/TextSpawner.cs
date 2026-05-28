using Godot;

namespace SMB;

public partial class TextSpawner : Node2D
{
    public override void _Ready()
    {
        Events.TextSpawnRequested += OnTextSpawn;
    }

    public override void _ExitTree()
    {
        Events.TextSpawnRequested -= OnTextSpawn;
    }

    private void OnTextSpawn(string text, Vector2 position)
    {
        SpawnText(text, position);
    }

    public void SpawnText(string text, Vector2 worldPosition)
    {
        var popup = new TextPopup();

        popup.Initialize(text);
        AddChild(popup);
        popup.GlobalPosition = worldPosition;
        popup.Play();
    }
}
