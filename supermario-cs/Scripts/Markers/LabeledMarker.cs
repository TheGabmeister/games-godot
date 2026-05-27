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
        var size = ThemeDB.FallbackFontSize / 4;
        var textSize = font.GetStringSize(label, HorizontalAlignment.Left, -1, size);
        var pos = new Vector2(-textSize.X / 2, font.GetAscent(size) / 2);
        DrawString(font, pos + new Vector2(1, 1), label, HorizontalAlignment.Left, -1, size, Colors.Black);
        DrawString(font, pos, label, HorizontalAlignment.Left, -1, size, Colors.Yellow);
    }
}
