using System;
using Godot;

namespace SuperMario;

public partial class TextPopupSpawner : Node
{
    private GameEvents _events;
    private Func<Node> _getPopupRoot;

    public void Initialize(GameEvents events, Func<Node> getPopupRoot)
    {
        _events = events;
        _getPopupRoot = getPopupRoot;

        _events.ScoreEarnedAt += OnScoreEarnedAt;
    }

    public override void _ExitTree()
    {
        if (_events != null)
            _events.ScoreEarnedAt -= OnScoreEarnedAt;
    }

    private void OnScoreEarnedAt(int points, Vector2 worldPosition)
    {
        Spawn("+" + points, worldPosition);
    }

    private void Spawn(string text, Vector2 worldPosition)
    {
        var root = _getPopupRoot();
        var popup = new TextPopup();

        popup.Initialize(text);
        root.AddChild(popup);
        popup.GlobalPosition = worldPosition;
        popup.Play();
    }
}
