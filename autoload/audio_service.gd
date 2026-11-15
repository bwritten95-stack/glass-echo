extends Node
## Lightweight procedural SFX via AudioStreamGenerator — no external assets required.

const BUS_SFX := "SFX"

var _players: Array[AudioStreamPlayer] = []
var _pool_size: int = 8
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_ensure_sfx_bus()
	for i in _pool_size:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		add_child(p)
		_players.append(p)
	SettingsStore.apply()

func _ensure_sfx_bus() -> void:
	if AudioServer.get_bus_index(BUS_SFX) >= 0:
		return
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, BUS_SFX)
	AudioServer.set_bus_send(idx, "Master")

func play_dash() -> void:
	_play_tone(880.0, 0.07, 0.22, "down")

func play_shatter() -> void:
	_play_noise_burst(0.12, 0.35, 1800.0)
	_play_tone(520.0, 0.1, 0.2, "down")

func play_hit() -> void:
	_play_tone(180.0, 0.08, 0.3, "down")

func play_enemy_die() -> void:
	_play_tone(320.0, 0.09, 0.18, "up")

func play_ui() -> void:
	_play_tone(660.0, 0.04, 0.12, "none")

func play_win() -> void:
	_play_tone(523.25, 0.12, 0.2, "none")
	_play_tone(659.25, 0.12, 0.2, "none")
	_play_tone(783.99, 0.18, 0.25, "none")

func play_lose() -> void:
	_play_tone(220.0, 0.2, 0.28, "down")

func play_wave() -> void:
	_play_tone(440.0, 0.06, 0.15, "up")

func _play_tone(freq: float, duration: float, volume: float, slide: String) -> void:
	var player := _acquire()
	if player == null:
		return
	var sample_rate := 22050.0
	var frames := int(duration * sample_rate)
	var data := PackedVector2Array()
	data.resize(frames)
	for i in frames:
		var t := float(i) / sample_rate
		var env := 1.0 - (float(i) / float(frames))
		env = env * env
		var f := freq
		match slide:
			"down":
				f = lerpf(freq, freq * 0.45, float(i) / float(frames))
			"up":
				f = lerpf(freq, freq * 1.6, float(i) / float(frames))
		var s := sin(TAU * f * t) * volume * env
		data[i] = Vector2(s, s)
	var stream := AudioStreamWAV.new()
	stream.mix_rate = int(sample_rate)
	stream.stereo = true
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.data = _pcm16(data)
	player.stream = stream
	player.play()

func _play_noise_burst(duration: float, volume: float, bright: float) -> void:
	var player := _acquire()
	if player == null:
		return
	var sample_rate := 22050.0
	var frames := int(duration * sample_rate)
	var data := PackedVector2Array()
	data.resize(frames)
	var lp := 0.0
	for i in frames:
		var env := 1.0 - (float(i) / float(frames))
		env *= env
		var n := _rng.randf_range(-1.0, 1.0)
		# crude brightness via leaky integrator mix
		lp = lerpf(lp, n, clampf(bright / 8000.0, 0.05, 0.9))
		var s := lp * volume * env
		data[i] = Vector2(s, s)
	var stream := AudioStreamWAV.new()
	stream.mix_rate = int(sample_rate)
	stream.stereo = true
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.data = _pcm16(data)
	player.stream = stream
	player.play()

func _pcm16(samples: PackedVector2Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 4)
	var i := 0
	for s in samples:
		var l := int(clampf(s.x, -1.0, 1.0) * 32767.0)
		var r := int(clampf(s.y, -1.0, 1.0) * 32767.0)
		bytes[i] = l & 0xFF
		bytes[i + 1] = (l >> 8) & 0xFF
		bytes[i + 2] = r & 0xFF
		bytes[i + 3] = (r >> 8) & 0xFF
		i += 4
	return bytes

func _acquire() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	return _players[0]
