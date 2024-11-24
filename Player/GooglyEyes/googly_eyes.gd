extends Node2D

class_name GogglyEyes

# the time factor variable speeds up the googleronies movement, if increased
@export
var time_factor := 1000

var raising = false
var blinking = false

@onready
var left_outer : GooglyEye = $LeftOuter

@onready
var right_outer : GooglyEye= $RightOuter

func set_player_direction(dir: Vector2, delta: float) -> void:
    var strength = dir.length()
    $LeftOuter/LeftInner.position.y = strength * delta * 5000
    $RightOuter/RightInner.position.y = strength * delta * 5000

func reset() -> void:
    left_outer.reset()
    right_outer.reset()

func walking_animation() -> void:
    left_outer.position.y = sin(Time.get_ticks_msec() * time_factor) 
    right_outer.position.y = -sin(Time.get_ticks_msec() * time_factor) 
    
func raise_eye() -> void:
    left_outer.raise_eye()
    right_outer.raise_eye()

func blink(duration: float) -> void:
    if blinking:
        return
    blinking = true
    var prevL = ($LeftOuter as Node2D).scale.y
    var prevR = ($RightOuter as Node2D).scale.y
    ($RightOuter as Node2D).scale.y = 0.0
    ($LeftOuter as Node2D).scale.y = 0.0
    await get_tree().create_timer(duration).timeout
    ($RightOuter as Node2D).scale.y = prevL
    ($LeftOuter as Node2D).scale.y = prevR
    blinking = false

func kill():
    visible = false

func respawn():
    visible = true

