extends TileMap

var astar = load("res://AStar2d_diag.gd").new()
var squares = {}

# TODO: disable static squares or remove from astar
func _ready():
	var id = 0
	for cell in get_used_cells():
		astar.add_point(id, map_to_world(cell) + Vector2(16, 16))
		if (get_cell(cell[0], cell[1]) > -1) && !is_static_square(cell):
			squares[str(cell)] = {"occupied": false}
		else:
			squares[str(cell)] = {"occupied": true}
		id += 1
	id = 0

	var stuff = get_node("Stuff").get_children()
	for thing in stuff:
		if thing.type == "static_object":
			var cell = world_to_map(thing.position)
			squares[str(cell)].occupied = true

	for cell in get_used_cells():
		var top_cell_coords = cell + Vector2(0, -1)
		var top_cell_tile = get_cell(top_cell_coords[0], top_cell_coords[1])
		var left_cell_coords = cell + Vector2(-1, 0)
		var left_cell_tile = get_cell(left_cell_coords[0], left_cell_coords[1])
		var bottom_cell_coords = cell + Vector2(0, 1)
		var bottom_cell_tile = get_cell(bottom_cell_coords[0], bottom_cell_coords[1])
		var right_cell_coords = cell + Vector2(1, 0)
		var right_cell_tile = get_cell(right_cell_coords[0], right_cell_coords[1])
		var top_left_cell_coords = cell + Vector2(-1, -1)
		var top_left_cell_tile = get_cell(top_left_cell_coords[0], top_left_cell_coords[1])
		var bottom_left_cell_coords = cell + Vector2(-1, 1)
		var bottom_left_cell_tile = get_cell(bottom_left_cell_coords[0], bottom_cell_coords[1])
		var top_right_cell_coords = cell + Vector2(1, -1)
		var top_right_cell_tile = get_cell(top_right_cell_coords[0], top_right_cell_coords[1])
		var bottom_right_cell_coords = cell + Vector2(1, 1)
		var bottom_right_cell_tile = get_cell(bottom_right_cell_coords[0], bottom_right_cell_coords[1])
		
		if(top_cell_tile > -1):
			var top_point = astar.get_closest_point(map_to_world(top_cell_coords))
			if top_point != id && top_point > -1:
				astar.connect_points(id, top_point)
		if(left_cell_tile > -1):
			var left_point = astar.get_closest_point(map_to_world(left_cell_coords))
			if left_point != id && left_point > -1:
				astar.connect_points(id, left_point)
		if(bottom_cell_tile > -1):
			var bottom_point = astar.get_closest_point(map_to_world(bottom_cell_coords))
			if bottom_point != id && bottom_point > -1:
				astar.connect_points(id, bottom_point)
		if(right_cell_tile > -1):
			var right_point = astar.get_closest_point(map_to_world(right_cell_coords))
			if right_point != id && right_point > -1:
				astar.connect_points(id, right_point)
		if(top_left_cell_tile > -1):
			var top_left_point = astar.get_closest_point(map_to_world(top_left_cell_coords))
			if top_left_point != id && top_left_point > -1:
				astar.connect_points(id, top_left_point)
		if(bottom_left_cell_tile > -1):
			var bottom_left_point = astar.get_closest_point(map_to_world(bottom_left_cell_coords))
			if bottom_left_point != id && bottom_left_point > -1:
				astar.connect_points(id, bottom_left_point)
		if(top_right_cell_tile > -1):
			var top_right_point = astar.get_closest_point(map_to_world(top_right_cell_coords))
			if top_right_point != id && top_right_point > -1:
				astar.connect_points(id, top_right_point)
		if(bottom_right_cell_tile > -1):
			var bottom_right_point = astar.get_closest_point(map_to_world(bottom_right_cell_coords))
			if bottom_right_point != id && bottom_right_point > -1:
				astar.connect_points(id, bottom_right_point)
			
		id += 1

func request_square(position):
	if squares && squares.size() > 0:
		var cell = world_to_map(position)
		return !squares[str(cell)].occupied
	return true

func is_static_square(cell):
	if get_cell(cell[0], cell[1]) in [1]:
		return true
