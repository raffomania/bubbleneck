extends Node2D

var kill_queue = []

func _ready() -> void:
    Globals.player_killed.connect(player_killed)

func player_killed(player: Player):
    kill_queue.append(player)
    queue_redraw()

func _draw():
    for player in kill_queue:
        var color: Color = player.player_color.darkened(0.3)
        color.a = 0.5
        for i in range(0, 20):
            var offset = Vector2(randf_range(-1, 1) * 50, randf_range(-1, 1) * 50)
            var radius = randf_range(2, 26)

            draw_circle(player.global_position + offset, radius, color, true)

    kill_queue = []