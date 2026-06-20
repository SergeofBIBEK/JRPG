class_name BattleBehavior;
extends InteractionBehavior;

func process_interaction():
	Events.battle_requested.emit();

func _init():
	interaction_name = "Fight";
