using System;
using Godot;

namespace SuperMario;

public partial class PlayerController : CharacterBody2D
{
    public event Action Died;

    [Export] public PackedScene FireballScene;

    private static readonly StringName InputLeft = "move_left";
    private static readonly StringName InputRight = "move_right";
    private static readonly StringName InputJump = "jump";
    private static readonly StringName InputFire = "run"; // X / J → fire when Fire power

    private ColorRect _visual;
    private CollisionShape2D _shape;
    private Blinker _blinker;
    private Marker2D _muzzle;
    private Vector2 _velocity;
    private int _facing = 1;
    private int _activeFireballs;
    private float _invulnTimer;
    private float _starTimer;
    private bool _dead;
    private PlayerPowerState _state = PlayerPowerState.Small;

    public PlayerPowerState State => _state;
    public bool IsStarInvincible => _starTimer > 0f;
    public bool IsInvulnerable => _invulnTimer > 0f;
    public bool CanBreakBricks => _state != PlayerPowerState.Small;

    public override void _Ready()
    {
        AddToGroup("player");
        CollisionLayer = Layers.Player;
        CollisionMask = Layers.Environment | Layers.PickupTrigger | Layers.LevelTrigger;

        _visual = GetNode<ColorRect>("Visual");
        _shape = GetNode<CollisionShape2D>("CollisionShape2D");
        _blinker = GetNode<Blinker>("Blinker");
        _blinker.Target = _visual;
        _muzzle = GetNode<Marker2D>("Muzzle");

        _state = GameSession.Instance.State.PowerState;
        ApplyStateVisuals();
    }

    public override void _PhysicsProcess(double delta)
    {
        if (_dead) return;

        float dt = (float)delta;
        if (_invulnTimer > 0f) _invulnTimer -= dt;
        if (_starTimer > 0f) _starTimer -= dt;

        float axis = 0f;
        if (Input.IsActionPressed(InputLeft)) axis -= 1f;
        if (Input.IsActionPressed(InputRight)) axis += 1f;

        _velocity.X = axis * Constants.PlayerSpeed;
        if (axis != 0f) _facing = axis > 0f ? 1 : -1;

        if (IsOnFloor() && Input.IsActionJustPressed(InputJump))
        {
            _velocity.Y = Constants.JumpForce;
        }

        if (Input.IsActionJustPressed(InputFire) && _state == PlayerPowerState.Fire
            && _activeFireballs < Constants.MaxFireballs)
        {
            SpawnFireball();
        }

        _velocity.Y += Constants.Gravity * dt;
        if (_velocity.Y > Constants.MaxFallSpeed)
            _velocity.Y = Constants.MaxFallSpeed;

        Velocity = _velocity;
        MoveAndSlide();
        _velocity = Velocity;

        for (int i = 0; i < GetSlideCollisionCount(); i++)
        {
            var col = GetSlideCollision(i);
            var normal = col.GetNormal();
            if (normal.Y > 0.9f)
            {
                if (col.GetCollider() is IBumpable bumpable)
                    bumpable.OnBumped(this);
                _velocity.Y = 0f;
            }
        }
    }

    private void SpawnFireball()
    {
        var fb = FireballScene.Instantiate<Fireball>();
        var pos = _muzzle.GlobalPosition;
        fb.Init(pos, _facing, this);
        var parent = (Node)GameSession.Instance.CurrentLevel;
        parent.AddChild(fb);
        _activeFireballs++;
    }

    public void NotifyFireballDestroyed()
    {
        if (_activeFireballs > 0) _activeFireballs--;
    }

    public void ApplyMushroom()
    {
        if (_state != PlayerPowerState.Small) return;
        SetState(PlayerPowerState.Big);
    }

    public void ApplyFireFlower()
    {
        if (_state == PlayerPowerState.Fire) return;
        SetState(_state == PlayerPowerState.Small ? PlayerPowerState.Big : PlayerPowerState.Fire);
    }

    public void ApplyStarman()
    {
        _starTimer = Constants.StarmanInvincibleDuration;
    }

    public void TakeDamage()
    {
        if (_invulnTimer > 0f || _starTimer > 0f || _dead) return;

        if (_state == PlayerPowerState.Small)
        {
            KillPlayer();
            return;
        }

        SetState(PlayerPowerState.Small);
        _invulnTimer = Constants.PlayerInvulnDuration;
        _blinker.Start(Constants.PlayerInvulnDuration);
    }

    public void KillPlayer()
    {
        if (_dead) return;
        _dead = true;
        Died?.Invoke();
        QueueFree();
    }

    public bool TryStomp(IStompable stompable)
    {
        if (_velocity.Y <= 0f) return false;
        _velocity.Y = Constants.StompBounceForce;
        stompable.OnStomped(this);
        return true;
    }

    private void SetState(PlayerPowerState newState)
    {
        _state = newState;
        GameSession.Instance.EmitPlayerPowerStateChanged(newState);
        ApplyStateVisuals();
    }

    private void ApplyStateVisuals()
    {
        int w, h;
        Color color;
        switch (_state)
        {
            case PlayerPowerState.Big:  w = Constants.PlayerBigWidth;   h = Constants.PlayerBigHeight;   color = new Color(0.85f, 0.10f, 0.10f); break;
            case PlayerPowerState.Fire: w = Constants.PlayerBigWidth;   h = Constants.PlayerBigHeight;   color = new Color(1.00f, 0.55f, 0.10f); break;
            default:                    w = Constants.PlayerSmallWidth; h = Constants.PlayerSmallHeight; color = new Color(0.85f, 0.10f, 0.10f); break;
        }

        _visual.Size = new Vector2(w, h);
        _visual.Position = new Vector2(-w / 2f, -h);
        _visual.Color = color;

        var rect = (RectangleShape2D)_shape.Shape;
        rect.Size = new Vector2(w, h);
        _shape.Position = new Vector2(0, -h / 2f);
    }
}
