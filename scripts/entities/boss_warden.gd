extends EnemyBase
## Mirror Warden — teleports, mirror beams, summons decoy echoes that explode.

const PROJECTILE_SCENE := preload("res://scenes/entities/enemy_projectile.tscn")
const CHASER_SCENE := preload("res://scenes/entities/enemy_chaser.tscn")

enum Phase { INTRO, CIRCLE, BEAM, SUMMON, ENRAGE }

var _phase: Phase = Phase.INTRO
var _phase_time: float = 0.0
var _beam_cd: float = 0.0
var _intro_done: bool = false

func _ready() -> void:
	max_hp = 22
	move_speed = 70.0
	score_value = 2500
	super._ready()
	_visual.color = Color(0.75, 0.9, 1.0)
	scale = Vector2(1.6, 1.6)
	add_to_group("boss")
	EventBus.boss_spawned.emit()
	_phase = Phase.INTRO
	_phase_time = 1.2
	# Soft entrance pulse
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.45)

func _ai(delta: float) -> void:
	_phase_time -= delta
	_beam_cd = maxf(_beam_cd - delta, 0.0)
	match _phase:
		Phase.INTRO:
			velocity = Vector2.ZERO
			if _phase_time <= 0.0:
				_set_phase(Phase.CIRCLE)
		Phase.CIRCLE:
			_orbit(delta)
			if _phase_time <= 0.0:
				_set_phase(Phase.BEAM)
		Phase.BEAM:
			velocity = Vector2.ZERO
			if _beam_cd <= 0.0:
				_fire_ring()
				_beam_cd = 0.55
			if _phase_time <= 0.0:
				_set_phase(Phase.SUMMON)
		Phase.SUMMON:
			velocity = Vector2.ZERO
			if _phase_time < 1.4 and not _intro_done:
				_intro_done = true
				_summon_adds()
			if _phase_time <= 0.0:
				_intro_done = false
				_set_phase(Phase.CIRCLE if hp > max_hp * 0.35 else Phase.ENRAGE)
		Phase.ENRAGE:
			_orbit(delta, 1.45)
			if _beam_cd <= 0.0:
				_fire_ring()
				_beam_cd = 0.4
			if _phase_time <= 0.0:
				_set_phase(Phase.BEAM)

func _set_phase(p: Phase) -> void:
	_phase = p
	match p:
		Phase.CIRCLE:
			_phase_time = 3.5
		Phase.BEAM:
			_phase_time = 2.2
			_beam_cd = 0.15
			_teleport_near_player()
		Phase.SUMMON:
			_phase_time = 1.6
		Phase.ENRAGE:
			_phase_time = 4.0
			_visual.color = Color(1.0, 0.55, 0.75)
		_:
			_phase_time = 1.0

func _orbit(_delta: float, speed_mul: float = 1.0) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var center := Vector2(640, 360)
	var away := (global_position - center)
	if away.length_squared() < 4.0:
		away = Vector2.RIGHT * 120.0
	var tangent := away.normalized().rotated(PI * 0.5)
	var desired := global_position + tangent * 90.0 + (center - global_position) * 0.05
	steer_toward(desired, move_speed * speed_mul)

func _teleport_near_player() -> void:
	if _player == null:
		return
	var offset := Vector2.RIGHT.rotated(randf() * TAU) * randf_range(140.0, 220.0)
	global_position = _player.global_position + offset
	_keep_in_bounds()
	EventBus.camera_shake_requested.emit(5.0, 0.12)

func _fire_ring() -> void:
	var count := 8 if _phase != Phase.ENRAGE else 12
	for i in count:
		var bolt := PROJECTILE_SCENE.instantiate() as Node2D
		bolt.global_position = global_position
		var dir := Vector2.from_angle(TAU * float(i) / float(count))
		get_parent().add_child(bolt)
		if bolt.has_method("launch"):
			bolt.launch(dir * (200.0 if _phase != Phase.ENRAGE else 250.0))

func _summon_adds() -> void:
	for i in 2:
		var add := CHASER_SCENE.instantiate() as Node2D
		add.global_position = global_position + Vector2.RIGHT.rotated(TAU * 0.5 * i) * 60.0
		get_parent().add_child(add)

func take_damage(amount: int = 1) -> void:
	super.take_damage(amount)
	if hp <= int(max_hp * 0.35) and _phase != Phase.ENRAGE and _phase != Phase.INTRO:
		_set_phase(Phase.ENRAGE)
