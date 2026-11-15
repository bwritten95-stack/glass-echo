class_name GlassEcho
extends CharacterBody2D

signal shattered

const LIFETIME := 12.0

@onready var _visual: Polygon2D = $Visual
@onready var _rim: Polygon2D = $Rim

var _hp: int = 1
var _age: float = 0.0
var _shattering: bool = false
var _shard_scene: PackedScene = preload("res://scenes/entities/shard_burst.tscn")

func _ready() -> void:
	add_to_group("echo")
	_visual.color = Color(0.65, 0.9, 1.0, 0.55)
	_rim.color = Color(0.85, 0.97, 1.0, 0.95)
	scale = Vector2(0.2, 0.2)
	var ring := Polygon2D.new()
	var pts := PackedVector2Array()
	for a in 24:
		pts.append(Vector2.from_angle(TAU * float(a) / 24.0) * 22.0)
	ring.polygon = pts
	ring.color = Color(0.6, 0.9, 1.0, 0.2)
	ring.z_index = -1
	add_child(ring)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(ring, "scale", Vector2(1.4, 1.4), 0.35)
	tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.35)

func _physics_process(delta: float) -> void:
	if _shattering:
		return
	_age += delta
	var flicker := 0.4 + 0.15 * sin(_age * 6.0 + global_position.x * 0.01)
	_visual.color.a = flicker
	if _age >= LIFETIME:
		shatter(false)

func take_damage(_amount: int = 1) -> void:
	if _shattering:
		return
	_hp -= 1
	if _hp <= 0:
		shatter(true)

func shatter(from_damage: bool) -> void:
	if _shattering:
		return
	_shattering = true
	var burst: Node2D = _shard_scene.instantiate() as Node2D
	burst.global_position = global_position
	get_parent().add_child(burst)
	if burst.has_method("setup"):
		burst.call("setup", from_damage)
	EventBus.echo_shattered.emit(global_position, 10 if from_damage else 6)
	AudioService.play_shatter()
	EventBus.camera_shake_requested.emit(6.0 if from_damage else 3.0, 0.1)
	EventBus.hitstop_requested.emit(0.035)
	shattered.emit()
	queue_free()
