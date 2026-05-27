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

public struct EV_ScoreEarned : IEvent
{
    public int value;
}

public struct EV_Pickup_Coin : IEvent
{
    public int value;
}

public struct EV_Pickup_Mushroom : IEvent
{
    public PlayerController player;
}

public struct EV_Pickup_FireFlower : IEvent
{
    public PlayerController player;
}

public struct EV_Pickup_Starman : IEvent
{
    public PlayerController player;
}

public struct EV_Pickup_OneUp : IEvent
{
}
