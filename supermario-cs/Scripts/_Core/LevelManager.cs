using System;
using Godot;

namespace SMB;

public partial class LevelManager : Node2D
{
    [Export] public Marker2D PlayerStart;
    [Export] public GoalTrigger GoalTrigger;
    [Export] private Node _markerRoot;

    private IScoreAwarder _scoreAwarder;
    private ICoinCollector _coinCollector;

    public void Initialize(IScoreAwarder scoreAwarder, ICoinCollector coinCollector)
    {
        _scoreAwarder = scoreAwarder ?? throw new ArgumentNullException(nameof(scoreAwarder));
        _coinCollector = coinCollector ?? throw new ArgumentNullException(nameof(coinCollector));
    }

    public override void _Ready()
    {
        if (PlayerStart == null)
            throw new InvalidOperationException($"{nameof(LevelManager)} requires {nameof(PlayerStart)} to be assigned in the editor.");

        if (GoalTrigger == null)
            throw new InvalidOperationException($"{nameof(LevelManager)} requires {nameof(GoalTrigger)} to be assigned in the editor.");

        if (_markerRoot == null)
            throw new InvalidOperationException($"{nameof(LevelManager)} requires {nameof(_markerRoot)} to be assigned in the editor.");

        if (_scoreAwarder == null || _coinCollector == null)
            throw new InvalidOperationException($"{nameof(LevelManager)} requires score and coin services before markers can spawn.");

        SpawnMarkers();
    }

    private void SpawnMarkers()
    {
        foreach (var child in _markerRoot.GetChildren())
        {
            switch (child)
            {
                case CoinMarker m:
                    AddChild(Coin.Create(m.GlobalPosition, _scoreAwarder, _coinCollector));
                    break;
                case QuestionBlockMarker m:
                    AddChild(QuestionBlock.Create(m.GlobalPosition, _scoreAwarder, _coinCollector));
                    break;
                case BrickBlockMarker m:
                    AddChild(BrickBlock.Create(m.GlobalPosition, _scoreAwarder));
                    break;
                case MushroomMarker m:
                    AddChild(Mushroom.Create(m.GlobalPosition, _scoreAwarder));
                    break;
                case StarmanMarker m:
                    AddChild(Starman.Create(m.GlobalPosition, _scoreAwarder));
                    break;
                case FireFlowerMarker m:
                    AddChild(FireFlower.Create(m.GlobalPosition, _scoreAwarder));
                    break;
            }
        }
    }
}
