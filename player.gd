extends Node2D

@export
var device: int = -1
@export
var movespeed := 700

func _draw() -> void:
    draw_circle(position, 20, Color.WEB_GREEN)


func _process(delta: float) -> void:
    var dir = Vector2(1, 0) * MultiplayerInput.get_axis(device, "ui_left", "ui_right")
    dir.y += MultiplayerInput.get_axis(device, "ui_up", "ui_down")

    position += dir * delta * movespeed
