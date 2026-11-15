extends Node
## Session stats for the current arena run.

var hp: int = 3
var max_hp: int = 3
var score: int = 0
var wave_index: int = 0
var echoes_alive: int = 0
var enemies_alive: int = 0
var run_active: bool = false
var outcome: String = "" # "won" | "lost" | ""

func reset() -> void:
	hp = max_hp
	score = 0
	wave_index = 0
	echoes_alive = 0
	enemies_alive = 0
	run_active = true
	outcome = ""

func add_score(points: int) -> void:
	score += max(points, 0)

func mark_won() -> void:
	run_active = false
	outcome = "won"

func mark_lost() -> void:
	run_active = false
	outcome = "lost"
