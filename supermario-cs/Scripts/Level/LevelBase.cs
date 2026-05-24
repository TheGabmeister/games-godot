using Godot;

namespace SuperMario;

public partial class LevelBase : Node2D
{
    [Export] public LevelDefinition Config;
    [Export] public PackedScene PlayerScene;

    [Signal] public delegate void LevelCompletedEventHandler();
    [Signal] public delegate void PlayerDiedEventHandler();

    private bool _initialized;

    public void Initialize(LevelDefinition config)
    {
        Config = config;

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
        var start = GetNode<Marker2D>("PlayerStart");
        var player = PlayerScene.Instantiate<PlayerController>();
        player.GlobalPosition = start.GlobalPosition;
        AddChild(player);
        player.Died += () => EmitSignal(SignalName.PlayerDied);

        var goal = GetNode<GoalTrigger>("GoalTrigger");
        goal.Reached += () => EmitSignal(SignalName.LevelCompleted);
    }
}
