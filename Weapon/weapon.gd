extends Area2D

@export
var throw_distance := 0.0

@export
var dash_curve: Curve

@export
var time_factor := 1.0

@export
var throw_range_factor := 1.0

var time := 0.0
var is_throwing := false
var dir

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    area_entered.connect(_on_area_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

    if is_throwing:
        time += delta * time_factor
        var curve_value = dash_curve.sample(time)
        throw_distance = curve_value * throw_range_factor
        global_position += dir * delta * throw_distance

    if time > 1.0:
        is_throwing = false
        time = 0


func throw(direction_vector : Vector2) -> void:
    is_throwing = true
    dir = direction_vector

func _on_area_entered(area) -> void:
    if time <= 1 and time > 0 and area.has_method("kill"):
        area.kill()
