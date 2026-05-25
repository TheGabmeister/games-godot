using System;

namespace SuperMario;

public interface ICoinEventSource
{
    event Action<int> CoinsCollected;
}
