extends Node
var brush=4 #id of the material selected
var brush_size=1
const ID_SAND  = 1
const ID_WATER =2
const ID_DIRT  = 3
const ID_STEAM =4
const DensityList=[1.5,1,null,0.5]
const ActiveMaterialList=[1,2,4] #Place here material IDS that you want to "tick"
var holding= false

#Stat Vars
var SandUpdates = 0
var WaterUpdates = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var last_canvas_text = ""
var last_time_text=""
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$fpss.text=("FPS: "+str(Engine.get_frames_per_second()))
	$SandCount.text=("Sand: "+str(SandUpdates))
	$WaterCount.text=("Water: "+str(WaterUpdates))
	if $canvas.text != last_canvas_text:
		last_canvas_text = $canvas.text
		var scale_val = float($canvas.text) / 10.0
		$TileMapLayer.scale = Vector2(scale_val, scale_val)
	if $time.text!=last_time_text:
		last_time_text=$time.text
		$Timer.wait_time=0.1/float($time.text)
		$Timer.start()
	if $clear.button_pressed==true:
		$TileMapLayer.clear()
	if holding:
		var mouse_pos = get_viewport().get_mouse_position()
		var tilexy = $TileMapLayer.local_to_map($TileMapLayer.to_local(mouse_pos))
		$TileMapLayer.set_cell(tilexy, brush, Vector2i(0, 0))
		for n in brush_size:
			for i in brush_size:
				$TileMapLayer.set_cell(tilexy+Vector2i(n,i), brush, Vector2i(0, 0))
		
func updatebrush():
	brush_size=int($LineEdit.text)
	if $water.button_pressed==true:
		brush=ID_WATER
	elif $dirt.button_pressed==true:
		brush=ID_DIRT
	elif $sand.button_pressed==true:
		brush=ID_SAND
	elif  $steam.button_pressed==true:
		brush=ID_STEAM

func _input(event:InputEvent) -> void:
	if get_viewport().gui_get_hovered_control() != null:
		updatebrush()
		return
	

	if  event is InputEventMouseButton:
		var tilexy=$TileMapLayer.local_to_map($TileMapLayer.to_local(event.position))
		if event.button_index == MOUSE_BUTTON_LEFT:
			holding = event.pressed
			updatebrush()
			$TileMapLayer.set_cell(tilexy,brush,Vector2i(0,0))
		if event.button_index == MOUSE_BUTTON_RIGHT:
			holding = event.pressed
			$TileMapLayer.set_cell(tilexy,brush,Vector2i(-1,-1))
		
		

