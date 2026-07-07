extends Node
var brush=4 #id of the material selected
var brush_size=1
const ID_SAND  = 1
const ID_WATER =2
const ID_DIRT  = 3
const ID_STEAM =4
const DensityList=[1.5,1,99,0.5]
const CDispersionList=[2,5,0,5]
var DispersionList=[2,5,0,5]
const ActiveMaterialList=[1,2,4] #Place here material IDS that you want to "tick"
var holding= false
var holdingDelete=false
var delete=false
var lastmaterialbrush=ID_SAND
#Config Vars
var dispersioning=true #activates or desactivates the disperison property
#Volime Vars
var globalvolume = 1
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
#setings menu labels
@onready var VolumeLabel=$"../setingsmenu/Control/MarginContainer/MarginContainer/VBoxContainer/Volume/VolumeLabel"
@onready var CanvasScaleLabel=$"../setingsmenu/Control/MarginContainer/MarginContainer/VBoxContainer/Canvas Size/CanvasScaleLabel"
@onready var BrushSizeLabel=$"../setingsmenu/Control/MarginContainer/MarginContainer/VBoxContainer/Brush Size/Brushsizelabel"
#buttons
#buttons-material
@onready var sandbutton=$"../CanvasLayer/UI/MarginContainer2/HBoxContainer/sand"
@onready var waterbutton=$"../CanvasLayer/UI/MarginContainer2/HBoxContainer/water"
@onready var dirtbutton=$"../CanvasLayer/UI/MarginContainer2/HBoxContainer/dirt"
@onready var steambutton=$"../CanvasLayer/UI/MarginContainer2/HBoxContainer/steam"
#buttons-system
@onready var clearbutton=$"../CanvasLayer/UI/MarginContainer3/HBoxContainer/time"
@onready var settingsbutton=$"../CanvasLayer/UI/MarginContainer4/BoxContainer/TextureButton"
#Menu
@onready var settingsmenu=$"../setingsmenu"
var settings_was_pressed = false
#Settings Menu Sliders
@onready var volumeslider=$"../setingsmenu/Control/MarginContainer/MarginContainer/VBoxContainer/Volume/VolumeSlider"
@onready var canvasscaleslider=$"../setingsmenu/Control/MarginContainer/MarginContainer/VBoxContainer/Canvas Size/CanvasSizeSlider"
@onready var brushsizeslider=$"../setingsmenu/Control/MarginContainer/MarginContainer/VBoxContainer/Brush Size/BrushSizeSlider"
#settings menu check buttons
@onready var DispersionButton=$"../setingsmenu/Control/MarginContainer/MarginContainer/VBoxContainer/dispersion/CheckButton"
#line edits
@onready var brushlineedit=$"../CanvasLayer/UI/MarginContainer3/HBoxContainer/brush"
@onready var canvaslineedit=$"../CanvasLayer/UI/MarginContainer3/HBoxContainer/canvas"
@onready var timelineedit=$"../CanvasLayer/UI/MarginContainer3/HBoxContainer/time"

#camera movement
var panning = false
var pan_speed = 1500.0
#updates
@onready var updates=0
func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout) #this makes shure the signal is conneted ti timer
	timer.start()   #starts timer just in case it is not starting for some weird reason...
		# Fix label widths and prevent them from expanding/shrinking
	VolumeLabel.custom_minimum_size.x = 60
	VolumeLabel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	VolumeLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	CanvasScaleLabel.custom_minimum_size.x = 60
	CanvasScaleLabel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	CanvasScaleLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	# Make sliders take all leftover space so they stay locked
	volumeslider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvasscaleslider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	

var last_time_text=""

var scale_val=4.0/10.0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if holding and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or holdingDelete and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		holding = false
		holdingDelete=false
		
	
	fpslabel.text=("FPS: "+str(Engine.get_frames_per_second()))
	SandCountLabel.text=("Sand: "+str(SandUpdates))
	WaterCountLabel.text=("Water: "+str(WaterUpdates))
	SteamCountLabel.text=("Steam: "+str(SteamUpdates))
	BrushSizeLabel.text=str("brush size:"+str(brush_size))
	if timelineedit.text!=last_time_text:
		last_time_text=timelineedit.text
		timer.wait_time=0.1/float(timelineedit.text)
		timer.start()
	if $"../CanvasLayer/UI/MarginContainer3/HBoxContainer/clear".button_pressed==true:
		tilemap.clear()
	#Settings Menu Scripts
	if settingsbutton.button_pressed and not settings_was_pressed:
		settingsmenu.visible = !settingsmenu.visible
		settings_was_pressed = true
	elif not settingsbutton.button_pressed:
		settings_was_pressed = false
	#Settings Sliders
	globalvolume=volumeslider.value
	VolumeLabel.text="Volume "+str(volumeslider.value)
	var old_s = tilemap.scale.x
	var new_s = canvasscaleslider.value
	if new_s != old_s:
		var m = get_viewport().get_mouse_position()
		tilemap.position = m - (m - tilemap.position) * (new_s / old_s)
		tilemap.scale = Vector2(new_s, new_s)
	CanvasScaleLabel.text = "Scale: %.1fx" % new_s
