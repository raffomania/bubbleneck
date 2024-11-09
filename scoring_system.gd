extends Node2D


var scores: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    scores = {}


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass

func increase_score(player):
    if scores.keys().has(player.device):
        scores[player.device] += 1
    else:
        scores[player.device] = 1
    print(scores)
