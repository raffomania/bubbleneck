extends Node2D


var radius = 0
var center = Vector2(0, 0)

func _ready() -> void:
    var viewport = get_viewport_rect()

    global_position.x = viewport.size.x / 2
    global_position.y = viewport.size.y / 2
    radius = min(viewport.size.x, viewport.size.y) / 2

func _draw() -> void:
    draw_circle(Vector2(0, 0), radius, Color(58 / 256.0, 81 / 256.0, 120 / 256.0), 1)


func _process(_delta: float) -> void:
    var viewport = get_viewport_rect()

    center.x = viewport.size.x / 2
    center.y = viewport.size.y / 2
    for player: Node2D in get_tree().get_nodes_in_group('players'):
       var dist = player.global_position.distance_to(center)
       if (!player.dead and dist > radius - player.radius):
           player.kill()

    for node: Node2D in get_tree().get_nodes_in_group('weapons'):
       var weapon = node as Weapon
       var dist = weapon.global_position.distance_to(center)
       if (weapon.is_throwing and dist > radius - 10):
           weapon.stick()