extends Node

## Medidor de estilo tipo arcade: los golpes y kills suben combo y rango;
## si dejás de atacar, el estilo decae. El techo es ULTRAKILL.

signal style_changed(rank: String, rank_index: int, progress: float, combo: int)
signal rank_up(rank: String, rank_index: int)

const RANKS: Array[String] = ["D", "C", "B", "A", "S", "SS", "SSS", "ULTRAKILL"]
const THRESHOLDS: Array[float] = [0.0, 6.0, 14.0, 26.0, 42.0, 64.0, 92.0, 130.0]
const DECAY_RATE: float = 3.5
const COMBO_TIMEOUT: float = 2.6
const MAX_POINTS: float = 160.0

var style_points: float = 0.0
var combo: int = 0
var rank_index: int = 0
var _decay_timer: float = 0.0
var _last_emit_bucket: int = -999


func _ready() -> void:
	EventBus.enemy_hit.connect(_on_enemy_hit)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	GameState.run_started.connect(reset_style)


func reset_style() -> void:
	style_points = 0.0
	combo = 0
	rank_index = 0
	_decay_timer = 0.0
	_last_emit_bucket = -999
	style_changed.emit(RANKS[0], 0, 0.0, 0)


func _process(delta: float) -> void:
	if style_points <= 0.0 and combo <= 0:
		return

	_decay_timer = maxf(_decay_timer - delta, 0.0)
	if _decay_timer <= 0.0:
		combo = 0
		style_points = maxf(style_points - DECAY_RATE * delta, 0.0)

	_recalculate_rank()
	_emit_if_needed(false)


func _on_enemy_hit(_enemy: Node, hit_zone: String, damage: float, _money_value: int) -> void:
	var points: float = damage * 0.1
	if hit_zone == "head":
		points += 2.5
	_add_points(points)
	combo += 1
	_decay_timer = COMBO_TIMEOUT
	_emit_if_needed(true)


func _on_enemy_killed(_enemy: Node, _hit_zone: String) -> void:
	_add_points(4.0)
	combo += 1
	_decay_timer = COMBO_TIMEOUT
	_emit_if_needed(true)


func _add_points(points: float) -> void:
	style_points = clampf(style_points + points, 0.0, MAX_POINTS)
	_recalculate_rank()


func _recalculate_rank() -> void:
	var new_rank: int = 0
	for index in range(THRESHOLDS.size()):
		if style_points >= THRESHOLDS[index]:
			new_rank = index

	if new_rank > rank_index:
		rank_index = new_rank
		rank_up.emit(RANKS[rank_index], rank_index)
	elif new_rank < rank_index:
		rank_index = new_rank


func rank_progress() -> float:
	if rank_index >= RANKS.size() - 1:
		return 1.0
	var current: float = THRESHOLDS[rank_index]
	var next: float = THRESHOLDS[rank_index + 1]
	return clampf((style_points - current) / maxf(next - current, 0.01), 0.0, 1.0)


func _emit_if_needed(force: bool) -> void:
	var bucket: int = int(style_points * 2.0)
	if force or bucket != _last_emit_bucket:
		_last_emit_bucket = bucket
		style_changed.emit(RANKS[rank_index], rank_index, rank_progress(), combo)
