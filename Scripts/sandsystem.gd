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
var delete=false
var lastmaterialbrush=ID_SAND

#Stat Vars
var SandUpdates = 0
var WaterUpdates = 0
var SteamUpdates = 0
# Called when the node enters the scene tree for the first time.
#Important paths
@onready var tilemap = $TileMapLayer
@onready var timer = $Timer
#Interface Path Vars
#labels
#game stat labels
@onready var fpslabel =$"../CanvasLayer/UI/MarginContainer3/HBoxContainer/fpss"
@onready var updateslabel =$"../CanvasLayer/UI/MarginContainer3/HBoxContainer/updates"
#material update labels
@onready var SandCountLabel=$"../CanvasLayer/UI/MarginContainer/VBoxContainer/SandCount"
@onready var WaterCountLabel=$"../CanvasLayer/UI/MarginContainer/VBoxContainer/WaterCount"
@onready var SteamCountLabel=$"../CanvasLayer/UI/MarginContainer/VBoxContainer/SteamCount"
#buttons
#buttons-material
@onready var sandbutton=$"../CanvasLayer/UI/MarginContainer2/HBoxContainer/sand"
@onready var waterbutton=$"../CanvasLayer/UI/MarginContainer2/HBoxContainer/water"
@onready var dirtbutton=$"../CanvasLayer/UI/MarginContainer2/HBoxContainer/dirt"
@onready var steambutton=$"../CanvasLayer/UI/MarginContainer2/HBoxContainer/steam"
#buttons-system
@onready var clearbutton=$"../CanvasLayer/UI/MarginContainer3/HBoxContainer/time"
#line edits
@onready var brushlineedit=$"../CanvasLayer/UI/MarginContainer3/HBoxContainer/brush"
@onready var canvaslineedit=$"../CanvasLayer/UI/MarginContainer3/HBoxContainer/canvas"
@onready var timelineedit=$"../CanvasLayer/UI/MarginContainer3/HBoxContainer/time"

@onready var updates=0
func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout) #this makes shure the signal is conneted ti timer
	timer.start()   #starts timer just in case it is not starting for some weird reason...
	
var last_canvas_text = ""
var last_time_text=""
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	fpslabel.text=("FPS: "+str(Engine.get_frames_per_second()))
	SandCountLabel.text=("Sand: "+str(SandUpdates))
	WaterCountLabel.text=("Water: "+str(WaterUpdates))
	SteamCountLabel.text=("Steam: "+str(SteamUpdates))
	if canvaslineedit.text != last_canvas_text:
		last_canvas_text = canvaslineedit.text
		var scale_val = float(canvaslineedit.text) / 10.0
		tilemap.scale = Vector2(scale_val, scale_val)
	if timelineedit.text!=last_time_text:
		last_time_text=timelineedit.text
		timer.wait_time=0.1/float(timelineedit.text)
		timer.start()
	if $"../CanvasLayer/UI/MarginContainer3/HBoxContainer/clear".button_pressed==true:
		tilemap.clear()
	if holding:
		var mouse_pos = get_viewport().get_mouse_position()
		var tilexy = tilemap.local_to_map(tilemap.to_local(mouse_pos))
		var offset = floor(brush_size / 2.0)
		tilemap.set_cell(tilexy, brush, Vector2i(0, 0))
		
		for n in brush_size:
			for i in brush_size:
				var pos = tilexy + Vector2i(n - offset, i - offset)
				tilemap.set_cell(pos, brush, Vector2i(0, 0))
				
		
func updatebrush():
	brush_size=int(brushlineedit.text)
	if waterbutton.button_pressed==true:
		brush=ID_WATER
		lastmaterialbrush=ID_WATER
	elif dirtbutton.button_pressed==true:
		brush=ID_DIRT
		lastmaterialbrush=ID_DIRT
	elif sandbutton.button_pressed==true:
		brush=ID_SAND
		lastmaterialbrush=ID_SAND
	elif  steambutton.button_pressed==true:
		brush=ID_STEAM
		lastmaterialbrush=ID_STEAM
	if delete==true:
		brush=-1

	
func _input(event:InputEvent) -> void:
	if get_viewport().gui_get_hovered_control() != null:
		updatebrush()
		return
	

	if  event is InputEventMouseButton:
		var tilexy=tilemap.local_to_map(tilemap.to_local(event.position))
		if event.button_index == MOUSE_BUTTON_LEFT:
			holding = event.pressed
			
			delete=false
			brush=lastmaterialbrush
			
			updatebrush()
			tilemap.set_cell(tilexy,brush,Vector2i(0,0))
			
		if event.button_index == MOUSE_BUTTON_RIGHT:
			holding = event.pressed
			tilemap.set_cell(tilexy,brush,Vector2i(-1,-1))
			
			delete=true
			updatebrush()
			
		
