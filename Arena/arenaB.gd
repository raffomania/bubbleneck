extends Node2D

@onready
var arena_offset := 5.0

var radius = 0
var center = Vector2(0, 0)
var viewport : Rect2
var arena_size : Vector2



func _ready() -> void:
    viewport = get_viewport_rect()

    global_position.x = viewport.size.x / 2
    global_position.y = viewport.size.y / 2
    radius = min(viewport.size.x, viewport.size.y) / 2
    arena_size = Vector2(Vector2(viewport.size.x - 10.0, viewport.size.y - 10.0))

func _draw() -> void:
    draw_rect(Rect2(Vector2(-viewport.size.x / 2.0 + arena_offset, -viewport.size.y / 2.0 + arena_offset), arena_size), Color(58 / 256.0, 81 / 256.0, 120 / 256.0))


func is_point_outside_rect(point) -> bool:
    if (point.x >= arena_size.x + arena_offset or point.x <= arena_offset or point.y >= arena_size.y + arena_offset or point.y <= arena_offset):
        return true
    else:
        return false

func _process(_delta: float) -> void:
    var viewport = get_viewport_rect()

    center.x = viewport.size.x / 2
    center.y = viewport.size.y / 2
    for player: Node2D in get_tree().get_nodes_in_group('players'):
       if (!player.dead and is_point_outside_rect(player.global_position)):
           player.global_position -= 0.01 * (player.global_position - center)

    for node: Node2D in get_tree().get_nodes_in_group('weapons'):
       var weapon = node as Weapon
       if (weapon.is_throwing and is_point_outside_rect(weapon.global_position)):
           weapon.stick()
