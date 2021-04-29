extends AStar2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _compute_cost(from_id, to_id):
	var from_point = get_point_position(from_id)
	var to_point = get_point_position(to_id)
	var distance = from_point.distance_to(to_point)
	if distance > 32:
		distance *= 1.5
		
	return distance
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
