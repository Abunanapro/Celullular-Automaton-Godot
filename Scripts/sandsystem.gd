extends Node
var brush=5 #id of the material selected
var brush_size=1
var brushtemp= 0 #temperature of brush
const ID_SAND  = 1
const ID_WATER =2
const ID_DIRT  = 3
const ID_STEAM =4
const ID_FIRE = 5
const DensityList=[1.5,1,99,0.5,0.3]
const CDispersionList=[2,5,0,5,2]
var DispersionList=[2,5,0,5,2]
const ActiveMaterialList=[1,2,4,5] #Place here material IDS that you want to "tick"
const MaterialNames=["0","Sand","Water","Dirt","Steam","Fire","Wood","Air"]#names  of each material related to id, always keep the 0 and the air names so this works porperly
#-----
#FIRE RELATED THINGS
var fire_lifespan: Dictionary = {} # Vector2i -> int (ticks remaining)
const FlammableList = [ID_DIRT]    # add any other IDs you want fire to consume	
const FIRE_MIN_LIFE = 15
const FIRE_MAX_LIFE = 35
const FIRE_SPREAD_CHANCE = 0.05    # chance per tick to ignite an eligible neighbor
const FIRE_EXTINGUISH_ON_WATER = true
#------
var temperature_map: Dictionary = {}
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
@onready var selectedmaterialLabel=$"../CanvasLayer/UI/MarginContainer/VBoxContainer/selected material"
@onready var tempselectedLabel=$"../CanvasLayer/UI/MarginContainer/VBoxContainer/selected temp"
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
@onready var firebutton=$"../CanvasLayer/UI/MarginContainer2/HBoxContainer/fire"
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
	
	
	if temperature_map.get(tilemap.local_to_map(tilemap.to_local(get_viewport().get_mouse_position()))):
		tempselectedLabel.text=str(temperature_map.get(tilemap.local_to_map(tilemap.to_local(get_viewport().get_mouse_position()))))+"Cº"
	else:
		tempselectedLabel.text="null"
	
	if tilemap.get_cell_source_id(tilemap.local_to_map(tilemap.to_local(get_viewport().get_mouse_position()))):
		selectedmaterialLabel.text=str(MaterialNames[tilemap.get_cell_source_id(tilemap.local_to_map(tilemap.to_local(get_viewport().get_mouse_position())))])
	else:
		selectedmaterialLabel.text="null"
		
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
		temperature_map[tilexy] = brushtemp
		for n in brush_size:
			for i in brush_size:
				var pos = tilexy + Vector2i(n - offset, i - offset)
				tilemap.set_cell(pos, brush,Vector2i(0,0) ,randi_range(0, 3))
				temperature_map[pos] = brushtemp
				
	# WASD pan
	var dir = Vector2(int(Input.is_key_pressed(KEY_A))-int(Input.is_key_pressed(KEY_D)),int(Input.is_key_pressed(KEY_W))-int(Input.is_key_pressed(KEY_S)))
	#this moves tilemap with wasd using pan speed :D
	if dir != Vector2.ZERO:
		tilemap.position += dir.normalized() * pan_speed * delta
		
		

func updatebrush():
	brush_size=brushsizeslider.value
	if waterbutton.button_pressed==true:
		brush=ID_WATER
		brushtemp=30
		lastmaterialbrush=ID_WATER
	elif dirtbutton.button_pressed==true:
		brush=ID_DIRT
		brushtemp=30
		lastmaterialbrush=ID_DIRT
	elif sandbutton.button_pressed==true:
		brush=ID_SAND
		brushtemp=30
		lastmaterialbrush=ID_SAND
	elif  steambutton.button_pressed==true:
		brush=ID_STEAM
		brushtemp=100
		lastmaterialbrush=ID_STEAM
	elif  firebutton.button_pressed==true:
		brush=ID_FIRE
		brushtemp=400
		lastmaterialbrush=ID_FIRE
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
#----------------------------------------------------------------
#Usefull FUNCTIONSS!!! i need this because I have to adapt the code to the new temperature map

