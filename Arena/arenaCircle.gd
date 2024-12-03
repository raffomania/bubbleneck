extends Node2D


var radius = 0
var center = Vector2(0, 0)
@export var color: Color
@export var background_color: Color

func _ready() -> void:
    var viewport = get_viewport_rect()

    global_position.x = viewport.size.x / 2
    global_position.y = viewport.size.y / 2
    var padding_percent = 3
    radius = (min(viewport.size.x, viewport.size.y) / 2) * (100 - padding_percent) / 100

func _draw() -> void:
    var viewport = get_viewport_rect()
    draw_rect(Rect2(-viewport.size / 2, viewport.size), background_color)
    draw_circle(Vector2(0, 0), radius, color, 1, -1, true)


func _process(_delta: float) -> void:
    var viewport = get_viewport_rect()

    center.x = viewport.size.x / 2
    center.y = viewport.size.y / 2
    for player: Node2D in get_tree().get_nodes_in_group('players'):
       var dist = player.global_position.distance_to(center)
       if (!player.dead and dist > radius - player.radius):
           player.position -= 0.01 * (player.position - center)

    for node: Node2D in get_tree().get_nodes_in_group('weapons'):
       var weapon = node as Weapon
       var dist = weapon.global_position.distance_to(center)
       if (weapon.is_throwing and dist > radius - 10):
           # This is to prevent the weapon being stuck on throw when the player is on the edge of the arena.
           # Stick only if arena center is below line orthogonal to weapon throwing direction.
           var a = weapon.position - (100 * Vector2.RIGHT.rotated(weapon.rotation).rotated(PI/2))
           var b = weapon.position + (100 * Vector2.RIGHT.rotated(weapon.rotation).rotated(PI/2))
           if (b-a).cross(position-a) > 0:
               weapon.stick()
