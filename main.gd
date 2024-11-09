extends Node2D

var main_scene = preload("res://main.tscn")
var stages = [
    preload("res://Stage/StageA.tscn")
]
var current_stage

@onready var spawner = $PlayerSpawner
@onready var camera = $Camera2D

func _ready() -> void:
    DebugMenu.style = DebugMenu.Style.VISIBLE_DETAILED
    next_stage()

func next_stage():
    if is_instance_valid(current_stage):
        current_stage.queue_free()
        
    spawner.remove_all_players()

    var stage_scene = stages[randi() % stages.size()]
    current_stage = stage_scene.instantiate()
    
    add_child(current_stage)
    camera.zoom = Vector2.ONE
    spawner.bottle = current_stage.find_child("Bottle")
    spawner.spawn_all_players.call_deferred()
