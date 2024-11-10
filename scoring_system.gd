extends Node2D


var scores: Dictionary

var score_text = preload("res://Scoring/score_text.tscn")

var childs = {}

var colors = {
    0: 'Cyan',
    1: 'Orange',
    2: 'Purple',
    3: 'Pink',
    4: 'Green',
    5: 'Yellow',
    6: 'Cyan',
    7: 'Orange',
    8: 'Purple',
}


func _ready() -> void:
    scores = {}

func init_scores() -> void:
    # for key in childs.keys():
    #     remove_child(childs[key])
    #     childs[key].queue_free()

    for node in get_tree().get_nodes_in_group('players'):
        var player = node as Player
        var index = player.device + 2
        if !scores.keys().has(index):
            scores[index] = 0
        var score
        if childs.keys().has(index):
            score = childs[index]
        else:
            score = score_text.instantiate()
        var text = score as RichTextLabel
        var colorname = colors[index]
        text.text = 'Player %s:   %s \n' % [colorname, scores[index]]
        text.global_position = Vector2(0, 50 * (index + 3))
        text.modulate = player.player_color
        childs[index] = score
        add_child(score)
        queue_redraw()


func increase_score(player):
    var index = player.device + 2
    if scores.keys().has(index):
        scores[index] += 1
    else:
        scores[index] = 1
    init_scores()
