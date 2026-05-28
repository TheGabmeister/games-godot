namespace SMB;

public static class PhysicsLayers
{
    public const uint Player = 1u << 0;
    public const uint Enemy = 1u << 1;
    public const uint PickupBody = 1u << 2;
    public const uint Environment = 1u << 3;
    public const uint Projectile = 1u << 4;
    public const uint EnemyProjectile = 1u << 5;
    public const uint PickupTrigger = 1u << 6;
    public const uint LevelTrigger = 1u << 7;
}
