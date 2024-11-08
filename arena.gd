extends Node2D


var radius = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    var viewport = get_viewport_rect()

    print('was', viewport.size)
    global_position.x = viewport.size.x / 2
    global_position.y = viewport.size.y / 2
    radius = min(viewport.size.x, viewport.size.y)
    print('lol', position)

func _draw() -> void:
    draw_circle(Vector2(0, 0), radius/2, Color.BISQUE, 1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass
