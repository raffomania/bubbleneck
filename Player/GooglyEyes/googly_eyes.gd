extends Node2D

class_name GogglyEyes

# the time factor variable speeds up the googleronies movement, if increased
@export
var time_factor := 1
# this variable always grows
var eternal_time_variable := 0.0

var raising = false

func _ready() -> void:
    modulate = Color(1, 1, 1, 0.7)

func _process(delta: float) -> void:
    eternal_time_variable += delta

func set_player_direction(dir: Vector2, delta: float) -> void:
    var strength = dir.length()
    $LeftOuter/LeftInner.position.y = strength * delta * 5000
    $RightOuter/RightInner.position.y = strength * delta * 5000

func walking_animation() -> void:
    $LeftOuter.position.y -= sin(eternal_time_variable * time_factor) * 0.5
    $RightOuter.position.y += sin(eternal_time_variable * time_factor) * 0.5
    
func raise_eye() -> void:
    if raising:
        return
    raising = true
    var prevL = ($LeftOuter as Node2D).scale.y
    var prevR = ($RightOuter as Node2D).scale.y
    ($RightOuter as Node2D).scale.y *= 2.0
    ($LeftOuter as Node2D).scale.y *= 2.0
    await get_tree().create_timer(0.2).timeout
    ($RightOuter as Node2D).scale.y = prevL
    ($LeftOuter as Node2D).scale.y = prevR
    
    raising = false

func kill():
    visible = false

func respawn():
    visible = true

