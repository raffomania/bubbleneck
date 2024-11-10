extends Node2D

@export
var color: Color

func _ready() -> void:
    queue_redraw()

func _draw():
    for i in range(0, 20):
        var offset = Vector2(randf_range(-1, 1) * 50, randf_range(-1, 1) * 50)
        var radius = randf_range(2, 26)

        draw_circle(offset, radius, color, true, -1, true)
