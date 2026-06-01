extends CanvasLayer
@onready var sender = $"../../Player/player"
@onready var cursor = $Cursor

func _ready() -> void:
	sender.looking.connect(self.change_cursor)
	sender.hud_visible.connect(self.hide_hud)

func change_cursor(object_name):
	if object_name != null:
		cursor.modulate = Color(0.122, 0.407, 0.374, 1.0)
	else:
		cursor.modulate = Color(1.0, 1.0, 1.0)
func hide_hud(show_hud: bool):
	cursor.visible = show_hud
	
