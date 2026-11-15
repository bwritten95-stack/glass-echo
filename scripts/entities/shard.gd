class_name Shard
extends Area2D

var _velocity: Vector2 = Vector2.ZERO
var _life: float = 0.35
var _hurt_enemies: bool = true

func _ready() -> void:
	add_to_group("shard")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func launch(vel: Vector2, hurt_enemies: bool) -> void:
	_velocity = vel
	_hurt_enemies = hurt_enemies
	rotation = vel.angle()

func _physics_process(delta: float) -> void:
	position += _velocity * delta
	_velocity = _velocity.lerp(Vector2.ZERO, 3.0 * delta)
	_life -= delta
	modulate.a = clampf(_life / 0.35, 0.0, 1.0)
	if _life <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if _hurt_enemies and body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(1)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_projectile"):
		area.queue_free()
