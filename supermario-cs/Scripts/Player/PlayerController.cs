using System;
using Godot;
using supermariocs.Autoloads;
using supermariocs.Interfaces;

namespace supermariocs.Player;

public partial class PlayerController : CharacterBody2D
{
    public event Action Died;

    [Export] public PackedScene FireballScene;
    [Export] public ColorRect Visual;
    [Export] public CollisionShape2D Shape;
    [Export] public Blinker Blinker;
    [Export] public Marker2D Muzzle;

    private static readonly StringName InputLeft = "move_left";
    private static readonly StringName InputRight = "move_right";
    private static readonly StringName InputJump = "jump";
    private static readonly StringName InputFire = "run"; // X / J → fire when Fire power

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

        if (GameManager.Instance?.State != null)
            _state = GameManager.Instance.State.PowerState;
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
            && _activeFireballs < Constants.MaxFireballs && FireballScene != null)
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
        var fb = FireballScene.Instantiate<Entities.Fireball>();
        var pos = Muzzle != null ? Muzzle.GlobalPosition : GlobalPosition;
        fb.Init(pos, _facing, this);
        var parent = (Node)GameManager.Instance?.CurrentLevel ?? GetTree().CurrentScene;
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
        Blinker?.Start(Constants.PlayerInvulnDuration);
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
        if (GameManager.Instance?.State != null)
            GameManager.Instance.State.PowerState = newState;
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

        if (Visual != null)
        {
            Visual.Size = new Vector2(w, h);
            Visual.Position = new Vector2(-w / 2f, -h);
            Visual.Color = color;
        }

        if (Shape?.Shape is RectangleShape2D rect)
        {
            rect.Size = new Vector2(w, h);
            Shape.Position = new Vector2(0, -h / 2f);
        }
    }
}