func _on_timer_timeout() -> void:
	
	updateslabel.text=("Active pixels: "+str(updates))
	updates=0
	var ProccesedCells = {}
	var cells:Array
	#automatically calculates active pixel ammount
	for x in range(ActiveMaterialList.size()):
		cells =cells + tilemap.get_used_cells_by_id(ActiveMaterialList[x])
	#cells = tilemap.get_used_cells_by_id(1)+tilemap.get_used_cells_by_id(2)+tilemap.get_used_cells_by_id(4)
	
	
	SandUpdates=0
	WaterUpdates=0
	SteamUpdates=0
	for cell in cells:
		var cellIndex = tilemap.get_cell_source_id(cell)
		updates=updates+1
		var up = cell + Vector2i(0, -1)
		var down = cell + Vector2i(0, 1)
		var right_bottom = cell + Vector2i(1, 1)
		var left_bottom = cell + Vector2i(-1, 1)
		var left = cell + Vector2i(-1, 0)   
		var right = cell + Vector2i(1, 0) 
		
		if not ProccesedCells.has(cell):
			match cellIndex:
				ID_SAND:
					#Update counter
					SandUpdates=SandUpdates+1
					#Sand Information
					var ID=ID_SAND
					var density=DensityList[ID_SAND-1]
					
					if tilemap.get_cell_source_id(down)==-1 and not ProccesedCells.has(down) and not ProccesedCells.has(cell):
						tilemap.set_cell(cell,-1)
						tilemap.set_cell(down, ID,Vector2i(0, 0))
						ProccesedCells[cell] = true
						ProccesedCells[down] = true
					else:
						if DensityList[tilemap.get_cell_source_id(down)-1]!=null:
							if DensityList[tilemap.get_cell_source_id(down)-1]<density and not ProccesedCells.has(down) and not ProccesedCells.has(cell):
								tilemap.set_cell(cell,tilemap.get_cell_source_id(down),Vector2i(0, 0))
								tilemap.set_cell(down, ID,Vector2i(0, 0))
								ProccesedCells[cell] = true
								ProccesedCells[down] = true
								
						if randi_range(0,1) ==1:
							if tilemap.get_cell_source_id(left_bottom)==-1 and tilemap.get_cell_source_id(left)==-1 and not ProccesedCells.has(left_bottom) and not ProccesedCells.has(cell):
								tilemap.set_cell(cell,-1)
								tilemap.set_cell(left_bottom, ID,Vector2i(0, 0))
								ProccesedCells[cell] = true
								ProccesedCells[left_bottom] = true
							elif DensityList[tilemap.get_cell_source_id(left)-1]!=null and DensityList[tilemap.get_cell_source_id(left_bottom)-1]!=null:
								if DensityList[tilemap.get_cell_source_id(left_bottom)-1]<density and DensityList[tilemap.get_cell_source_id(left)-1]<density and not ProccesedCells.has(cell) and not ProccesedCells.has(left_bottom):
									tilemap.set_cell(cell,tilemap.get_cell_source_id(left_bottom),Vector2i(0, 0))
									tilemap.set_cell(left_bottom, ID,Vector2i(0, 0))
									ProccesedCells[cell] = true
									ProccesedCells[left_bottom] = true
						else:
							if tilemap.get_cell_source_id(right_bottom)==-1 and tilemap.get_cell_source_id(right)==-1 and not ProccesedCells.has(cell) and not ProccesedCells.has(right_bottom):
								tilemap.set_cell(cell,-1)
								tilemap.set_cell(right_bottom, ID,Vector2i(0, 0))
								ProccesedCells[cell] = true
								ProccesedCells[right_bottom] = true
							
							elif DensityList[tilemap.get_cell_source_id(right)-1]!=null and DensityList[tilemap.get_cell_source_id(right_bottom)-1]!=null:
								if DensityList[tilemap.get_cell_source_id(right_bottom)-1]<density and DensityList[tilemap.get_cell_source_id(right)-1]<density and not ProccesedCells.has(cell) and not ProccesedCells.has(right_bottom):
									tilemap.set_cell(cell,tilemap.get_cell_source_id(right_bottom),Vector2i(0, 0))
									tilemap.set_cell(right_bottom, ID,Vector2i(0, 0))
									ProccesedCells[cell] = true
									ProccesedCells[right_bottom] = true
				ID_WATER:
					var ID=ID_WATER
					WaterUpdates=WaterUpdates+1
					var density=DensityList[ID_WATER-1]
				
					if tilemap.get_cell_source_id(down)==-1 and not ProccesedCells.has(cell) and not ProccesedCells.has(down):
						tilemap.set_cell(cell,-1)
						tilemap.set_cell(down, ID,Vector2i(0, 0))
						ProccesedCells[cell] = true
						ProccesedCells[down] = true
					else:
						if DensityList[tilemap.get_cell_source_id(down)-1]!=null:
							if DensityList[tilemap.get_cell_source_id(down)-1]<density and not ProccesedCells.has(cell) and not ProccesedCells.has(down):
								tilemap.set_cell(cell,tilemap.get_cell_source_id(down),Vector2i(0, 0))
								tilemap.set_cell(down, ID,Vector2i(0, 0))
								ProccesedCells[cell] = true
								ProccesedCells[down] = true
						if randi_range(1,0) ==1:
							if tilemap.get_cell_source_id(left)==-1 and not ProccesedCells.has(cell) and not ProccesedCells.has(left):
								tilemap.set_cell(cell,-1)
								tilemap.set_cell(left, ID,Vector2i(0, 0))
								ProccesedCells[cell] = true
								ProccesedCells[left] = true
							elif DensityList[tilemap.get_cell_source_id(left)-1]!=null:
								if DensityList[tilemap.get_cell_source_id(left)-1]<density  and not ProccesedCells.has(cell) and not ProccesedCells.has(left):
									tilemap.set_cell(cell,tilemap.get_cell_source_id(left),Vector2i(0, 0))
									tilemap.set_cell(left, ID,Vector2i(0, 0))
									ProccesedCells[cell] = true
									ProccesedCells[left] = true
						else:
							if tilemap.get_cell_source_id(right)==-1 and not ProccesedCells.has(cell) and not ProccesedCells.has(right):
								tilemap.set_cell(cell,-1)
								tilemap.set_cell(right, ID,Vector2i(0, 0))
								ProccesedCells[cell] = true
								ProccesedCells[right] = true
							elif DensityList[tilemap.get_cell_source_id(right)-1]!=null:
								if DensityList[tilemap.get_cell_source_id(right)-1]<density  and not ProccesedCells.has(cell) and not ProccesedCells.has(right):
									tilemap.set_cell(cell,tilemap.get_cell_source_id(right),Vector2i(0, 0))
									tilemap.set_cell(right, ID,Vector2i(0, 0))
									ProccesedCells[cell] = true
									ProccesedCells[right] = true
				ID_STEAM:
					var density=DensityList[ID_STEAM-1]
					var ID=ID_STEAM
					SteamUpdates=SteamUpdates+1
					if tilemap.get_cell_source_id(up)==-1 and not ProccesedCells.has(cell) and not ProccesedCells.has(up):
						tilemap.set_cell(cell,-1)
						tilemap.set_cell(up, ID,Vector2i(0, 0))
						ProccesedCells[cell] = true
						ProccesedCells[up] = true
					else:
						if DensityList[tilemap.get_cell_source_id(up)-1]!=null:
							if DensityList[tilemap.get_cell_source_id(up)-1]<density and not ProccesedCells.has(cell) and not ProccesedCells.has(up):
								tilemap.set_cell(cell,tilemap.get_cell_source_id(up),Vector2i(0, 0))
								tilemap.set_cell(up, ID,Vector2i(0, 0))
								ProccesedCells[cell] = true
								ProccesedCells[up] = true
						if randi_range(1,0) ==1:
							if tilemap.get_cell_source_id(left)==-1 and not ProccesedCells.has(cell) and not ProccesedCells.has(left):
								tilemap.set_cell(cell,-1)
								tilemap.set_cell(left, ID,Vector2i(0, 0))
								ProccesedCells[cell] = true
								ProccesedCells[left] = true
							elif DensityList[tilemap.get_cell_source_id(left)-1]!=null:
								if DensityList[tilemap.get_cell_source_id(left)-1]<density  and not ProccesedCells.has(cell) and not ProccesedCells.has(right):
									tilemap.set_cell(cell,tilemap.get_cell_source_id(left),Vector2i(0, 0))
									tilemap.set_cell(left, ID,Vector2i(0, 0))
									ProccesedCells[cell] = true
									ProccesedCells[left] = true
						else:
							if tilemap.get_cell_source_id(right)==-1 and not ProccesedCells.has(cell) and not ProccesedCells.has(right):
								tilemap.set_cell(cell,-1)
								tilemap.set_cell(right, ID,Vector2i(0, 0))
								ProccesedCells[cell] = true
								ProccesedCells[right] = true
							elif DensityList[tilemap.get_cell_source_id(right)-1]!=null:
								if DensityList[tilemap.get_cell_source_id(right)-1]<density  and not ProccesedCells.has(cell) and not ProccesedCells.has(right):
									tilemap.set_cell(cell,tilemap.get_cell_source_id(right),Vector2i(0, 0))
									tilemap.set_cell(right, ID,Vector2i(0, 0))
									ProccesedCells[cell] = true
									ProccesedCells[right] = true
		
		
