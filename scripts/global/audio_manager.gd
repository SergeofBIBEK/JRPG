extends Node;

## ── Music ────────────────────────────────────────────────────────────

var _music_player: AudioStreamPlayer;
var _current_music: String = "";

const MUSIC_TRACKS: Dictionary = {
	"title": "res://audio/music/title.ogg",
	"town": "res://audio/music/town.ogg",
	"dungeon": "res://audio/music/dungeon.ogg",
	"battle": "res://audio/music/battle.ogg",
	"victory": "res://audio/music/victory.ogg",
	"game_over": "res://audio/music/game_over.ogg",
};

## ── SFX ──────────────────────────────────────────────────────────────

const SFX_TRACKS: Dictionary = {
	"menu_cursor": "res://audio/sfx/menu_cursor.wav",
	"menu_select": "res://audio/sfx/menu_select.wav",
	"menu_cancel": "res://audio/sfx/menu_cancel.wav",
	"save_confirm": "res://audio/sfx/save_confirm.wav",
	"attack_swing": "res://audio/sfx/attack_swing.wav",
	"hit": "res://audio/sfx/hit.wav",
	"item_use": "res://audio/sfx/item_use.wav",
	"dialog_advance": "res://audio/sfx/dialog_advance.wav",
	"item_pickup": "res://audio/sfx/item_pickup.wav",
};

const SFX_POOL_SIZE: int = 4;
var _sfx_players: Array[AudioStreamPlayer] = [];
var _sfx_index: int = 0;

## ── Preloaded Cache ──────────────────────────────────────────────────

var _music_cache: Dictionary = {};
var _sfx_cache: Dictionary = {};

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS;

	# Create music player
	_music_player = AudioStreamPlayer.new();
	_music_player.bus = "Master";
	_music_player.volume_db = -6.0;
	add_child(_music_player);

	# Create SFX player pool
	for i in SFX_POOL_SIZE:
		var player = AudioStreamPlayer.new();
		player.bus = "Master";
		player.volume_db = -3.0;
		add_child(player);
		_sfx_players.append(player);

	# Preload all audio
	_preload_audio();

func _preload_audio() -> void:
	for key in MUSIC_TRACKS:
		var path = MUSIC_TRACKS[key];
		if ResourceLoader.exists(path):
			_music_cache[key] = load(path);
		else:
			push_warning("[AudioManager] Music file not found: " + path);

	for key in SFX_TRACKS:
		var path = SFX_TRACKS[key];
		if ResourceLoader.exists(path):
			_sfx_cache[key] = load(path);
		else:
			push_warning("[AudioManager] SFX file not found: " + path);

## ── Public API ───────────────────────────────────────────────────────

func play_music(track_name: String, fade_time: float = 0.5) -> void:
	if track_name == _current_music and _music_player.playing:
		return;

	if track_name == "":
		stop_music(fade_time);
		return;

	if track_name not in _music_cache:
		push_warning("[AudioManager] Unknown music track: " + track_name);
		return;

	# Fade out current music, then start new
	if _music_player.playing and fade_time > 0.0:
		var tween = create_tween();
		tween.tween_property(_music_player, "volume_db", -40.0, fade_time);
		await tween.finished;

	_current_music = track_name;
	_music_player.stream = _music_cache[track_name];
	_music_player.volume_db = -6.0;
	_music_player.play();

func stop_music(fade_time: float = 0.5) -> void:
	if not _music_player.playing:
		_current_music = "";
		return;

	if fade_time > 0.0:
		var tween = create_tween();
		tween.tween_property(_music_player, "volume_db", -40.0, fade_time);
		await tween.finished;

	_music_player.stop();
	_current_music = "";
	_music_player.volume_db = -6.0;

func play_sfx(sfx_name: String) -> void:
	if sfx_name not in _sfx_cache:
		push_warning("[AudioManager] Unknown SFX: " + sfx_name);
		return;

	var player = _sfx_players[_sfx_index];
	player.stream = _sfx_cache[sfx_name];
	player.play();
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE;

func get_current_music() -> String:
	return _current_music;

## Play a short jingle (like victory), then resume previous music
func play_jingle(track_name: String, resume_after: bool = true) -> void:
	var previous_music = _current_music;

	_current_music = track_name;
	if track_name in _music_cache:
		_music_player.stream = _music_cache[track_name];
		_music_player.volume_db = -6.0;
		_music_player.play();

		if resume_after:
			await _music_player.finished;
			if _current_music == track_name:
				play_music(previous_music, 0.0);
