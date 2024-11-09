extends Node2D

# the time factor variable speeds up the googleronies movement, if increased
@export
var time_factor := 1
# this variable always grows
var eternal_time_variable := 0.0

func _ready() -> void:
    modulate = Color(1, 1, 1, 0.7)

func _process(delta: float) -> void:
    eternal_time_variable += delta

func set_player_direction(dir: Vector2, delta: float) -> void:
    var strength = dir.length()
    $LeftOuter/LeftInner.position.y = strength * delta * 5000
    $RightOuter/RightInner.position.y = strength * delta * 5000

func walking_animation() -> void:
    $LeftOuter.position.y -= sin(eternal_time_variable * time_factor) * 0.1
    $RightOuter.position.y += sin(eternal_time_variable * time_factor) * 0.1

func kill():
    visible = false

func respawn():
    visible = true

