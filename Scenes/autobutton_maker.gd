extends HBoxContainer




@onready var sandsystem: Node = $"../../../../Game2"

var group := ButtonGroup.new()


func _ready() -> void:
	for id in sandsystem.MaterialColors.keys():
		if id == -1: # skip air
			continue
		_create_button(id)

func _create_button(id: int) -> void:
	var btn := Button.new()
	btn.toggle_mode = true
	btn.button_group = group
	btn.text = sandsystem.MaterialNames[id]
	btn.custom_minimum_size = Vector2(70, 32)

	var color: Color = sandsystem.MaterialColors[id]
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 1.0)
	style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", style)

	var style_pressed := style.duplicate()
	style_pressed.border_width_left = 3
	style_pressed.border_width_right = 3
	style_pressed.border_width_top = 3
	style_pressed.border_width_bottom = 3
	style_pressed.border_color = Color.WHITE
	btn.add_theme_stylebox_override("pressed", style_pressed)

	btn.add_theme_color_override("font_color", Color.BLACK if color.get_luminance() > 0.5 else Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.BLACK if color.get_luminance() > 0.5 else Color.WHITE)

	btn.pressed.connect(_on_material_pressed.bind(id))
	add_child(btn)

	if id == sandsystem.brush:
		btn.button_pressed = true

func _on_material_pressed(id: int) -> void:
	sandsystem.brush = id
	sandsystem.lastmaterialbrush = id
	sandsystem.brushtemp = sandsystem.MaterialTemps.get(id)
	
	sandsystem.delete = false
