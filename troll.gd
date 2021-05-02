extends Node2D

const MOTION_SPEED = 64 # Pixels/second.
const TILE_SIZE = 32
var virtualPosition = position
var movingDirection = Vector2(0, 0)
var lastWalkSprite = null
var walkDownSprite = null
var walkLeftSprite = null
var walkUpSprite = null
var walkRightSprite = null

var tile_map
var point_path

func _ready():
	walkDownSprite = get_node("WalkDown")
	walkLeftSprite = get_node("WalkLeft")
	walkUpSprite = get_node("WalkUp")
	walkRightSprite = get_node("WalkRight")
	lastWalkSprite = walkDownSprite
	tile_map = $"../../TileMap"
	if get_tree().get_network_unique_id() == int(get_name()):
		$Controls.show()
		$Camera2D.current = true

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

func _process(_delta):
	if is_network_master():
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
			
		if reachedVirtualPosition() && movingDirection:
			stopMovingReached()
		
		if reachedVirtualPosition():
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
		move_delta(_delta)
		gamestate.set_player_position(get_name(), self.position)
		gamestate.set_player_moving_direction(get_name(), self.movingDirection)
		gamestate.set_player_virtual_pos(get_name(), self.virtualPosition)
			
	elif get_tree().get_network_unique_id() == int(get_name()):
		move_delta(_delta)
	else:
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
	set_sprite_direction()
	if motion:
		#warning-ignore:return_value_discarded
		translate(motion)
