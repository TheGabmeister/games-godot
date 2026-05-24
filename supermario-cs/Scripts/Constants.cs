namespace SuperMario;

public static class Layers
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

public static class Constants
{
    // Player physics (mirrored from MonoGame PlayerController.cs)
    public const float Gravity = 1200f;
    public const float JumpForce = -680f;
    public const float MaxFallSpeed = 600f;
    public const float PlayerSpeed = 280f;
    public const float StompBounceForce = -420f;
    public const float StompTopTolerance = 16f;
    public const float PlayerInvulnDuration = 2f;
    public const int MaxFireballs = 2;

    // Player size (in pixels)
    public const int PlayerSmallWidth = 32;
    public const int PlayerSmallHeight = 48;
    public const int PlayerBigWidth = 32;
    public const int PlayerBigHeight = 64;

    // Platforms
    public const float MovingPlatformDistance = 160f;
    public const float MovingPlatformSpeed = 80f;

    // Blocks
    public const float BlockBumpDistance = 8f;
    public const float BlockBumpDuration = 0.18f;
    public const int BrickBreakScore = 50;

    // Coins / pickups
    public const int CoinValue = 200;
    public const int MushroomScore = 1000;
    public const int StarmanPickupScore = 1000;

    // Starman
    public const float StarmanSpeed = 220f;
    public const float StarmanBounceForce = -420f;
    public const float StarmanInvincibleDuration = 10f;

    // Enemies — walking
    public const float GoombaWalkSpeed = 80f;
    public const float GreenKoopaTroopaWalkSpeed = 80f;
    public const float RedKoopaTroopaWalkSpeed = 80f;
    public const float GreenKoopaParatroopaFlySpeed = 100f;
    public const float RedKoopaParatroopaFlySpeed = 100f;
    public const float BuzzyBeetleWalkSpeed = 80f;
    public const float SpinyWalkSpeed = 80f;

    // HammerBro
    public const float HammerBroShuffleSpeed = 40f;
    public const float HammerBroShuffleInterval = 1.2f;
    public const float HammerBroJumpForce = -520f;
    public const float HammerBroJumpInterval = 3.5f;
    public const float HammerBroThrowInterval = 2.0f;

    // Hammer (projectile)
    public const float HammerHorizontalSpeed = 220f;
    public const float HammerInitialUpSpeed = 520f;
    public const float HammerGravity = 1400f;
    public const float HammerLifetime = 3f;
    public const float HammerSpinSpeed = 18f;

    // Blooper
    public const float BlooperSpeed = 90f;
    public const float BlooperBobSpeed = 4f;
    public const float BlooperBobStrength = 24f;

    // BulletBill
    public const float BulletBillSpeed = 180f;
    public const float BulletBillLifetime = 5f;
    public const float BulletBillCannonFireInterval = 4f;

    // Podoboo
    public const float PodobooJumpSpeed = 520f;
    public const float PodobooGravity = 1200f;
    public const float PodobooRestDuration = 1f;

    // Fireball (mirrored from MonoGame Fireball.cs)
    public const float FireballSpeed = 400f;
    public const float FireballGravity = 1400f;
    public const float FireballBounceForce = -500f;
    public const float FireballMaxFallSpeed = 700f;
    public const float FireballLifetime = 3f;

    // Game
    public const int StartingLives = 3;
}
