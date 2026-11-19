extends Node
## Estado global de la run y la meta-progresión.
## Responsabilidad única: almacenar y exponer estado.
## No spawnea enemigos, no maneja zonas y no conoce escenas.

signal money_changed(new_amount: int)
signal timer_changed(remaining: float)
signal run_started
signal run_ended(reason: String)

const VALID_END_REASONS: PackedStringArray = ["timer", "death", "completed"]

# Tiempo base de la run, ampliable desde el hub.
@export var base_run_time: float = 60.0

# Plata persistente entre runs. El setter emite la señal al cambiar.
var money: int = 0:
	set(value):
		var clamped_value: int = maxi(value, 0)
		if clamped_value == money:
			return
		money = clamped_value
		money_changed.emit(money)

# True mientras la run está en curso. Evita emitir run_ended más de una vez.
var is_run_active: bool = false

# Tiempo restante de la run actual.
var run_timer: float = 0.0

# Mejoras compradas. Persisten entre runs.
var upgrades: Dictionary = {}


func add_run_time(seconds: float) -> void:
	base_run_time += seconds


func register_upgrade(upgrade_id: String, bonus: float) -> void:
	# Guarda nivel y bonus acumulado para aplicarlo en cada run.
	var level_key: String = upgrade_id + "_level"
	var bonus_key: String = upgrade_id + "_bonus"
	upgrades[level_key] = int(upgrades.get(level_key, 0)) + 1
	upgrades[bonus_key] = float(upgrades.get(bonus_key, 0.0)) + bonus


func get_upgrade_level(upgrade_id: String) -> int:
	return int(upgrades.get(upgrade_id + "_level", 0))


func add_money(amount: int) -> void:
	if amount <= 0:
		return
	money += amount


func spend_money(amount: int) -> bool:
	if amount < 0 or money < amount:
		return false
	money -= amount
	return true


func start_run() -> void:
	is_run_active = true
	run_timer = base_run_time
	timer_changed.emit(run_timer)
	run_started.emit()


func tick_run(delta: float) -> void:
	# Avanza el temporizador y notifica. No tickea si la run ya terminó.
	if not is_run_active or run_timer <= 0.0:
		return

	run_timer = maxf(run_timer - delta, 0.0)
	timer_changed.emit(run_timer)

	if run_timer <= 0.0:
		end_run("timer")


func end_run(reason: String) -> void:
	# Ignora llamadas repetidas (ej. muerte y timer en el mismo frame).
	if not is_run_active:
		return
	is_run_active = false

	# TODO: Fase 2.4 — aplicar consecuencias por motivo (ej. penalización por muerte).
	if not VALID_END_REASONS.has(reason):
		push_warning("GameState.end_run: motivo desconocido '%s'" % reason)
	run_ended.emit(reason)


func reset_run() -> void:
	# Solo reinicia el estado de la run. money y upgrades persisten.
	is_run_active = false
	run_timer = base_run_time
	timer_changed.emit(run_timer)
