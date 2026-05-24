using Godot;
using supermariocs.Autoloads;
using supermariocs.Player;
using supermariocs.Resources;
using supermariocs.Ui;

namespace supermariocs.Level;

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

        _state ??= GameManager.Instance?.State;

        if (Config == null)
            GD.PushWarning($"LevelBase {Name}: Config is not assigned.");

        SetupLevel();
    }

    private void SetupLevel()
    {
        if (Config != null && Config.MusicTrack != null)
            MusicManager.Instance?.Play(Config.MusicTrack);

        var start = GetNodeOrNull<Marker2D>("PlayerStart");
        if (PlayerScene != null)
        {
            if (start == null)
            {
                GD.PushError($"LevelBase {Name}: PlayerStart marker is required.");
            }
            else
            {
                var player = PlayerScene.Instantiate<PlayerController>();
                player.GlobalPosition = start.GlobalPosition;
                AddChild(player);
                player.Died += () => EmitSignal(SignalName.PlayerDied);
            }
        }

        var goal = GetNodeOrNull<GoalTrigger>("GoalTrigger");
        if (goal != null)
            goal.Reached += () => EmitSignal(SignalName.LevelCompleted);

        if (HudScene != null)
        {
            var hud = HudScene.Instantiate<Hud>();
            hud.Bind(_state);
            AddChild(hud);
        }
    }
}
