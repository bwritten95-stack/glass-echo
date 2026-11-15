extends Area2D

var _velocity: Vector2 = Vector2.ZERO
var _life: float = 3.5

func _ready() -> void:
	add_to_group("enemy_projectile")
	body_entered.connect(_on_body_entered)

func launch(vel: Vector2) -> void:
	_velocity = vel
	rotation = vel.angle()

func _physics_process(delta: float) -> void:
	position += _velocity * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1)
		queue_free()
	elif body.is_in_group("echo") and body.has_method("take_damage"):
		body.take_damage(1)
		queue_free()
