using Godot;

namespace SMB.EventBus;

public struct EV_SfxPlay : IEvent
{
    public AudioStream value;
}

public struct EV_TextSpawn : IEvent
{
    public string text;
    public Vector2 position;
}
