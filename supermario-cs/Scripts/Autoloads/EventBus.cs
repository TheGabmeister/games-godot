using Godot;

namespace supermariocs;

public partial class EventBus : Node
{
	// Player
	[Signal] public delegate void PlayerDiedEventHandler();
	[Signal] public delegate void PlayerRespawnedEventHandler();
	[Signal] public delegate void PlayerPoweredUpEventHandler(StringName powerUpType);
	[Signal] public delegate void PlayerPowerStateChangedEventHandler(int oldState, int newState);
	[Signal] public delegate void PlayerDamagedEventHandler();
	[Signal] public delegate void PlayerStarPowerStartedEventHandler();
	[Signal] public delegate void PlayerStarPowerEndedEventHandler();

	// Scoring and HUD
	[Signal] public delegate void CoinCollectedEventHandler(Vector2 position);
	[Signal] public delegate void ScoreAwardedEventHandler(int points, Vector2 position);
	[Signal] public delegate void ScoreChangedEventHandler(int newScore);
	[Signal] public delegate void LivesChangedEventHandler(int newLives);
	[Signal] public delegate void CoinsChangedEventHandler(int newCoinCount);
	[Signal] public delegate void TimeTickEventHandler(int timeRemaining);
	[Signal] public delegate void OneUpEarnedEventHandler();

	// Level
	[Signal] public delegate void LevelStartedEventHandler(int world, int level);
	[Signal] public delegate void LevelCompletedEventHandler();
	[Signal] public delegate void FlagpoleReachedEventHandler(float heightRatio);

	// Enemies
	[Signal] public delegate void EnemyStompedEventHandler(Vector2 position);
	[Signal] public delegate void EnemyKilledEventHandler(Vector2 position, StringName enemyType);
	[Signal] public delegate void ComboStompEventHandler(int count, Vector2 position);

	// Blocks and items
	[Signal] public delegate void BlockBumpedEventHandler(Vector2 position);
	[Signal] public delegate void BlockBrokenEventHandler(Vector2 position);
	[Signal] public delegate void ItemSpawnedEventHandler(StringName itemType, Vector2 position);

	// Game state
	[Signal] public delegate void GamePausedEventHandler();
	[Signal] public delegate void GameResumedEventHandler();
	[Signal] public delegate void GameOverEventHandler();

	public override void _Ready()
	{
		GD.Print("[EventBus] ready");
	}
}
