using System;
using Godot;

namespace SuperMario;

public interface ITextPopupEventSource
{
    event Action<string, Vector2> TextPopupRequested;
}
