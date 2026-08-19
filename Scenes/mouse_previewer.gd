extends Node2D
@onready var Bslider: HSlider = $"../../setingsmenu/Control/MarginContainer/MarginContainer/VBoxContainer/Brush Size/BrushSizeSlider"
@onready var main = $"../../Game2"  

func _process(delta: float) -> void:
	queue_redraw()

func _draw():
	var tilexy = main.mouse_to_cell()
	var offset = floor(Bslider.value / 2.0)
	var top_left_cell = tilexy - Vector2i(int(offset), int(offset))

	var top_left_local = Vector2(top_left_cell) * main.CELL_PIXEL_SIZE
	var top_left_global = main.world_container.to_global(top_left_local)
	var screen_pos = get_viewport().get_canvas_transform() * top_left_global

	var visual_size = Bslider.value * main.CELL_PIXEL_SIZE * main.world_container.scale.x

	draw_rect(Rect2(screen_pos, Vector2(visual_size, visual_size)), Color.WHITE, false, 2.0)
	draw_circle(screen_pos + Vector2(visual_size, visual_size) / 2.0, 2, Color.WHITE)