func _on_timer_timeout() -> void:
	var ProccesedCells:Array
	var cells:Array
	#automatically calculates active pixel ammount
	for x in range(ActiveMaterialList.size()):
		cells =cells + $TileMapLayer.get_used_cells_by_id(ActiveMaterialList[x])
	#cells = $TileMapLayer.get_used_cells_by_id(1)+$TileMapLayer.get_used_cells_by_id(2)+$TileMapLayer.get_used_cells_by_id(4)
	var updates=0
	SandUpdates=0
	WaterUpdates=0
	for cell in cells:
		var cellIndex = $TileMapLayer.get_cell_source_id(cell)
		updates=updates+1
		var up = cell + Vector2i(0, -1)
		var down = cell + Vector2i(0, 1)
		var right_bottom = cell + Vector2i(1, 1)
		var left_bottom = cell + Vector2i(-1, 1)
		var left = cell + Vector2i(-1, 0)   
		var right = cell + Vector2i(1, 0) 
		match cellIndex:
			ID_SAND:
				#Update counter
				SandUpdates=SandUpdates+1
				#Sand Information
				var ID=ID_SAND
				var density=DensityList[ID_SAND-1]
				
				if $TileMapLayer.get_cell_source_id(down)==-1 and not(down in ProccesedCells) and not(cell in ProccesedCells):
					$TileMapLayer.set_cell(cell,-1)
					$TileMapLayer.set_cell(down, ID,Vector2i(0, 0))
					ProccesedCells.append(cell)
					ProccesedCells.append(down)
				else:
					if DensityList[$TileMapLayer.get_cell_source_id(down)-1]!=null:
						if DensityList[$TileMapLayer.get_cell_source_id(down)-1]<density and not(down in ProccesedCells) and not(cell in ProccesedCells):
							$TileMapLayer.set_cell(cell,$TileMapLayer.get_cell_source_id(down),Vector2i(0, 0))
							$TileMapLayer.set_cell(down, ID,Vector2i(0, 0))
							ProccesedCells.append(cell)
							ProccesedCells.append(down)
							
					if randi_range(1,0) ==1:
						if $TileMapLayer.get_cell_source_id(left_bottom)==-1 and $TileMapLayer.get_cell_source_id(left)==-1 and not(left_bottom in ProccesedCells) and not(cell in ProccesedCells):
							$TileMapLayer.set_cell(cell,-1)
							$TileMapLayer.set_cell(left_bottom, ID,Vector2i(0, 0))
							ProccesedCells.append(cell)
							ProccesedCells.append(left_bottom)
						elif DensityList[$TileMapLayer.get_cell_source_id(left)-1]!=null and DensityList[$TileMapLayer.get_cell_source_id(left_bottom)-1]!=null:
							if DensityList[$TileMapLayer.get_cell_source_id(left_bottom)-1]<density and DensityList[$TileMapLayer.get_cell_source_id(left)-1]<density and (not(cell in ProccesedCells) and not(left_bottom in ProccesedCells)):
								$TileMapLayer.set_cell(cell,$TileMapLayer.get_cell_source_id(left_bottom),Vector2i(0, 0))
								$TileMapLayer.set_cell(left_bottom, ID,Vector2i(0, 0))
								ProccesedCells.append(cell)
								ProccesedCells.append(left_bottom)
					else:
						if $TileMapLayer.get_cell_source_id(right_bottom)==-1 and $TileMapLayer.get_cell_source_id(right)==-1 and (not(cell in ProccesedCells) and not(right_bottom in ProccesedCells)):
							$TileMapLayer.set_cell(cell,-1)
							$TileMapLayer.set_cell(right_bottom, ID,Vector2i(0, 0))
							ProccesedCells.append(cell)
							ProccesedCells.append(right_bottom)
						
						elif DensityList[$TileMapLayer.get_cell_source_id(right)-1]!=null and DensityList[$TileMapLayer.get_cell_source_id(right_bottom)-1]!=null:
							if DensityList[$TileMapLayer.get_cell_source_id(right_bottom)-1]<density and DensityList[$TileMapLayer.get_cell_source_id(right)-1]<density and (not(cell in ProccesedCells) and not(right_bottom in ProccesedCells)):
								$TileMapLayer.set_cell(cell,$TileMapLayer.get_cell_source_id(right_bottom),Vector2i(0, 0))
								$TileMapLayer.set_cell(right_bottom, ID,Vector2i(0, 0))
								ProccesedCells.append(cell)
								ProccesedCells.append(right_bottom)
			ID_WATER:
				var ID=ID_WATER
				WaterUpdates=WaterUpdates+1
				var density=DensityList[ID_WATER-1]
			
				if $TileMapLayer.get_cell_source_id(down)==-1 and not(down in ProccesedCells) and not(cell in ProccesedCells):
					$TileMapLayer.set_cell(cell,-1)
					$TileMapLayer.set_cell(down, ID_WATER,Vector2i(0, 0))
					ProccesedCells.append(cell)
					ProccesedCells.append(down)
				else:
					if DensityList[$TileMapLayer.get_cell_source_id(down)-1]!=null:
						if DensityList[$TileMapLayer.get_cell_source_id(down)-1]<density and not(down in ProccesedCells) and not(cell in ProccesedCells):
							$TileMapLayer.set_cell(cell,$TileMapLayer.get_cell_source_id(down),Vector2i(0, 0))
							$TileMapLayer.set_cell(down, ID,Vector2i(0, 0))
							ProccesedCells.append(cell)
							ProccesedCells.append(down)
					if randi_range(1,0) ==1:
						if $TileMapLayer.get_cell_source_id(left)==-1 and (not(cell in ProccesedCells) or not(left in ProccesedCells)):
							$TileMapLayer.set_cell(cell,-1)
							$TileMapLayer.set_cell(left, ID,Vector2i(0, 0))
							ProccesedCells.append(cell)
							ProccesedCells.append(left)
						elif DensityList[$TileMapLayer.get_cell_source_id(left)-1]!=null:
							if DensityList[$TileMapLayer.get_cell_source_id(left)-1]<density  and (not(cell in ProccesedCells) or not(left in ProccesedCells)):
								$TileMapLayer.set_cell(cell,$TileMapLayer.get_cell_source_id(left),Vector2i(0, 0))
								$TileMapLayer.set_cell(left, ID,Vector2i(0, 0))
								ProccesedCells.append(cell)
								ProccesedCells.append(left)
					else:
						if $TileMapLayer.get_cell_source_id(right)==-1 and (not(cell in ProccesedCells) or not(right in ProccesedCells)):
							$TileMapLayer.set_cell(cell,-1)
							$TileMapLayer.set_cell(right, ID,Vector2i(0, 0))
							ProccesedCells.append(cell)
							ProccesedCells.append(right)
						elif DensityList[$TileMapLayer.get_cell_source_id(right)-1]!=null:
							if DensityList[$TileMapLayer.get_cell_source_id(right)-1]<density  and (not(cell in ProccesedCells) or not(right in ProccesedCells)):
								$TileMapLayer.set_cell(cell,$TileMapLayer.get_cell_source_id(right),Vector2i(0, 0))
								$TileMapLayer.set_cell(right, ID,Vector2i(0, 0))
								ProccesedCells.append(cell)
								ProccesedCells.append(right)
			ID_STEAM:
				var density=DensityList[ID_STEAM-1]
				
			
				if $TileMapLayer.get_cell_source_id(up)==-1:
					$TileMapLayer.set_cell(cell,-1)
					$TileMapLayer.set_cell(up, ID_STEAM,Vector2i(0, 0))
				else:
					if DensityList[$TileMapLayer.get_cell_source_id(up)-1]!=null:
						if DensityList[$TileMapLayer.get_cell_source_id(up)-1]<density:
							$TileMapLayer.set_cell(cell,$TileMapLayer.get_cell_source_id(up),Vector2i(0, 0))
							$TileMapLayer.set_cell(up, ID_STEAM,Vector2i(0, 0))
					if randi_range(1,0) ==1:
						if $TileMapLayer.get_cell_source_id(left)==-1:
							$TileMapLayer.set_cell(cell,-1)
							$TileMapLayer.set_cell(left, ID_STEAM,Vector2i(0, 0))
					else:
						if $TileMapLayer.get_cell_source_id(right)==-1:
							$TileMapLayer.set_cell(cell,-1)
							$TileMapLayer.set_cell(right, ID_STEAM,Vector2i(0, 0))
	$updates.text=("Active pixels: "+str(updates))
