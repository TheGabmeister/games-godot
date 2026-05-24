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

        _events.TextPopupRequested += OnTextPopupRequested;
    }

    public override void _ExitTree()
    {
        if (_events != null)
            _events.TextPopupRequested -= OnTextPopupRequested;
    }

    private void OnTextPopupRequested(string text, Vector2 worldPosition)
    {
        Spawn(text, worldPosition);
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
