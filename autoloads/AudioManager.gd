extends Node

const SAMPLE_RATE := 44100.0

var bgm_volume: float = 0.15
var sfx_volume: float = 0.35

var _bgm_player: AudioStreamPlayer
var _bgm_playback: AudioStreamGeneratorPlayback = null
var _bgm_freqs: Array[float] = []
var _bgm_phases: Array[float] = []
var _bgm_on: bool = false

var _sfx_player: AudioStreamPlayer
var _sfx_playback: AudioStreamGeneratorPlayback = null
var _sfx_freqs: Array[float] = []
var _sfx_phases: Array[float] = []
var _sfx_samples_left: int = 0

func _ready() -> void:
	_bgm_player = _make_gen_player(0.1)
	_sfx_player = _make_gen_player(0.5)
	add_child(_bgm_player)
	add_child(_sfx_player)

func _make_gen_player(buffer: float) -> AudioStreamPlayer:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = SAMPLE_RATE
	gen.buffer_length = buffer
	var p := AudioStreamPlayer.new()
	p.stream = gen
	return p

func play_world_bgm() -> void:
	_start_bgm([261.6, 329.6, 392.0])

func play_battle_bgm() -> void:
	_start_bgm([220.0, 277.2, 329.6])

func stop_bgm() -> void:
	_bgm_on = false
	_bgm_player.stop()

func play_sfx_attack() -> void:  _play_sfx([180.0, 120.0], 0.08)
func play_sfx_spell() -> void:   _play_sfx([880.0, 1108.7, 1318.5], 0.15)
func play_sfx_levelup() -> void: _play_sfx([392.0, 523.2, 659.2, 783.9], 0.18)
func play_sfx_button() -> void:  _play_sfx([440.0], 0.05)
func play_sfx_victory() -> void: _play_sfx([523.2, 659.2, 784.0, 1046.5], 0.22)

func set_bgm_volume(v: float) -> void:
	bgm_volume = clampf(v, 0.0, 1.0)
	_bgm_player.volume_db = linear_to_db(bgm_volume + 0.001)

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)

func _start_bgm(freqs: Array[float]) -> void:
	_bgm_freqs = freqs
	_bgm_phases.resize(_bgm_freqs.size())
	_bgm_phases.fill(0.0)
	_bgm_on = true
	_bgm_player.volume_db = linear_to_db(bgm_volume + 0.001)
	_bgm_player.play()
	_bgm_playback = _bgm_player.get_stream_playback()

func _play_sfx(freqs: Array[float], duration: float) -> void:
	_sfx_freqs = freqs
	_sfx_phases.resize(_sfx_freqs.size())
	_sfx_phases.fill(0.0)
	_sfx_samples_left = int(SAMPLE_RATE * duration)
	if not _sfx_player.playing:
		_sfx_player.volume_db = linear_to_db(sfx_volume + 0.001)
		_sfx_player.play()
		_sfx_playback = _sfx_player.get_stream_playback()

func _process(_delta: float) -> void:
	if _bgm_on and _bgm_playback:
		var n := _bgm_playback.get_frames_available()
		for _i in n:
			var s := 0.0
			for j in _bgm_freqs.size():
				s += sin(_bgm_phases[j] * TAU) / _bgm_freqs.size()
				_bgm_phases[j] = fmod(_bgm_phases[j] + _bgm_freqs[j] / SAMPLE_RATE, 1.0)
			_bgm_playback.push_frame(Vector2(s, s))

	if _sfx_samples_left > 0 and _sfx_playback:
		var n := _sfx_playback.get_frames_available()
		for _i in n:
			if _sfx_samples_left <= 0:
				break
			var s := 0.0
			var fade := float(_sfx_samples_left) / float(max(_sfx_samples_left, 2205))
			for j in _sfx_freqs.size():
				s += sin(_sfx_phases[j] * TAU) / _sfx_freqs.size()
				_sfx_phases[j] = fmod(_sfx_phases[j] + _sfx_freqs[j] / SAMPLE_RATE, 1.0)
			var sample := s * sfx_volume * minf(fade, 1.0)
			_sfx_playback.push_frame(Vector2(sample, sample))
			_sfx_samples_left -= 1
