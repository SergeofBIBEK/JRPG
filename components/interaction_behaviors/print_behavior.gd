class_name PrintBehavior;
extends InteractionBehavior;

func process_interaction():
	print("I WAS INTERACTED WITH!");

func _init():
	interaction_name = "Print";
