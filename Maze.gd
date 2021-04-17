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

onready var Map = $TileMap
onready var timer = $Timer
		
func _ready():
	reset()
	
func reset(map_seed: int = 0):
	randomize()
	if !map_seed:
		map_seed = randi()
	seed(map_seed)
	print("Seed: ", map_seed)
	tile_size = Map.cell_size
	
	var viewport_tile_size = get_viewport().size / tile_size
	width = int(viewport_tile_size.x)
	height = int(viewport_tile_size.y)
	
	yield(make_maze(), 'completed')
	yield(erase_walls(), 'completed')
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
	var current_walls = Map.get_cellv(current) - cell_walls[dir]
	var next_walls = Map.get_cellv(next) - cell_walls[-dir]
	Map.set_cellv(current, current_walls)
	Map.set_cellv(next, next_walls)
	for n in range(1, spacing):
		var cell = current + (dir * n)
		if dir.x != 0:
			Map.set_cellv(cell, 5)  # vertical road
		else:
			Map.set_cellv(cell, 10)  # horizontal road

func make_maze():
	var unvisited = []  # array of unvisited tiles
	var stack = []
	# fill the map with solid tiles
	Map.clear()
	for x in range(width):
		for y in range(height):
			Map.set_cellv(Vector2(x, y), N|E|S|W)
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
		yield(get_tree(), 'idle_frame')

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
		if Map.get_cellv(current) & cell_walls[dir]:
			connect_cells(current, neighbor)
		yield(get_tree(), 'idle_frame')


func _on_timer_timeout():
	reset()
