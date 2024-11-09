extends Node2D


var scores: Dictionary


func _ready() -> void:
    scores = {}

func init_scores() -> void:
    for player in get_tree().get_nodes_in_group('players'):
        if !scores.keys().has(player.device):
            scores[player.device] = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    var text = 'Score \n'
    for key in scores.keys():
        text += 'Player %s: %s \n' % [key + 2, scores[key]]
    $ScoreText.text = text
    $ScoreText.global_position = Vector2(20, 20)

func increase_score(player):
    if scores.keys().has(player.device):
        scores[player.device] += 1
    else:
        scores[player.device] = 1
    print(scores)
