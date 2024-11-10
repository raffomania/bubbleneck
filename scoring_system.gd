extends Node2D


var scores: Dictionary

var score_text = preload("res://Scoring/score_text.tscn")

var childs = {}

var colors = {
    -2: 'Cyan',
    -1: 'Orange',
    0: 'Purple',
    1: 'Pink',
    2: 'Green',
    3: 'Cyan',
}


func _ready() -> void:
    scores = {}

func init_scores() -> void:
    for key in childs.keys():
        remove_child(childs[key])
    for node in get_tree().get_nodes_in_group('players'):
        var player = node as Player
        if !scores.keys().has(player.device):
            scores[player.device] = 0
        var score = score_text.instantiate()
        var text = score as RichTextLabel
        var colorname = colors[player.device]
        text.text = 'Player %s:   %s \n' % [colorname, scores[player.device]]
        text.global_position = Vector2(50, 50 * (player.device + 3))
        text.modulate = player.player_color
        childs[player.device] = score
        add_child(score)


func increase_score(player):
    if scores.keys().has(player.device):
        scores[player.device] += 1
    else:
        scores[player.device] = 1
    print(scores)
    init_scores()
