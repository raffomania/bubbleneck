extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    area_entered.connect(_on_area_entered)

func _on_area_entered(area) -> void:
    if not is_instance_of(area, Player):
        return
    
    var weapon = get_parent() as Weapon
    weapon.attach_to_player(area)