#dispersion toggle
	if DispersionButton.button_pressed==true:
		DispersionList=CDispersionList
	else:
		DispersionList=[2,2,0,2]
	#Main
	if holding or holdingDelete:
		var mouse_pos = get_viewport().get_mouse_position()
		var tilexy = tilemap.local_to_map(tilemap.to_local(mouse_pos))
		var offset = floor(brush_size / 2.0)
		tilemap.set_cell(tilexy, brush, Vector2i(0, 0))
		
		for n in brush_size:
			for i in brush_size:
				var pos = tilexy + Vector2i(n - offset, i - offset)
				tilemap.set_cell(pos, brush, Vector2i(0, 0))
				
	# WASD pan
	var dir = Vector2(int(Input.is_key_pressed(KEY_A))-int(Input.is_key_pressed(KEY_D)),int(Input.is_key_pressed(KEY_W))-int(Input.is_key_pressed(KEY_S)))
	#this moves tilemap with wasd using pan speed :D
	if dir != Vector2.ZERO:
		tilemap.position += dir.normalized() * pan_speed * delta
func updatebrush():
	brush_size=brushsizeslider.value
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
			holdingDelete = event.pressed
			tilemap.set_cell(tilexy,brush,Vector2i(-1,-1))
			
			delete=true
			updatebrush()
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		panning = event.pressed
	
	if event is InputEventMouseMotion and panning:
		tilemap.position += event.relative
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and Input.is_key_pressed(KEY_CTRL):
			brushsizeslider.value = min(100.0, brushsizeslider.value + 1)
		
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and Input.is_key_pressed(KEY_CTRL):
			brushsizeslider.value = max(1.0, brushsizeslider.value - 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP :
			canvasscaleslider.value = min(10.0, canvasscaleslider.value + 0.1)
		
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN :
			canvasscaleslider.value = max(0.1, canvasscaleslider.value - 0.1)
	
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
					var dispersion =DispersionList[ID_SAND-1]
					
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
					var dispersion =DispersionList[ID_WATER-1]
					
					if tilemap.get_cell_source_id(down)==-1 and not ProccesedCells.has(cell) and not ProccesedCells.has(down):
						tilemap.set_cell(cell,-1)
						tilemap.set_cell(down, ID,Vector2i(0, 0))
						ProccesedCells[cell] = true
						ProccesedCells[down] = true
					elif DensityList[tilemap.get_cell_source_id(down)-1]<density and not ProccesedCells.has(cell) and not ProccesedCells.has(down):
						tilemap.set_cell(cell,tilemap.get_cell_source_id(down),Vector2i(0, 0))
						tilemap.set_cell(down, ID,Vector2i(0, 0))
						ProccesedCells[cell] = true
						ProccesedCells[down] = true
						
					else:
						
						var d = 1 if randi_range(0, 1) == 1 else -1 #outputs a random number 1 or -1, that later becomes the direction
						var target=null
						
						for x in range(1,dispersion):
							if tilemap.get_cell_source_id(cell+Vector2i(d*x,0))!=-1 : #check if cell not empty
								if DensityList[tilemap.get_cell_source_id(cell+Vector2i(d*x,0))-1]>density :
										target=cell+Vector2i(d*x-d,0)
										break
							if x==dispersion-1:
								target=cell+Vector2i(d*x-d,0)
						
									
						if randi_range(0,1)==1:
							if target!=null and not ProccesedCells.has(cell) and not ProccesedCells.has(target) and tilemap.get_cell_source_id(target)==-1:
								tilemap.set_cell(cell,tilemap.get_cell_source_id(target))
								tilemap.set_cell(target, ID,Vector2i(0, 0))
								ProccesedCells[cell] = true
								ProccesedCells[target] = true
						else:
							if d==1 and tilemap.get_cell_source_id(left)==-1 and not ProccesedCells.has(cell) and not ProccesedCells.has(left):
								tilemap.set_cell(cell,-1)
								tilemap.set_cell(left, ID,Vector2i(0, 0))
								ProccesedCells[cell] = true
								ProccesedCells[left] = true
							elif d==-1 and tilemap.get_cell_source_id(right)==-1 and not ProccesedCells.has(cell) and not ProccesedCells.has(right):
								tilemap.set_cell(cell,-1)
								tilemap.set_cell(right, ID,Vector2i(0, 0))
								ProccesedCells[cell] = true
								ProccesedCells[right] = true

				ID_STEAM:
					var density=DensityList[ID_STEAM-1]
					var ID=ID_STEAM
					var dispersion =DispersionList[ID_STEAM-1]
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
		
		
