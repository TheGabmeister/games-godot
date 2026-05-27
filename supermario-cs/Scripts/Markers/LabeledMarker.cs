using Godot;

namespace SMB;

[Tool]
public partial class LabeledMarker : Marker2D
{
    private const int FontSize = 20;

    public override void _Draw()
    {
        if (!Engine.IsEditorHint())
            return;

        var label = GetType().Name;
        if (label.EndsWith("Marker"))
            label = label[..^"Marker".Length];

        var font = ThemeDB.FallbackFont;
        DrawSetTransform(Vector2.Zero, 0, Vector2.One / GetViewportTransform().Scale);

        var textSize = font.GetStringSize(label, HorizontalAlignment.Left, -1, FontSize);
        var pos = new Vector2(-textSize.X / 2, font.GetAscent(FontSize) / 2);
        DrawString(font, pos + Vector2.One, label, HorizontalAlignment.Left, -1, FontSize, Colors.Black);
        DrawString(font, pos, label, HorizontalAlignment.Left, -1, FontSize, Colors.Yellow);
    }
}
