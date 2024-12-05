extends Area2D

class_name Shield
func _ready() -> void:
    area_entered.connect(_on_area_entered)

    # block all weapons except your own weapon
func _on_area_entered(area):
    var is_weapon = is_instance_of(area, WeaponHitbox)
    var is_my_weapon = is_weapon and is_instance_valid(area.get_parent().weapon_owner) and area.get_parent().weapon_owner == get_parent()
    var weapon_thrown = is_weapon and area.get_parent().is_throwing
    if not is_weapon or is_my_weapon or not weapon_thrown:
        return

    var weapon = area.get_parent()
    var pos = weapon.global_position
    # drop weapon to ground without hurting anyone
    weapon.is_throwing  = false
    weapon.end_throw()
    weapon.set_global_position(pos)
    weapon.bounce_back()


func remove():
    area_entered.disconnect(_on_area_entered)

