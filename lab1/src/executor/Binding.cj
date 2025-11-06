package cjcj.executor

import std.deriving.Derive

/**
 * Runtime binding for a variable stored inside an environment.
 *
 * Uninitialized: the declaration has been seen but no value has been assigned yet.
 * Initialized(value): the variable currently holds a concrete Value.
 */
@Derive[ToString]
public enum Binding {
    | LET_Uninitialized(Value)
    | VAR_Uninitialized(Value)
    | VAR_Initialized(Value)
    | LET_Initialized(Value)

    public static func letFrom(value: Value): Binding {
        Binding.LET_Initialized(value)
    }

    public static func varFrom(value: Value): Binding {
        Binding.VAR_Initialized(value)
    }

    public static func getValue(binding: Binding): Value {
        match (binding) {
            case Binding.LET_Uninitialized(_) => throw Exception("Trying to access uninitialized let binding")
            case Binding.VAR_Uninitialized(_) => throw Exception("Trying to access uninitialized var binding")
            case Binding.LET_Initialized(v) => v
            case Binding.VAR_Initialized(v) => v
        }
    }
}