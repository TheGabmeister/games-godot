using System;
using System.Collections.Generic;
using Godot;

namespace SuperMario;

public partial class LevelManager : Node2D
{
    public event Action<int> ScoreEarned;
    public event Action<int> CoinsCollected;

    [Export] public Marker2D PlayerStart;
    [Export] public GoalTrigger GoalTrigger;
    [Export] private Node _markerRoot;

    public GameEvents Events;

    private readonly HashSet<Node> _wiredEventSources = new();

    public override void _Ready()
    {
        if (PlayerStart == null)
            throw new InvalidOperationException($"{nameof(LevelManager)} requires {nameof(PlayerStart)} to be assigned in the editor.");

        if (GoalTrigger == null)
            throw new InvalidOperationException($"{nameof(LevelManager)} requires {nameof(GoalTrigger)} to be assigned in the editor.");

        if (_markerRoot == null)
            throw new InvalidOperationException($"{nameof(LevelManager)} requires {nameof(_markerRoot)} to be assigned in the editor.");

        WireEventSources(this);
        SpawnMarkers();
    }

    private void SpawnMarkers()
    {
        foreach (var child in _markerRoot.GetChildren())
        {
            switch (child)
            {
                case CoinMarker coinMarker:
                    AddRuntimeEntity(Coin.Create(coinMarker.GlobalPosition, Events));
                    break;
            }
        }
    }

    private void AddRuntimeEntity(Node entity)
    {
        AddChild(entity);
        WireEventSources(entity);
    }

    private void OnChildEnteredTree(Node child)
    {
        WireEventSources(child);
    }

    private void WireEventSources(Node root)
    {
        if (!_wiredEventSources.Add(root)) return;
        root.ChildEnteredTree += OnChildEnteredTree;

        if (root is IScoreEventSource scoreSource)
            scoreSource.ScoreEarned += points => ScoreEarned?.Invoke(points);

        if (root is ICoinEventSource coinSource)
            coinSource.CoinCollected += coins => CoinsCollected?.Invoke(coins);

        foreach (var child in root.GetChildren())
            WireEventSources(child);
    }
}
