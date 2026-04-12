using Godot;

namespace supermariocs;

public partial class GameManager : Node
{
	public enum PowerState { Small, Big, Fire }
	public enum GameState { Title, Playing, Paused, GameOver, LevelComplete, Transitioning }

	private const int CoinsPerExtraLife = 100;

	public int Score { get; private set; } = 0;
	public int Coins { get; private set; } = 0;
	public int Lives { get; private set; } = 3;
	public int TimeRemaining { get; private set; } = 400;
	public int CurrentWorld { get; private set; } = 1;
	public int CurrentLevel { get; private set; } = 1;
	public PowerState CurrentPowerState { get; private set; } = PowerState.Small;
	public GameState CurrentGameState { get; private set; } = GameState.Title;

	private EventBus _bus;
	private float _timerAccumulator;

	public override void _Ready()
	{
		_bus = GetNode<EventBus>("/root/EventBus");
		GD.Print($"[GameManager] ready (state={CurrentGameState})");
	}

	public override void _Process(double delta)
	{
		if (CurrentGameState != GameState.Playing) return;
		if (TimeRemaining <= 0) return;

		_timerAccumulator += (float)delta;
		while (_timerAccumulator >= 1.0f)
		{
			_timerAccumulator -= 1.0f;
			TimeRemaining = Mathf.Max(0, TimeRemaining - 1);
			_bus.EmitSignal(EventBus.SignalName.TimeTick, TimeRemaining);
			if (TimeRemaining == 0)
			{
				LoseLife();
				return;
			}
		}
	}

	public void StartNewGame()
	{
		Score = 0;
		Coins = 0;
		Lives = 3;
		CurrentWorld = 1;
		CurrentLevel = 1;
		CurrentPowerState = PowerState.Small;
		_bus.EmitSignal(EventBus.SignalName.ScoreChanged, Score);
		_bus.EmitSignal(EventBus.SignalName.CoinsChanged, Coins);
		_bus.EmitSignal(EventBus.SignalName.LivesChanged, Lives);
		SetGameState(GameState.Playing);
	}

	public void StartLevel(LevelConfig config)
	{
		if (config == null) return;
		CurrentWorld = config.World;
		CurrentLevel = config.Level;
		TimeRemaining = (int)config.TimeLimit;
		_timerAccumulator = 0;
		SetGameState(GameState.Playing);
		_bus.EmitSignal(EventBus.SignalName.LevelStarted, CurrentWorld, CurrentLevel);
		_bus.EmitSignal(EventBus.SignalName.TimeTick, TimeRemaining);
	}

	public void AddScore(int points, Vector2 position = default)
	{
		Score += points;
		_bus.EmitSignal(EventBus.SignalName.ScoreAwarded, points, position);
		_bus.EmitSignal(EventBus.SignalName.ScoreChanged, Score);
	}

	public void AddCoin(Vector2 position = default)
	{
		Coins++;
		_bus.EmitSignal(EventBus.SignalName.CoinCollected, position);
		_bus.EmitSignal(EventBus.SignalName.CoinsChanged, Coins);
		AddScore(200, position);
		if (Coins >= CoinsPerExtraLife)
		{
			Coins -= CoinsPerExtraLife;
			GrantOneUp();
			_bus.EmitSignal(EventBus.SignalName.CoinsChanged, Coins);
		}
	}

	public void GrantOneUp()
	{
		Lives++;
		_bus.EmitSignal(EventBus.SignalName.OneUpEarned);
		_bus.EmitSignal(EventBus.SignalName.LivesChanged, Lives);
	}

	public void LoseLife()
	{
		Lives--;
		CurrentPowerState = PowerState.Small;
		_bus.EmitSignal(EventBus.SignalName.LivesChanged, Lives);
		_bus.EmitSignal(EventBus.SignalName.PlayerDied);
		if (Lives <= 0)
		{
			SetGameState(GameState.GameOver);
			_bus.EmitSignal(EventBus.SignalName.GameOver);
		}
	}

	public void SetPowerState(PowerState state)
	{
		var previous = CurrentPowerState;
		if (previous == state) return;
		CurrentPowerState = state;
		_bus.EmitSignal(EventBus.SignalName.PlayerPowerStateChanged, (int)previous, (int)state);
	}

	public void SetGameState(GameState state)
	{
		if (CurrentGameState == state) return;
		var previous = CurrentGameState;
		CurrentGameState = state;
		GD.Print($"[GameManager] state {previous} -> {state}");
		if (state == GameState.Paused) _bus.EmitSignal(EventBus.SignalName.GamePaused);
		else if (previous == GameState.Paused) _bus.EmitSignal(EventBus.SignalName.GameResumed);
	}
}
