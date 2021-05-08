extends Node2D

const MOTION_SPEED = 64 # Pixels/second.
const TILE_SIZE = 32
var virtualPosition
var movingDirection = Vector2(0, 0)
var lastWalkSprite = null
var walkDownSprite = null
var walkLeftSprite = null
var walkUpSprite = null
var walkRightSprite = null

var tile_map
var point_path

func _ready():
	virtualPosition = position
	walkDownSprite = get_node("WalkDown")
	walkLeftSprite = get_node("WalkLeft")
	walkUpSprite = get_node("WalkUp")
	walkRightSprite = get_node("WalkRight")
	lastWalkSprite = walkDownSprite
	tile_map = $"../../TileMap"
	if get_tree().get_network_unique_id() == int(get_name()):
		$Controls.show()
		$Camera2D.current = true

func _unhandled_input(event):
	if get_tree().get_network_unique_id() == int(get_name()):
		if not event.is_action_pressed("click") && not event is InputEventScreenTouch:
			return
		var touch_pos
		if event.is_action_pressed("click"):
			gamestate.rpc_id(1, "set_player_clicked", get_global_mouse_position())
		if event is InputEventScreenTouch && event.pressed && event.index == 0:
			touch_pos = get_canvas_transform().affine_inverse().xform(event.position)    
			gamestate.rpc_id(1, "set_player_clicked", touch_pos)
		set_point_path(touch_pos)
func _process(_delta):
	if is_network_master():
		if gamestate.get_player_clicked(get_name()):
			set_point_path(null)
			gamestate.unset_player_clicked(get_name())
		if !point_path:
			if reachedVirtualPosition() && movingDirection:
				stopMovingReached()
				
			if reachedVirtualPosition() || !movingDirection:
				if gamestate.get_player_input_action(get_name()) == "move_right":
					movingDirection = Vector2(1, 0)
					virtualPosition.x = position.x + TILE_SIZE
					virtualPosition.y = position.y
				if gamestate.get_player_input_action(get_name()) == "move_left":
					movingDirection = Vector2(-1, 0)
					virtualPosition.x = position.x - TILE_SIZE
					virtualPosition.y = position.y
				if gamestate.get_player_input_action(get_name()) == "move_up":
					movingDirection = Vector2(0, -1)
					virtualPosition.y = position.y - TILE_SIZE
					virtualPosition.x = position.x
				if gamestate.get_player_input_action(get_name()) == "move_down":
					movingDirection = Vector2(0, 1)
					virtualPosition.y = position.y + TILE_SIZE
					virtualPosition.x = position.x
					
				request_square()
			
	elif get_tree().get_network_unique_id() == int(get_name()):
		if Input.get_action_strength("move_right") || Input.get_action_strength("move_right_mobile"):
			gamestate.rpc_id(1, "set_player_input", "move_right")
		elif Input.get_action_strength("move_left") || Input.get_action_strength("move_left_mobile"):
			gamestate.rpc_id(1, "set_player_input", "move_left")
		elif Input.get_action_strength("move_up") || Input.get_action_strength("move_up_mobile"):
			gamestate.rpc_id(1, "set_player_input", "move_up")
		elif Input.get_action_strength("move_down") || Input.get_action_strength("move_down_mobile"):
			gamestate.rpc_id(1, "set_player_input", "move_down")
		else:
			gamestate.rpc_id(1, "set_player_input", "")
			
		if !point_path:
			if reachedVirtualPosition() && movingDirection:
				stopMovingReached()
			
			if reachedVirtualPosition() || !movingDirection:
				if Input.get_action_strength("move_right") || Input.get_action_strength("move_right_mobile"):
					movingDirection = Vector2(1, 0)
					virtualPosition.x = position.x + TILE_SIZE
					virtualPosition.y = position.y
				if Input.get_action_strength("move_left") || Input.get_action_strength("move_left_mobile"):
					movingDirection = Vector2(-1, 0)
					virtualPosition.x = position.x - TILE_SIZE
					virtualPosition.y = position.y
				if Input.get_action_strength("move_up") || Input.get_action_strength("move_up_mobile"):
					movingDirection = Vector2(0, -1)
					virtualPosition.y = position.y - TILE_SIZE
					virtualPosition.x = position.x
				if Input.get_action_strength("move_down") || Input.get_action_strength("move_down_mobile"):
					movingDirection = Vector2(0, 1)
					virtualPosition.y = position.y + TILE_SIZE
					virtualPosition.x = position.x
					
				request_square()
			
