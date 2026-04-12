using Godot;

namespace supermariocs;

public partial class GameManager : Node
{
	public enum PowerState { Small, Big, Fire }
	public enum GameState { Title, Playing, Paused, GameOver, LevelComplete, Transitioning }

	public int Score { get; private set; } = 0;
	public int Coins { get; private set; } = 0;
	public int Lives { get; private set; } = 3;
	public float TimeRemaining { get; private set; } = 400.0f;
	public int CurrentWorld { get; private set; } = 1;
	public int CurrentLevel { get; private set; } = 1;
	public PowerState CurrentPowerState { get; private set; } = PowerState.Small;
	public GameState CurrentGameState { get; private set; } = GameState.Title;

	public override void _Ready()
	{
		GD.Print($"[GameManager] ready (state={CurrentGameState})");
	}

	public void StartNewGame()
	{
		Score = 0;
		Coins = 0;
		Lives = 3;
		CurrentWorld = 1;
		CurrentLevel = 1;
		CurrentPowerState = PowerState.Small;
		SetGameState(GameState.Playing);
	}

	public void StartLevel(LevelConfig config)
	{
		if (config == null) return;
		CurrentWorld = config.World;
		CurrentLevel = config.Level;
		TimeRemaining = config.TimeLimit;
	}

	public void AddScore(int points, Vector2 position = default)
	{
		Score += points;
	}

	public void AddCoin(Vector2 position = default)
	{
		Coins++;
	}

	public void LoseLife()
	{
		Lives--;
		CurrentPowerState = PowerState.Small;
	}

	public void SetPowerState(PowerState state)
	{
		CurrentPowerState = state;
	}

	public void SetGameState(GameState state)
	{
		if (CurrentGameState == state) return;
		var previous = CurrentGameState;
		CurrentGameState = state;
		GD.Print($"[GameManager] state {previous} -> {state}");
	}
}
