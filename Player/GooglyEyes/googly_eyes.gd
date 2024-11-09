extends Node2D


func _ready() -> void:
    modulate = Color(1, 1, 1, 0.7)


func set_player_direction(dir: Vector2, delta: float) -> void:
    var strength = dir.length()
    $LeftOuter/LeftInner.position.y = strength * delta * 5000
    $RightOuter/RightInner.position.y = strength * delta * 5000

func kill():
    visible = false

func respawn():
    visible = true

