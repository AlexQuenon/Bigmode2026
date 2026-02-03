extends CharacterBody2D


# TODO: const collection to resource?

# TODO: Minimum ground accel?  Move to zero if drag large? Fixed acceleration to 0?

const GROUND_MAX_SPEED = 100.0
const GROUND_ACCELERATION = 2000.0
const GROUND_DRAG = 0.25

const AIR_MAX_SPEED = 500.0
const AIR_ACCELERATION = 55.0
const AIR_DRAG = 0.01

const SLIDE_MAX_ANGLE = 2 * PI * 50.0 / 360.0

var global := Vector2.ZERO  # TODO: TEMP
func _ready():
	set_motion_mode(CharacterBody2D.MOTION_MODE_FLOATING)
	set_wall_min_slide_angle(SLIDE_MAX_ANGLE)
	# TODO: TEMP
	global = get_global_position()

# TODO: TEMP
func _process(_delta):
	if Input.is_action_just_pressed("Reset"):
		global_position = global

func _physics_process(delta):
	var direction = Input.get_vector("Left", "Right", "Up", "Down")

	if is_on_wall() and get_wall_normal().dot(Vector2.UP) > 0:
		# Ground accel
		var normal = get_wall_normal()
		var acceleration = get_gravity().slide(normal)
		if Input.is_action_pressed("Slide"):
			velocity += acceleration * delta
		else:
			acceleration -= velocity * GROUND_DRAG
			direction = direction * Vector2.RIGHT  # TODO: evaluate if this feels good with 2d input
			if direction == Vector2.ZERO:
				velocity += acceleration * delta
				velocity = velocity.move_toward(Vector2.ZERO, GROUND_ACCELERATION * get_wall_normal().dot(Vector2.UP) * delta)
			else:
				var input_acceleration = direction.slide(normal) * GROUND_ACCELERATION
				_set_velocity_with_input_constraints(acceleration, input_acceleration, GROUND_MAX_SPEED)
	else:
		# Air accel
		var acceleration = get_gravity()
		acceleration -= velocity * AIR_DRAG
		var input_acceleration = direction * AIR_ACCELERATION
		_set_velocity_with_input_constraints(acceleration, input_acceleration, AIR_MAX_SPEED)

	move_and_slide()
	if is_on_wall() and velocity.dot(get_wall_normal()):
		velocity = velocity.slide(get_wall_normal())


func _set_velocity_with_input_constraints(
	acceleration: Vector2,
	input_acceleration: Vector2,
	max_speed: float
):
	var delta = get_physics_process_delta_time()
	var default_velocity = velocity + acceleration * delta
	var altered_velocity = default_velocity + input_acceleration * delta
	if altered_velocity.length() > max_speed and altered_velocity.length() > default_velocity.length():
		velocity = default_velocity
	else:
		velocity = altered_velocity
