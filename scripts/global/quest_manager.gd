extends Node;

## Simple flag-based quest state. Flags are string keys that are either set or not.
var _flags: Dictionary = {};

func set_flag(flag_name: String) -> void:
	_flags[flag_name] = true;

func has_flag(flag_name: String) -> bool:
	return _flags.get(flag_name, false);

func clear_flag(flag_name: String) -> void:
	_flags.erase(flag_name);
