extends Node2D


func _draw() -> void:
    draw_circle(position, 20, Color.WEB_GREEN)


func _process(delta: float) -> void:
    var dir = Vector2(1, 0) * Input.get_axis("ui_left", "ui_right")
    dir.y += Input.get_axis("ui_up", "ui_down")

    print(dir)
    position += dir * delta * 700