# Moves a material from `from` to `to`, carrying its temperature with it.
# 
func move_material(from: Vector2i, to: Vector2i, id: int, alt_tile: int) -> void:
	tilemap.set_cell(to, id, Vector2i(0, 0), alt_tile)
	temperature_map[to] = temperature_map.get(from, 20)
	tilemap.set_cell(from, -1)
	temperature_map.erase(from)

# Swaps two materials' tiles AND their temperatures.
# usefull for temperature 
func swap_material(a: Vector2i, b: Vector2i) -> void:
	var a_id = tilemap.get_cell_source_id(a)
	var a_alt = tilemap.get_cell_alternative_tile(a)
	var b_id = tilemap.get_cell_source_id(b)
	var b_alt = tilemap.get_cell_alternative_tile(b)
	var a_temp = temperature_map.get(a, 20)
	var b_temp = temperature_map.get(b, 20)

	tilemap.set_cell(a, b_id, Vector2i(0, 0), b_alt)
	tilemap.set_cell(b, a_id, Vector2i(0, 0), a_alt)
	temperature_map[a] = b_temp
	temperature_map[b] = a_temp


func simulate_powder(cell: Vector2i, ID: int, dir: Vector2i, ProccesedCells: Dictionary) -> void:
	var density = DensityList[ID - 1]
	var variation = tilemap.get_cell_alternative_tile(cell)

	var fwd = cell + dir                          # straight ahead (e.g. directly below)
	var diag_left = cell + dir + Vector2i(-1, 0)   # ahead-and-left (e.g. down-left)
	var diag_right = cell + dir + Vector2i(1, 0)   # ahead-and-right (e.g. down-right)
	var side_left = cell + Vector2i(-1, 0)         # directly beside, same row (used as a "clearance check")
	var side_right = cell + Vector2i(1, 0)
	#case 1 just falling without being blocked by anything
	if tilemap.get_cell_source_id(fwd)==-1 and not ProccesedCells.has(fwd) and not ProccesedCells.has(cell):
		move_material(cell,fwd,ID,variation)
		return 
	#case 2 where we want to move to is occupied by something LESS dense
	if tilemap.get_cell_source_id(fwd)!=-1 and DensityList[tilemap.get_cell_source_id(fwd) - 1]< density and not ProccesedCells.has(fwd) and not ProccesedCells.has(cell):
		swap_material(cell,fwd)
		return 
	#case 3 where we want to move to is occupuied by a denser or same density material
	if randi_range(0, 1) == 1:
		if tilemap.get_cell_source_id(diag_left) == -1 and tilemap.get_cell_source_id(side_left) == -1 and not ProccesedCells.has(diag_left) and not ProccesedCells.has(cell):
			move_material(cell, diag_left, ID, variation)
			ProccesedCells[cell] = true
			ProccesedCells[diag_left] = true
			return
			#try to swap lighter materials that are on our diag left
		if tilemap.get_cell_source_id(side_left) != -1 and tilemap.get_cell_source_id(diag_left) != -1 and DensityList[tilemap.get_cell_source_id(side_left) - 1] != null and DensityList[tilemap.get_cell_source_id(diag_left) - 1] != null:
			if DensityList[tilemap.get_cell_source_id(diag_left) - 1] < density and DensityList[tilemap.get_cell_source_id(side_left) - 1] < density and not ProccesedCells.has(cell) and not ProccesedCells.has(diag_left):
				swap_material(cell, diag_left)
				ProccesedCells[cell] = true
				ProccesedCells[diag_left] = true
				return

	else:
		if tilemap.get_cell_source_id(diag_right) == -1 and tilemap.get_cell_source_id(side_right) == -1 and not ProccesedCells.has(cell) and not ProccesedCells.has(diag_right):
			move_material(cell, diag_right, ID, variation)
			ProccesedCells[cell] = true
			ProccesedCells[diag_right] = true
			return
		#try to swap lighter materials that are on our diag right
		if tilemap.get_cell_source_id(side_right) != -1 and tilemap.get_cell_source_id(diag_right) != -1 and DensityList[tilemap.get_cell_source_id(side_right) - 1] != null and DensityList[tilemap.get_cell_source_id(diag_right) - 1] != null:
			if DensityList[tilemap.get_cell_source_id(diag_right) - 1] < density and DensityList[tilemap.get_cell_source_id(side_right) - 1] < density and not ProccesedCells.has(cell) and not ProccesedCells.has(diag_right):
				swap_material(cell, diag_right)
				ProccesedCells[cell] = true
				ProccesedCells[diag_right] = true

