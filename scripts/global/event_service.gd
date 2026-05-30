extends Node;

signal show_interaction_prompt(world_position: Vector2, list: Array[InteractionPromptData]);
signal hide_interaction_prompt();

signal show_dialog(dialog_image: Texture2D, dialog_text: Array[String], dialog_name: String);
signal hide_dialog();

signal transition_requested(target_scene_path: String, spawn_location: String);

signal menu_opened();
signal menu_closed();

signal menu_items_requested();
signal menu_status_requested();
signal menu_save_requested();
signal menu_quit_requested();

var pending_spawn_location: String = "";
