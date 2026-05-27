using System;
using Godot;

namespace SMB;

public partial class LevelManager : Node2D
{
    [Export] public Marker2D PlayerStart;
    [Export] public GoalTrigger GoalTrigger;
    [Export] private Node _markerRoot;

    public override void _Ready()
    {
        if (PlayerStart == null)
            throw new InvalidOperationException($"{nameof(LevelManager)} requires {nameof(PlayerStart)} to be assigned in the editor.");

        if (GoalTrigger == null)
            throw new InvalidOperationException($"{nameof(LevelManager)} requires {nameof(GoalTrigger)} to be assigned in the editor.");

        if (_markerRoot == null)
            throw new InvalidOperationException($"{nameof(LevelManager)} requires {nameof(_markerRoot)} to be assigned in the editor.");

        SpawnMarkers();
    }

    private void SpawnMarkers()
    {
        foreach (var child in _markerRoot.GetChildren())
        {
            switch (child)
            {
                case CoinMarker m:
                    AddChild(Coin.Create(m.GlobalPosition));
                    break;
                case QuestionBlockMarker m:
                    AddChild(QuestionBlock.Create(m.GlobalPosition));
                    break;
                case BrickBlockMarker m:
                    AddChild(BrickBlock.Create(m.GlobalPosition));
                    break;
                case MushroomMarker m:
                    AddChild(Mushroom.Create(m.GlobalPosition));
                    break;
                case StarmanMarker m:
                    AddChild(Starman.Create(m.GlobalPosition));
                    break;
                case FireFlowerMarker m:
                    AddChild(FireFlower.Create(m.GlobalPosition));
                    break;
            }
        }
    }
}
