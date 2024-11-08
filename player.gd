extends Sprite2D


func _ready() -> void:
    pass # Replace with function body.


func _process(delta: float) -> void:
    var dir = Vector2(1, 0) * Input.get_axis("ui_left", "ui_right")
    dir.y += Input.get_axis("ui_up", "ui_down")

    print(dir)
    position += dir * delta * 200
