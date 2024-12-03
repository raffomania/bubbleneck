extends Node2D

class_name KillStreakLabel

@export
var duration := 1

var color := Color.HOT_PINK
var text := "[center]X"


func init() -> void:
    var tween = create_tween()
    tween.tween_property(self, "global_position:y", global_position.y - 100, duration)
    tween.parallel().tween_property($RichTextLabel, "modulate:a", 0, duration)
    tween.set_trans(Tween.TRANS_SPRING)
    await tween.finished
    queue_free()

func set_text(new_text: String) -> void:
    text = new_text
    $RichTextLabel.text = text

func set_color(new_color: Color) -> void:
    color = new_color
    $RichTextLabel.modulate = color

