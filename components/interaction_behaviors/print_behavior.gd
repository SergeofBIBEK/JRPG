class_name PrintBehavior;
extends InteractionBehavior;

func process_interaction():
	print("I WAS INTERACTED WITH!" , interaction_name);

func _init():
	interaction_name = "Print";
