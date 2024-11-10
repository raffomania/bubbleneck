extends Area2D

class_name WeaponHitbox

func _ready() -> void:
    area_entered.connect(_on_area_entered)

func check_now():
    for area in get_overlapping_areas():
        _on_area_entered(area)


func _on_area_entered(area) -> void:
    if not is_instance_of(area, Player):
        return
    
    var weapon = get_parent() as Weapon
    weapon.hit_player(area)