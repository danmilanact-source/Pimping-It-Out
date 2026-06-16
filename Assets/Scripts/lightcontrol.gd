extends DirectionalLight3D

# Definimos las constantes de energía
const MAX_ENERGY = 12.0  # El brillo máximo a mediodía (puedes subirlo a 1.5 o 2.0 si quieres)
const MIN_ENERGY = 0.2 # Oscuridad total de noche

func _ready() -> void:
	# 1. Nos conectamos a la señal del Autoload de tiempo
	GlobalTime.minute_changed.connect(_on_time_changed)
	
	# 2. Forzamos una actualización inicial al empezar el juego
	_actualizar_energia_luz(GlobalTime.hour, GlobalTime.minute)

func _on_time_changed(actual_minute: int, actual_hour: int) -> void:
	# Cada vez que avanza un minuto en el juego, recalculamos la luz de forma suave
	_actualizar_energia_luz(actual_hour, actual_minute)

func _actualizar_energia_luz(hora: int, minuto: int) -> void:
	# Convertimos la hora y minutos actuales a un valor decimal (ej: 14:30 -> 14.5)
	var hora_decimal : float = hora + (minuto / 60.0)
	var energia_objetivo : float = MIN_ENERGY
	
	# --- LÓGICA DEL CICLO DÍA/NOCHE ---
	if hora_decimal >= 6.0 and hora_decimal < 12.0:
		# AMANECER (6:00 a 12:00): La luz sube desde MIN hasta MAX
		var factor = (hora_decimal - 6.0) / 6.0
		energia_objetivo = lerp(MIN_ENERGY, MAX_ENERGY, factor)
		
	elif hora_decimal >= 12.0 and hora_decimal < 18.0:
		# ATARDECER (12:00 a 18:00): La luz baja desde MAX hasta MIN
		var factor = (hora_decimal - 12.0) / 6.0
		energia_objetivo = lerp(MAX_ENERGY, MIN_ENERGY, factor)
		
	else:
		# NOCHE (18:00 a 6:00): Luz al mínimo
		energia_objetivo = MIN_ENERGY

	# 3. Usamos un Tween ultra rápido (de la duración de un tick) para suavizar la transición visual
	var tiempo_transicion = GlobalTime.time_tick.wait_time
	var tween = create_tween()
	
	# IMPORTANTE: "light_energy" es la propiedad real de Godot para la intensidad de la luz
	tween.tween_property(self, "light_energy", energia_objetivo, tiempo_transicion)