# Handles liquid movement: water, steam... and if blocked they spread sideways looking for a gap.
# dir:
#   Vector2i(0, 1)  = down 
#   Vector2i(0, -1) = up  
func simulate_fluid(cell: Vector2i, ID: int, dir: Vector2i, ProccesedCells: Dictionary) -> void:
	var density = DensityList[ID - 1]
	var dispersion = DispersionList[ID - 1] # how many tiles sideways this material can "look" for a gap
	var variation = tilemap.get_cell_alternative_tile(cell)
	var fwd = cell + dir # the cell directly in the preferred direction (down for water, up for steam)
	
	#Case 1 just moving when nothing is blocking
	if tilemap.get_cell_source_id(fwd)==-1 and not ProccesedCells.has(cell) and not ProccesedCells.has(fwd):
		move_material(cell,fwd,ID,variation)
		ProccesedCells[cell] = true
		ProccesedCells[fwd] = true
		return
	#Case 2 the cell where we want to move to is occupied by something less dense than our material
	if tilemap.get_cell_source_id(fwd) != -1 and DensityList[tilemap.get_cell_source_id(fwd) - 1] < density and not ProccesedCells.has(cell) and not ProccesedCells.has(fwd):
		swap_material(cell, fwd)
		ProccesedCells[cell] = true
		ProccesedCells[fwd] = true
		return
	#Case 3 where we want to move tho is occupied by smth denser or with equal density 
	var d = 1 if randi_range(0, 1) == 1 else -1 #outputs a random number 1 or -1, that later becomes the direction
	var target=null
	for x in range(1,dispersion):
		if tilemap.get_cell_source_id(cell+Vector2i(d*x,0))!=-1 : #check if cell not empty
			if DensityList[tilemap.get_cell_source_id(cell+Vector2i(d*x,0))-1]>density :
					target=cell+Vector2i(d*x-d,0)
					break
		if x==dispersion-1:
			target=cell+Vector2i(d*x-d,0)
	#case 3.1 we found our target and we move to it
					
	if randi_range(0,1)==1:
		if target!=null and not ProccesedCells.has(cell) and not ProccesedCells.has(target) and tilemap.get_cell_source_id(target)==-1:
			move_material(cell, target, ID, variation)
			ProccesedCells[cell] = true
			ProccesedCells[target] = true
	#case 3.2 we found no target so we move sideways
	else:
		if tilemap.get_cell_source_id(cell + Vector2i(-d, 0)) == -1 and not ProccesedCells.has(cell) and not ProccesedCells.has(cell + Vector2i(-d, 0)):
			move_material(cell, cell + Vector2i(-d, 0), ID, variation)
			ProccesedCells[cell] = true
			ProccesedCells[cell + Vector2i(-d, 0)] = true
#this is just the same as liquid but it has a chance of not moving lol
func simulate_viscous(cell: Vector2i, ID: int, dir: Vector2i, ProccesedCells: Dictionary, move_chance: float) -> void:
	if randf() > move_chance:
		ProccesedCells[cell] = true # too viscouse to move try next tick :D
		return
	simulate_fluid(cell, ID, dir, ProccesedCells)



