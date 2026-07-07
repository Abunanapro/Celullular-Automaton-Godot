extends Node2D

@onready var Bslider: HSlider = $"../../setingsmenu/Control/MarginContainer/MarginContainer/VBoxContainer/Brush Size/BrushSizeSlider"
@onready var tilemap: TileMapLayer = $"../../Game2/TileMapLayer"

func _process(delta: float) -> void:
	queue_redraw()

func _draw():
	#calculation of pos with zoom in mind 
	var screen_pos = get_viewport().get_canvas_transform() * tilemap.to_global(tilemap.map_to_local(tilemap.local_to_map(tilemap.to_local(get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()))))
	var visual_size = Bslider.value * 16 * tilemap.scale.x
	#drawing square centred on mouse
	draw_rect(Rect2(screen_pos.x - visual_size / 2.0,screen_pos.y - visual_size / 2.0,visual_size,visual_size),Color.WHITE,false,2.0)
	#central white point
	draw_circle(screen_pos, 2, Color.WHITE)
