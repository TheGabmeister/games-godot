using Godot;

namespace SMB;

public partial class TextSpawner : Node2D
{
    public override void _Ready()
    {
        Bus<EV_TextSpawn>.Sub(OnTextSpawn);
    }

    public override void _ExitTree()
    {
        Bus<EV_TextSpawn>.Unsub(OnTextSpawn);
    }

    private void OnTextSpawn(EV_TextSpawn ev)
    {
        SpawnText(ev.text, ev.position);
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
