using Godot;

namespace SuperMario;

public partial class LevelBase : Node2D
{
    [Export] public LevelDefinition Config;
    [Export] public PackedScene PlayerScene;
    [Export] public PackedScene HudScene;

    [Signal] public delegate void LevelCompletedEventHandler();
    [Signal] public delegate void PlayerDiedEventHandler();

    private GameState _state;
    private bool _initialized;

    public void Initialize(LevelDefinition config, GameState state)
    {
        Config = config;
        _state = state;

        if (IsInsideTree())
            InitializeOnce();
    }

    public override void _Ready()
    {
        InitializeOnce();
    }

    private void InitializeOnce()
    {
        if (_initialized) return;
        _initialized = true;

        SetupLevel();
    }

    private void SetupLevel()
    {
        if (Config != null && Config.MusicTrack != null)
            MusicManager.Instance?.Play(Config.MusicTrack);

        var start = GetNode<Marker2D>("PlayerStart");
        var player = PlayerScene.Instantiate<PlayerController>();
        player.GlobalPosition = start.GlobalPosition;
        AddChild(player);
        player.Died += () => EmitSignal(SignalName.PlayerDied);

        var goal = GetNode<GoalTrigger>("GoalTrigger");
        goal.Reached += () => EmitSignal(SignalName.LevelCompleted);

        var hud = HudScene.Instantiate<Hud>();
        hud.Bind(_state);
        AddChild(hud);
    }
}
