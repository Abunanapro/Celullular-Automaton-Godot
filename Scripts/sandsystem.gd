extends Node

var brush=6 #id of the material selected
var brush_size=1
var brushtemp= 0 #temperature of brush
@onready var world_container=$WorldContainer

const CHUNK_SIZE = 16
const CELL_PIXEL_SIZE = 8

#COLORS:
const MaterialColors = {
	-1: Color(0, 0, 0, 0),           # air
	1: Color(0.87, 0.73, 0.35, 1.0), # sand
	2: Color(0.2, 0.4, 0.9, 0.8),    # water
	3: Color(0.125, 0.073, 0.01, 1.0),   # dirt
	4: Color(0.8, 0.8, 0.85, 0.5),   # steam
	5: Color(1.0, 0.4, 0.1, 1.0),    # fire
	6:Color(0.294, 0.179, 0.063, 1.0), #wood
	7:Color(0.05, 0.05, 0.05, 1.0), #oil
	8:Color(0.41, 0.0, 0.0, 1.0), #magma
	9:Color(0.059, 0.89, 0.0, 1.0), #acid
	10:Color(0.095, 0.476, 0.783, 0.9), #ice
	11:Color(0.634, 0.842, 1.0, 0.7), #glass
	12:Color(0.819, 0.613, 0.284, 1.0),#wood dust
	13:Color(0.137, 0.115, 0.088, 0.5) #butane
}

const ID_SAND  = 1
const ID_WATER =2
const ID_DIRT  = 3
const ID_STEAM =4
const ID_FIRE = 5
const ID_WOOD =6
const ID_OIL=7
const ID_MAGMA=8
const ID_ACID=9
const ID_ICE=10
const ID_GLASS=11
const ID_WOODDUST=12
const ID_BUTANE=13

const DensityList=[1.5,1,99,0.5,0.3,99,1.2,4,1,0.9,99,1.2,0.6]
const CDispersionList=[2,5,0,5,2,0,6,2,5,0,0,2,7]
var DispersionList=[2,5,0,5,2]
const ActiveMaterialList=[1,2,4,5,7,8,9,12,13] #Place here material IDS that you want to "tick"
const MaterialNames=["0","Sand","Water","Dirt","Steam","Fire","Wood","Oil","Magma","Acid","Ice","Glass","Wood Dust","Butane","Air"]#names  of each material related to id, always keep the 0 and the air names so this works porperly
#-----

var FireHealth: Dictionary={}
#------
var dirty_cells: Dictionary = {}
var chunks: Dictionary = {}
var temperature_map: Dictionary = {}
var active_chunks: Dictionary = {}
var next_active_chunks: Dictionary = {}
var holding= false
var holdingDelete=false
var delete=false
var lastmaterialbrush=6
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
#no longer used^
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
#https://es.wikipedia.org/wiki/Algoritmo_de_Bresenham A
func get_line_cells(from: Vector2i, to: Vector2i) -> Array:
	var cells = []
	var dx = abs(to.x - from.x)
	var dy = -abs(to.y - from.y)
	var sx = 1 if from.x < to.x else -1
	var sy = 1 if from.y < to.y else -1
	var err = dx + dy
	var current = from
	while true:
		cells.append(current)
		if current == to:
			break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			current.x += sx
		if e2 <= dx:
			err += dx
			current.y += sy
	return cells



#EXTREMLEY IMPORTANT FUNCTIONS! to pass this from one thread to multiple threads, bcs I have to change the way the simulations saves the tilemap, because if I multithread I can't acces tilemap :C
func ensure_chunk_sprite(chunk_coord: Vector2i, chunk: ChunkData) -> void:
	if chunk.sprite != null:
		return
	var sprite = Sprite2D.new()
	sprite.texture = chunk.texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(CELL_PIXEL_SIZE, CELL_PIXEL_SIZE)
	sprite.position = Vector2(chunk_coord.x * CHUNK_SIZE * CELL_PIXEL_SIZE,chunk_coord.y * CHUNK_SIZE * CELL_PIXEL_SIZE)
	world_container.add_child(sprite)
	chunk.sprite = sprite

func grid_get_id(cell: Vector2i) -> int:
	var chunk_cord =cell_to_chunk(cell)
	var chunk = get_chunk(chunk_cord, false)
	if chunk == null:
		return -1
	return chunk.ids[local_index(cell)]
	

func grid_get_temp(cell: Vector2i) -> int:
	var chunk_cord =cell_to_chunk(cell)
	var chunk = get_chunk(chunk_cord, false)
	if chunk == null:
		return -1
	return chunk.temps[local_index(cell)]
	
func grid_get_alt(cell: Vector2i) -> int:
	var chunk_cord =cell_to_chunk(cell)
	var chunk = get_chunk(chunk_cord, false)
	if chunk == null:
		return 0
	return chunk.alts[local_index(cell)]

func temp_set(cell: Vector2i, temp: int) -> void:
	var chunk_cord =cell_to_chunk(cell)
	var chunk = get_chunk(chunk_cord, true)
	chunk.temps[local_index(cell)]=temp
	
	
func grid_set(cell: Vector2i, id: int, alt: int) -> void:
	var chunk_cord =cell_to_chunk(cell)
	var chunk = get_chunk(chunk_cord, true)
	var idx = local_index(cell)
	if chunk.ids[idx] == id:
		return
	chunk.ids[local_index(cell)]=id
	chunk.alts[local_index(cell)]=alt
	dirty_cells[cell] = true

