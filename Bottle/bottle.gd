extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  # center the bottle
  var viewport = get_viewport_rect()
  # position.x = viewport.size.x / 2
  position.x = viewport.size.x / 2
  position.y = viewport.size.y / 2


