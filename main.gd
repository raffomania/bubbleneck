extends Node2D

var main_scene = preload("res://main.tscn")

func _ready() -> void:
    DebugMenu.style = DebugMenu.Style.VISIBLE_DETAILED

func restart():
    get_tree().root.add_child.call_deferred(main_scene.instantiate())
    queue_free()
