extends CanvasLayer

const NORMAL_DURATION = 0.5  # Velocidad normal (0.5s = 1 min)
const FAST_DURATION = 0.02   # Velocidad ultra rápida para el "skip"

var time_tick : Timer
var minute = 0
var hour = 8
var day = 1

var is_skipping : bool = false

@onready var label = $TimeLabel 
@onready var skipbutton = $SkipButton

enum WEEKDAY { MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY }
var current_WEEKDAY: WEEKDAY = WEEKDAY.MONDAY

signal minute_changed(current_minute: int, current_hour: int)
signal hour_changed(current_hour: int)
signal day_changed(current_day: int, day_of_week: WEEKDAY)

func _ready() -> void:
	_setup_timer()
	_setup_button_signals() 
	write_label() 

func _setup_timer() -> void:
	time_tick = Timer.new()
	time_tick.wait_time = NORMAL_DURATION
	time_tick.autostart = true
	time_tick.timeout.connect(_on_timeout)
	add_child(time_tick)

func _setup_button_signals() -> void:
	skipbutton.button_down.connect(_on_skip_button_down)
	skipbutton.button_up.connect(_on_skip_button_up)

func _on_timeout() -> void:
	minute += 1
	
	if minute >= 60:
		minute = 0
		hour += 1
		hour_changed.emit(hour)
		
		if hour >= 24:
			hour = 0
			_advance_day()
			
	minute_changed.emit(minute, hour)
	write_label() # Actualiza el texto en pantalla

func _advance_day() -> void:
	day += 1
	var next_day_index = (current_WEEKDAY + 1) % 7
	current_WEEKDAY = next_day_index as WEEKDAY
	
	day_changed.emit(day, current_WEEKDAY)

# --- FUNCIONES DE SKIP TIME ---

func _on_skip_button_down() -> void:
	if not is_skipping: 
		is_skipping = true
		# Le cambiamos la velocidad AL MISMO timer y lo reiniciamos de forma segura
		time_tick.wait_time = FAST_DURATION

func _on_skip_button_up() -> void:
	if is_skipping: 
		is_skipping = false
		# Le devolvemos la velocidad normal AL MISMO timer y lo reiniciamos de forma segura
		time_tick.wait_time = NORMAL_DURATION

func get_time_string() -> String:
	return "%02d:%02d - Day %d (%s)" % [hour, minute, day, WEEKDAY.keys()[current_WEEKDAY]]

func write_label():
	label.text = get_time_string()