func _on_timer_timeout() -> void:
	
	updateslabel.text=("Active pixels: "+str(updates))
	updates=0
	var ProccesedCells = {} #this just prevents cells from overwiring 
	var cells:Array
	#automatically calculates active pixel ammount
	for x in range(ActiveMaterialList.size()):
		cells =cells + tilemap.get_used_cells_by_id(ActiveMaterialList[x])
	#cells = tilemap.get_used_cells_by_id(1)+tilemap.get_used_cells_by_id(2)+tilemap.get_used_cells_by_id(4)
	
	
	SandUpdates=0
	WaterUpdates=0
	SteamUpdates=0
	for cell in cells:
		
		updates=updates+1
		var up = cell + Vector2i(0, -1)
		var down = cell + Vector2i(0, 1)
		var right_bottom = cell + Vector2i(1, 1)
		var left_bottom = cell + Vector2i(-1, 1)
		var left = cell + Vector2i(-1, 0)   
		var right = cell + Vector2i(1, 0) 
		
		if not ProccesedCells.has(cell):
			match tilemap.get_cell_source_id(cell):
				ID_SAND:
					simulate_powder(cell,ID_SAND,Vector2i(0,1),ProccesedCells)
					SandUpdates=SandUpdates+1
					
					
				ID_WATER:
					simulate_fluid(cell,ID_WATER,Vector2i(0,1),ProccesedCells)
					WaterUpdates=WaterUpdates+1
					

				ID_STEAM:
					simulate_fluid(cell,ID_STEAM,Vector2i(0,-1),ProccesedCells)
					SteamUpdates=SteamUpdates+1
					
				ID_FIRE:
					var ID = ID_FIRE
					var variation = tilemap.get_cell_alternative_tile(cell)

					# --- lifespan tracking ---
					if not fire_lifespan.has(cell):
						fire_lifespan[cell] = randi_range(FIRE_MIN_LIFE, FIRE_MAX_LIFE)
					fire_lifespan[cell] -= 1 #we make the fire lose life each tick
					# extinguish once lifespan runs out
					if fire_lifespan[cell] <= 0:
						tilemap.set_cell(cell, -1)#turns into air
						temperature_map.erase(cell)#
						fire_lifespan.erase(cell)
						ProccesedCells[cell] = true
					else:
						var neighbors = [up, down, left, right, cell+Vector2i(1,-1), cell+Vector2i(-1,-1), cell+Vector2i(1,1), cell+Vector2i(-1,1)]
						var extinguished = false
						# check for water touching this fire -> put it out, turn to steam
						if FIRE_EXTINGUISH_ON_WATER:
							for n in neighbors:
								if tilemap.get_cell_source_id(n) == ID_WATER:
									tilemap.set_cell(cell, ID_STEAM, Vector2i(0,0), randi_range(0,3))
									temperature_map[cell] = 100
									fire_lifespan.erase(cell)
									ProccesedCells[cell] = true
									extinguished = true
									break
						if not extinguished:
							# try to ignite a random flammable neighbor
							neighbors.shuffle()#rondomizes neighbor order
							for n in neighbors:
								var n_id = tilemap.get_cell_source_id(n)
								if n_id in FlammableList and not ProccesedCells.has(n) and not fire_lifespan.has(n):
									if randf() < FIRE_SPREAD_CHANCE:
										tilemap.set_cell(n, ID_FIRE, Vector2i(0,0), randi_range(0,3))
										fire_lifespan[n] = randi_range(FIRE_MIN_LIFE, FIRE_MAX_LIFE)
										temperature_map[n] = 400
										ProccesedCells[n] = true
										break # one ignite per tick keeps spread readable, remove to make it more aggressive
							# visual flicker: randomize the alt tile every tick so it changes color
							tilemap.set_cell(cell, ID, Vector2i(0,0), randi_range(0,3))
							# slightly goes upp
							if randf() < 0.4 and tilemap.get_cell_source_id(up) == -1 and not ProccesedCells.has(up) and not ProccesedCells.has(cell):
								tilemap.set_cell(cell, -1)
								tilemap.set_cell(up, ID, Vector2i(0,0), randi_range(0,3))
								fire_lifespan[up] = fire_lifespan[cell]
								fire_lifespan.erase(cell)
								temperature_map[up] = temperature_map.get(cell, 400)
							ProccesedCells[cell] = true
								
