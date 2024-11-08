extends Node2D


var radius = 0
var center = Vector2(0, 0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    var viewport = get_viewport_rect()

    global_position.x = viewport.size.x / 2
    global_position.y = viewport.size.y / 2
    radius = min(viewport.size.x, viewport.size.y) / 2

func _draw() -> void:
    draw_circle(Vector2(0, 0), radius, Color.BISQUE, 1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    var viewport = get_viewport_rect()

    center.x = viewport.size.x / 2
    center.y = viewport.size.y / 2
    for player: Node2D in get_tree().get_nodes_in_group('players'):
       var dist = player.position.distance_to(center)
       if (!player.dead and dist > radius - player.radius):
           player.kill()