class ChunkData:
	var ids: PackedInt32Array     
	var alts: PackedInt32Array    
	var temps: PackedInt32Array   
	var image: Image              
	var texture: ImageTexture    
	var sprite: Sprite2D          

	func _init():
		var size = CHUNK_SIZE * CHUNK_SIZE
		ids.resize(size)
		alts.resize(size)
		temps.resize(size)
		ids.fill(-1)
		alts.fill(0)
		temps.fill(20)


		image = Image.create(CHUNK_SIZE, CHUNK_SIZE, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		texture = ImageTexture.create_from_image(image)
		sprite = null
func mouse_to_cell() -> Vector2i:
	var mouse_pos = get_viewport().get_mouse_position()
	var local_pos = world_container.to_local(mouse_pos)
	return Vector2i(floori(local_pos.x / CELL_PIXEL_SIZE), floori(local_pos.y / CELL_PIXEL_SIZE))
#updates the images shown it used to use tilemap thats why it has this name ...
func sync_tilemap() -> void:
	if dirty_cells.is_empty():
		return
	var touched_chunks: Dictionary = {}
	for cell in dirty_cells.keys():
		var chunk_coord = cell_to_chunk(cell)
		var chunk = get_chunk(chunk_coord, true)
		ensure_chunk_sprite(chunk_coord, chunk)
		var idx = local_index(cell)
		var material_id = chunk.ids[idx]
		var base_color = MaterialColors.get(material_id, Color(1, 0, 1, 1))
		var alt = chunk.alts[idx]
		var color = vary_color(base_color, alt)
		var lx = ((cell.x % CHUNK_SIZE) + CHUNK_SIZE) % CHUNK_SIZE
		var ly = ((cell.y % CHUNK_SIZE) + CHUNK_SIZE) % CHUNK_SIZE
		chunk.image.set_pixel(lx, ly, color)
		touched_chunks[chunk_coord] = true
	for chunk_coord in touched_chunks.keys():
		var chunk = chunks[chunk_coord]
		chunk.texture.update(chunk.image)
	dirty_cells.clear()
	#vary the color of the materials
func vary_color(base: Color, alt: int) -> Color:
	if base.a == 0.0: #if transparent skip the color variation
		return base  
	 
	var factor = [1.0, 0.9, 1.1, 0.95][alt % [1.0, 0.9, 1.1, 0.95].size()] 
	return Color(clamp(base.r * factor, 0.0, 1.0),clamp(base.g * factor, 0.0, 1.0),clamp(base.b * factor, 0.0, 1.0),base.a)
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
var lastcellmouse:Vector2i
var scale_val=4.0/10.0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if holding and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or holdingDelete and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		holding = false
		holdingDelete=false
	
	
	if grid_get_temp(mouse_to_cell())!=-1:
		tempselectedLabel.text=str(grid_get_temp(mouse_to_cell()))+"Cº"
	else:
		tempselectedLabel.text=str(20)+"Cº"
	
	if grid_get_id(mouse_to_cell()):
		selectedmaterialLabel.text=str(MaterialNames[grid_get_id(mouse_to_cell())])
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
		for c in chunks.values():
			if c.sprite != null:
				c.sprite.queue_free()
		chunks.clear()
		dirty_cells.clear()
		active_chunks.clear()
		next_active_chunks.clear()
	#Settings Menu Scripts
	if settingsbutton.button_pressed and not settings_was_pressed:
		settingsmenu.visible = !settingsmenu.visible
		settings_was_pressed = true
	elif not settingsbutton.button_pressed:
		settings_was_pressed = false
	#Settings Sliders
	globalvolume=volumeslider.value
	VolumeLabel.text="Volume "+str(volumeslider.value)
	var old_s = world_container.scale.x
	var new_s = canvasscaleslider.value
	if new_s != old_s:
		var m = get_viewport().get_mouse_position()
		world_container.position = m - (m - world_container.position) * (new_s / old_s)
		world_container.scale = Vector2(new_s, new_s)
	CanvasScaleLabel.text = "Scale: %.1fx" % new_s
#dispersion toggle
	if DispersionButton.button_pressed==true:
		DispersionList=CDispersionList
	else:
		DispersionList=[2,2,0,2]
	#Main
	if holding or holdingDelete:
		var mouse_pos = get_viewport().get_mouse_position()
		var tilexy = mouse_to_cell()
		var offset = floor(brush_size / 2.0)
		for c in get_line_cells(lastcellmouse, tilexy):
			for n in brush_size:
				for i in brush_size:
					var pos = c + Vector2i(n - offset, i - offset)
					grid_set(pos, brush, randi_range(0, 3))
					temperature_map[pos] = brushtemp
					wake_cell(pos)
		grid_set(tilexy, brush, 1)
		
		temperature_map[tilexy] = brushtemp
		
				
	# WASD pan
	var dir = Vector2(int(Input.is_key_pressed(KEY_A))-int(Input.is_key_pressed(KEY_D)),int(Input.is_key_pressed(KEY_W))-int(Input.is_key_pressed(KEY_S)))
	#this moves tilemap with wasd using pan speed :D
	if dir != Vector2.ZERO:
		tilemap.position += dir.normalized() * pan_speed * delta
		
	sync_tilemap()
	lastcellmouse=mouse_to_cell()

func updatebrush():
	brush_size=brushsizeslider.value
	#moved to autobuttonmaker script 
	if delete==true:
		brush=-1
	
	
func _input(event:InputEvent) -> void:
	if get_viewport().gui_get_hovered_control() != null:
		updatebrush()
		return
	

	if  event is InputEventMouseButton:
		var tilexy=mouse_to_cell()
		if event.button_index == MOUSE_BUTTON_LEFT:
			holding = event.pressed
			
			delete=false
			brush=lastmaterialbrush
			
			updatebrush()
			wake_cell(tilexy)
			grid_set(tilexy,brush,1)
			
		if event.button_index == MOUSE_BUTTON_RIGHT:
			holdingDelete = event.pressed
			grid_set(tilexy,brush,1)
			wake_cell(tilexy)
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

#Cell_to_chunk function, this calculates on wich chunk this cell is located
func cell_to_chunk(cell: Vector2i)->Vector2i:
	var chunk_x = floori(float(cell.x) / CHUNK_SIZE)
	
	var chunk_y = floori(float(cell.y) / CHUNK_SIZE)
	return Vector2i(chunk_x, chunk_y)
#gets localized cords example cell 17,17->1,1
func local_index(cell: Vector2i) -> int:
	
	var lx = ((cell.x % CHUNK_SIZE) + CHUNK_SIZE) % CHUNK_SIZE
	var ly = ((cell.y % CHUNK_SIZE) + CHUNK_SIZE) % CHUNK_SIZE
	return ly * CHUNK_SIZE + lx
#gets chunk from chunk dictionary
func get_chunk(chunk_coord: Vector2i, create_if_missing: bool):
	if chunks.has(chunk_coord):
		return chunks[chunk_coord]
		
		
	if not create_if_missing:
		return null
	var chunknew=ChunkData.new()
	chunks[chunk_coord]= chunknew
	return chunknew
#this function wakes up surrounding cells 
func wake_cell(cell: Vector2i)->void:
	for dx in [-1, 0, 1]:      
		for dy in [-1, 0, 1]:  
			var neighborcell = cell + Vector2i(dx, dy)
			var chunk = cell_to_chunk(neighborcell)
			# Marcamos ese chunk como "activo para el próximo tick"
			next_active_chunks[chunk] = true

# Moves a material from `from` to `to`, carrying its temperature with it.
# 
func move_material(from: Vector2i, to: Vector2i, id: int, alt_tile: int) -> void:
	grid_set(to, id, alt_tile)
	temperature_map[to] = temperature_map.get(from, 20)
	grid_set(from, -1,0)
	temperature_map.erase(from)
	
	wake_cell(from)
	wake_cell(to)
	

# Swaps two materials' tiles AND their temperatures.
# usefull for temperature 
func swap_material(a: Vector2i, b: Vector2i) -> void:
	var a_id = grid_get_id(a)
	var a_alt = grid_get_alt(a)
	var b_id = grid_get_id(b)
	var b_alt = grid_get_alt(b)
	var a_temp = temperature_map.get(a, 20)
	var b_temp = temperature_map.get(b, 20)

	grid_set(a, b_id, b_alt)
	grid_set(b, a_id, a_alt)
	temperature_map[a] = b_temp
	temperature_map[b] = a_temp
	
	wake_cell(a)
	wake_cell(b)



func simulate_powder(cell: Vector2i, ID: int, dir: Vector2i, ProccesedCells: Dictionary) -> void:
	var density = DensityList[ID - 1]
	var variation = grid_get_alt(cell)

	var fwd = cell + dir                          # straight ahead (e.g. directly below)
	var diag_left = cell + dir + Vector2i(-1, 0)   # ahead-and-left (e.g. down-left)
	var diag_right = cell + dir + Vector2i(1, 0)   # ahead-and-right (e.g. down-right)
	var side_left = cell + Vector2i(-1, 0)         # directly beside, same row (used as a "clearance check")
	var side_right = cell + Vector2i(1, 0)
	#case 1 just falling without being blocked by anything
	if grid_get_id(fwd)==-1 and not ProccesedCells.has(fwd) and not ProccesedCells.has(cell):
		move_material(cell,fwd,ID,variation)
		ProccesedCells[cell]=true
		ProccesedCells[fwd]=true
		return 
	#case 2 where we want to move to is occupied by something LESS dense
	if grid_get_id(fwd)!=-1 and DensityList[grid_get_id(fwd) - 1]< density and not ProccesedCells.has(fwd) and not ProccesedCells.has(cell):
		swap_material(cell,fwd)
		ProccesedCells[cell]=true
		ProccesedCells[fwd]=true
		return 
	#case 3 where we want to move to is occupuied by a denser or same density material
	if randi_range(0, 1) == 1:
		if grid_get_id(diag_left) == -1 and grid_get_id(side_left) == -1 and not ProccesedCells.has(diag_left) and not ProccesedCells.has(cell):
			move_material(cell, diag_left, ID, variation)
			ProccesedCells[cell] = true
			ProccesedCells[diag_left] = true
			return
			#try to swap lighter materials that are on our diag left
		if grid_get_id(side_left) != -1 and grid_get_id(diag_left) != -1 and DensityList[grid_get_id(side_left) - 1] != null and DensityList[grid_get_id(diag_left) - 1] != null:
			if DensityList[grid_get_id(diag_left) - 1] < density and DensityList[grid_get_id(side_left) - 1] < density and not ProccesedCells.has(cell) and not ProccesedCells.has(diag_left):
				swap_material(cell, diag_left)
				ProccesedCells[cell] = true
				ProccesedCells[diag_left] = true
				return

	else:
		if grid_get_id(diag_right) == -1 and grid_get_id(side_right) == -1 and not ProccesedCells.has(cell) and not ProccesedCells.has(diag_right):
			move_material(cell, diag_right, ID, variation)
			ProccesedCells[cell] = true
			ProccesedCells[diag_right] = true
			return
		#try to swap lighter materials that are on our diag right
		if grid_get_id(side_right) != -1 and grid_get_id(diag_right) != -1 and DensityList[grid_get_id(side_right) - 1] != null and DensityList[grid_get_id(diag_right) - 1] != null:
			if DensityList[grid_get_id(diag_right) - 1] < density and DensityList[grid_get_id(side_right) - 1] < density and not ProccesedCells.has(cell) and not ProccesedCells.has(diag_right):
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
	var variation = grid_get_alt(cell)
	var fwd = cell + dir # the cell directly in the preferred direction (down for water, up for steam)
	
	#Case 1 just moving when nothing is blocking
	if grid_get_id(fwd)==-1 and not ProccesedCells.has(cell) and not ProccesedCells.has(fwd):
		move_material(cell,fwd,ID,variation)
		ProccesedCells[cell] = true
		ProccesedCells[fwd] = true
		return
	#Case 2 the cell where we want to move to is occupied by something less dense than our material
	if grid_get_id(fwd) != -1 and DensityList[grid_get_id(fwd) - 1] < density and not ProccesedCells.has(cell) and not ProccesedCells.has(fwd):
		swap_material(cell, fwd)
		ProccesedCells[cell] = true
		ProccesedCells[fwd] = true
		return
	#Case 3 where we want to move tho is occupied by smth denser or with equal density 
	var d = 1 if randi_range(0, 1) == 1 else -1 #outputs a random number 1 or -1, that later becomes the direction
	var target=null
	for x in range(1,dispersion):
		if grid_get_id(cell+Vector2i(d*x,0))!=-1 : #check if cell not empty
			if DensityList[grid_get_id(cell+Vector2i(d*x,0))-1]>density :
					target=cell+Vector2i(d*x-d,0)
					break
		if x==dispersion-1:
			target=cell+Vector2i(d*x-d,0)
	#case 3.1 we found our target and we move to it
					
	if randi_range(0,1)==1:
		if target!=null and not ProccesedCells.has(cell) and not ProccesedCells.has(target) and grid_get_id(target)==-1:
			move_material(cell, target, ID, variation)
			ProccesedCells[cell] = true
			ProccesedCells[target] = true
	#case 3.2 we found no target so we move sideways
	else:
		if grid_get_id(cell + Vector2i(-d, 0)) == -1 and not ProccesedCells.has(cell) and not ProccesedCells.has(cell + Vector2i(-d, 0)):
			move_material(cell, cell + Vector2i(-d, 0), ID, variation)
			ProccesedCells[cell] = true
			ProccesedCells[cell + Vector2i(-d, 0)] = true
#this is just the same as liquid but it has a chance of not moving lol
func simulate_viscous(cell: Vector2i, ID: int, dir: Vector2i, ProccesedCells: Dictionary, move_chance: float) -> void:
	if randf() > move_chance:
		ProccesedCells[cell] = true # too viscouse to move try next tick :D
		return
	simulate_fluid(cell, ID, dir, ProccesedCells)
#simulate fire material 
func simulate_fire(cell: Vector2i, ID: int, dir: Vector2i, ProccesedCells: Dictionary, canburnlist:Array,flammability:float,maxinitialhealth:int,mininitialhealth:int) -> void:
	var density = DensityList[ID - 1]
	var dispersion = DispersionList[ID - 1] # how many tiles sideways this material can "look" for a gap
	var variation = grid_get_alt(cell)
	var fwd = cell + dir # the cell directly in the preferred direction (down for water, up for steam)
	var initialhealth=randi_range(mininitialhealth,maxinitialhealth)
	if FireHealth.has(cell)!=true:
		FireHealth.set(cell,initialhealth)
	if FireHealth.get(cell)<=0:
		FireHealth.erase(cell)
		grid_set(cell,-1,0)
		return
	if FireHealth.get(cell)!=null:
		FireHealth.set(cell,FireHealth.get(cell)-1)
	for dx in [-1, 0, 1]:      
		for dy in [-1, 0, 1]:  
			var neighborcell = cell + Vector2i(dx, dy)
			if canburnlist.has(grid_get_id(neighborcell)) and randf()<flammability:
				grid_set(neighborcell,5,randi_range(0,3))
				wake_cell(neighborcell)
				FireHealth.set(cell,FireHealth.get(cell)-1)
				return
			
			# Marcamos ese chunk como "activo para el próximo tick"
			
	#Case 1 just moving when nothing is blocking
	if grid_get_id(fwd)==-1 and not ProccesedCells.has(cell) and not ProccesedCells.has(fwd):
		move_material(cell,fwd,ID,variation)
		FireHealth.set(fwd,FireHealth.get(cell))
		FireHealth.erase(cell)
		ProccesedCells[cell] = true
		ProccesedCells[fwd] = true
		return
	#Case 2 the cell where we want to move to is occupied by something less dense than our material
	if grid_get_id(fwd) != -1 and DensityList[grid_get_id(fwd) - 1] < density and not ProccesedCells.has(cell) and not ProccesedCells.has(fwd):
		FireHealth.set(fwd, FireHealth.get(cell))
		FireHealth.erase(cell)
		swap_material(cell, fwd)
		ProccesedCells[cell] = true
		ProccesedCells[fwd] = true
		return
	#Case 3 where we want to move tho is occupied by smth denser or with equal density 
	var d = 1 if randi_range(0, 1) == 1 else -1 #outputs a random number 1 or -1, that later becomes the direction
	var target=null
	for x in range(1,dispersion):
		if grid_get_id(cell+Vector2i(d*x,0))!=-1 : #check if cell not empty
			if DensityList[grid_get_id(cell+Vector2i(d*x,0))-1]>density :
					target=cell+Vector2i(d*x-d,0)
					break
		if x==dispersion-1:
			target=cell+Vector2i(d*x-d,0)
	#case 3.1 we found our target and we move to it
					
	if randi_range(0,1)==1:
		if target!=null and not ProccesedCells.has(cell) and not ProccesedCells.has(target) and grid_get_id(target)==-1:
			
			move_material(cell, target, ID, variation)
			FireHealth.set(target,FireHealth.get(cell))
			FireHealth.erase(cell)
			ProccesedCells[cell] = true
			ProccesedCells[target] = true
	#case 3.2 we found no target so we move sideways
	else:
		if grid_get_id(cell + Vector2i(-d, 0)) == -1 and not ProccesedCells.has(cell) and not ProccesedCells.has(cell + Vector2i(-d, 0)):
			
			move_material(cell, cell + Vector2i(-d, 0), ID, variation)
			FireHealth.set(cell + Vector2i(-d, 0),FireHealth.get(cell))
			FireHealth.erase(cell)
			ProccesedCells[cell] = true
			ProccesedCells[cell + Vector2i(-d, 0)] = true


func _on_timer_timeout() -> void:
	
	print("Chunks activos: ", active_chunks.size())
	updateslabel.text=("Active pixels: "+str(updates))
	updates=0
	SandUpdates=0
	WaterUpdates=0
	SteamUpdates=0
	var ProccesedCells = {} #this just prevents cells from overwiring 
	
	
	
	for chunk_coord in active_chunks.keys():
		#calculates the start of the chunk
		var initial_x = chunk_coord.x * CHUNK_SIZE
		var initial_y = chunk_coord.y * CHUNK_SIZE
		#simulate the chunk
		for x in range(CHUNK_SIZE):
			for y in range(CHUNK_SIZE):
				var cell = Vector2i(initial_x + x, initial_y + y)
				updates = updates + 1
				if ProccesedCells.has(cell) or grid_get_id(cell)==-1:
					continue #skip already proccesed cells
				match grid_get_id(cell):
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
						simulate_fire(cell,ID_FIRE, Vector2i(0,-2),ProccesedCells,[6],0.3,10,5)
					ID_MAGMA:
						simulate_fire(cell,ID_MAGMA,Vector2i(0,1),ProccesedCells,[6],0.1,20,10)
					ID_OIL:
						simulate_fluid(cell,ID_OIL,Vector2i(0,2),ProccesedCells)
					ID_WOODDUST:
						simulate_powder(cell,ID_WOODDUST,Vector2i(0,1),ProccesedCells)
					ID_BUTANE:
						simulate_fluid(cell,ID_BUTANE,Vector2i(0,-1),ProccesedCells)
					
	active_chunks = next_active_chunks
	next_active_chunks = {}
	
