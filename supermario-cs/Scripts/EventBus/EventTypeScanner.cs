using System;
using System.Collections.Generic;
using System.Reflection;

namespace SMB.EventBus;

public static class EventTypeScanner
{
    public static List<Type> GetTypes(Type interfaceType)
    {
        var types = new List<Type>();

        foreach (var assembly in AppDomain.CurrentDomain.GetAssemblies())
            AddTypesFromAssembly(GetLoadableTypes(assembly), interfaceType, types);

        return types;
    }

    private static void AddTypesFromAssembly(Type[] assemblyTypes, Type interfaceType, ICollection<Type> results)
    {
        foreach (var type in assemblyTypes)
        {
            if (type == interfaceType) continue;
            if (!type.IsValueType) continue;
            if (type.ContainsGenericParameters) continue;
            if (!interfaceType.IsAssignableFrom(type)) continue;

            results.Add(type);
        }
    }

    private static Type[] GetLoadableTypes(Assembly assembly)
    {
        if (assembly.IsDynamic)
            return Array.Empty<Type>();

        try
        {
            return assembly.GetTypes();
        }
        catch (ReflectionTypeLoadException ex)
        {
            var types = new List<Type>();
            foreach (var type in ex.Types)
            {
                if (type != null)
                    types.Add(type);
            }
            return types.ToArray();
        }
        catch (NotSupportedException)
        {
            return Array.Empty<Type>();
        }
    }
}
