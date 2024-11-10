extends Node2D

var splotch_scene = preload("res://Stage/splotches.tscn")

func _ready() -> void:
    Globals.player_killed.connect(player_killed)

func player_killed(player: Player):
    var color: Color = Color(player.player_color).darkened(0.3)
    color.a = 0.5
    var splotches = splotch_scene.instantiate()
    splotches.color = color
    splotches.global_position = Vector2(player.global_position)
    add_child(splotches)