using Godot;

namespace SMB;

[Tool]
public partial class LabeledMarker : Marker2D
{
    public override void _Draw()
    {
        if (!Engine.IsEditorHint())
            return;

        var label = GetType().Name;
        if (label.EndsWith("Marker"))
            label = label[..^"Marker".Length];

        var font = ThemeDB.FallbackFont;
        var size = ThemeDB.FallbackFontSize;
        var pos = new Vector2(8, -4);
        DrawString(font, pos + new Vector2(1, 1), label, HorizontalAlignment.Left, -1, size, Colors.Black);
        DrawString(font, pos, label, HorizontalAlignment.Left, -1, size, Colors.Yellow);
    }
}