func _physics_process(_delta):
	if is_network_master():
		if !point_path:
			move_delta(_delta)
		else:
			move_along_path(_delta)
		gamestate.set_player_position(get_name(), self.position)
		gamestate.set_player_moving_direction(get_name(), self.movingDirection)
		gamestate.set_player_virtual_pos(get_name(), self.virtualPosition)
		gamestate.set_player_point_path(get_name(), self.point_path)
			
	elif get_tree().get_network_unique_id() == int(get_name()):
		if !point_path:
			move_delta(_delta)
		else:
			move_along_path(_delta)
	set_sprite_direction()
		
func set_player_name(new_name):
	$Label.set_text(new_name)
			
func set_sprite_direction():
	walkDownSprite.visible = false
	walkLeftSprite.visible = false
	walkRightSprite.visible = false
	walkUpSprite.visible = false
	
	if lastWalkSprite != null:
		lastWalkSprite.visible = true
		
	if movingDirection.x == 1:
		walkRightSprite.visible = true
		lastWalkSprite = walkRightSprite
	if movingDirection.x == -1:
		walkLeftSprite.visible = true
		lastWalkSprite = walkLeftSprite
	if movingDirection.y == 1:
		walkDownSprite.visible = true
		lastWalkSprite = walkDownSprite
	if movingDirection.y == -1:
		walkUpSprite.visible = true
		lastWalkSprite = walkUpSprite
		
func request_square():
	if !tile_map.request_square(virtualPosition):
		self.movingDirection = Vector2()
		self.virtualPosition = self.position
		
func move_delta(_delta):
	var motion = Vector2()
	motion = movingDirection * MOTION_SPEED * _delta

	if motion:
		#warning-ignore:return_value_discarded
		translate(motion)
		
func reachedVirtualPosition():
	if movingDirection.x == 1:
		if position.x >= virtualPosition.x:
			return true
		return false
	if movingDirection.x == -1:
		if position.x <= virtualPosition.x:
			return true
		return false
	if movingDirection.y == 1:
		if position.y >= virtualPosition.y:
			return true
		return false
	if movingDirection.y == -1:
		if position.y <= virtualPosition.y:
			return true
		return false

func stopMovingReached():
	self.movingDirection = Vector2()
	self.position = self.virtualPosition
	
func move_along_path(_delta):
	var distance = MOTION_SPEED * _delta
	var last_point = position
	if virtualPosition != position && virtualPosition != point_path[0]:
		var distance_between_points = position.distance_to(virtualPosition)
		var direction_to = position.direction_to(virtualPosition)
		var diag_factor = get_diag_factor(direction_to)
		if distance <= distance_between_points:
			self.position = self.position + (direction_to * distance * diag_factor)
			return
		self.position = virtualPosition
		return
	while point_path.size():
		var distance_between_points = last_point.distance_to(point_path[0])
		var direction_to = last_point.direction_to(point_path[0])
		var diag_factor = get_diag_factor(direction_to)
		# The position to move to falls between two points.
		if distance <= distance_between_points:
			self.virtualPosition = point_path[0]
			self.movingDirection = direction_to
			self.position = last_point + (direction_to * distance * diag_factor)
			return
		# The position is past the end of the segment.
		distance -= distance_between_points
		last_point = point_path[0]
		point_path.remove(0)
	# The character reached the end of the path.
	self.position = last_point
	self.point_path = null
	
func get_diag_factor(direction):
	var diag_factor = 1
	if abs(direction[0]) != 1 && abs(direction[1]) != 1:
		diag_factor = 0.75
	return diag_factor
	
func set_point_path(touch_pos):
	var fromPoint = tile_map.astar.get_closest_point(self.position)
	var target_pos
	if is_network_master():
		target_pos = gamestate.get_player_clicked(get_name())
	elif get_tree().get_network_unique_id() == int(get_name()):
		target_pos = touch_pos if touch_pos else get_global_mouse_position()
	if !tile_map.request_square(target_pos):
		return
	var toPoint = tile_map.astar.get_closest_point(target_pos)
	point_path = tile_map.astar.get_point_path(fromPoint, toPoint)
	point_path.remove(0)
	if is_network_master():
		gamestate.set_player_point_path(get_name(), self.point_path)

