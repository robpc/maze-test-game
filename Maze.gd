extends Node2D

var tile_size = 64  # tile size (in pixels)
var width = 25  # width of map (in tiles)
var height = 15  # height of map (in tiles)

var spacing = 2
var erase_fraction = 0.2  # amount of wall removal

const N = 1
const E = 2
const S = 4
const W = 8

var cell_walls = {
	Vector2(1, 0): E,
	Vector2(-1, 0): W,
	Vector2(0, 1): S,
	Vector2(0, -1): N
}

@onready var Map = $TileMap
@onready var timer = $Timer
@onready var project = $CanvasLayer/Margin/BottomPanel/MarginContainer/List/Project
		
func _ready():
	var version = ProjectSettings.get_setting('build_info/package/version')
	var build_date = ProjectSettings.get_setting('build_info/package/build_date')
	project.set_value(version if version else build_date)
	reset()
	
func reset(map_seed: int = 0):
	randomize()
	if !map_seed:
		map_seed = randi()
	seed(map_seed)
	print("Seed: ", map_seed)
	tile_size = Map.tile_set.tile_size
	
	var viewport_tile_size = get_viewport().size / tile_size
	width = int(viewport_tile_size.x)
	height = int(viewport_tile_size.y)
	
	await make_maze()
	await erase_walls()
	timer.start()

func check_neighbors(cell, unvisited):
	var list = []
	for n in cell_walls.keys():
		if cell + (n * spacing) in unvisited:
			list.append(cell + (n * spacing))
	return list
	
func connect_cells(current: Vector2, next: Vector2) -> void:
	# remove walls from *both* cells
	var dir := (next - current).normalized()
	var current_walls = Map.get_cell_source_id(0, current) - cell_walls[dir]
	var next_walls = Map.get_cell_source_id(0,next) - cell_walls[-dir]
	Map.set_cell(0, current, current_walls, Vector2i.ZERO)
	Map.set_cell(0, next, next_walls, Vector2i.ZERO)
	for n in range(1, spacing):
		var cell = current + (dir * n)
		if dir.x != 0:
			Map.set_cell(0, cell, 5, Vector2i.ZERO)  # vertical road
		else:
			Map.set_cell(0, cell, 10, Vector2i.ZERO)  # horizontal road

func make_maze():
	var unvisited = []  # array of unvisited tiles
	var stack = []
	# fill the map with solid tiles
	Map.clear()
	for x in range(width):
		for y in range(height):
			Map.set_cell(0, Vector2(x, y), N|E|S|W, Vector2i.ZERO)
	for x in range(0, width, spacing):
		for y in range(0, height, spacing):
			unvisited.append(Vector2(x, y))
	var current = Vector2(0, 0)
	unvisited.erase(current)
	
	while unvisited:
		var neighbors = check_neighbors(current, unvisited)
		if neighbors.size() > 0:
			var next = neighbors[randi() % neighbors.size()]
			stack.append(current)
			
			connect_cells(current, next)
			
			current = next
			unvisited.erase(current)
		elif stack:
			current = stack.pop_back()
		await get_tree().process_frame

func erase_walls():
	# randomly remove a percentage of the map's walls
	for i in range(int(width * height * erase_fraction / spacing)):
		# pick a random tile not on the edge
		var x = (1 + randi() % ((width / spacing) - 1)) * spacing
		var y = (1 + randi() % ((height / spacing) - 1)) * spacing
		
		var current = Vector2(x, y)
		# pick a random neighbor
		var dir = cell_walls.keys()[randi() % cell_walls.size()]
		var neighbor = current + (dir * spacing)
		# if there's a wall between cell and neighbor, remove it
		if Map.get_cell_source_id(0, current) & cell_walls[dir]:
			connect_cells(current, neighbor)
		await get_tree().process_frame


func _on_timer_timeout():
	reset()
