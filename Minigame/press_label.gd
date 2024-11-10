extends Sprite2D

class_name PressLabel

var textures = {
 "left": preload("res://Minigame/keyboard_arrow_left_outline.png"),
 "right": preload("res://Minigame/keyboard_arrow_right_outline.png"),
 "up": preload("res://Minigame/keyboard_arrow_up_outline.png"),
 "down": preload("res://Minigame/keyboard_arrow_down_outline.png"),
}

var pressed_textures = {
 "left": preload("res://Minigame/keyboard_arrow_left.png"),
 "right": preload("res://Minigame/keyboard_arrow_right.png"),
 "up": preload("res://Minigame/keyboard_arrow_up.png"),
 "down": preload("res://Minigame/keyboard_arrow_down.png"),
}

var is_pressed := false
var dir: String

func set_direction(new_dir: String):
    dir = new_dir
    update_texture()

func set_color(color: Color):
    self_modulate = color
    $Background.self_modulate = color.lightened(0.8)

func set_pressed(new_pressed: bool):
    is_pressed = new_pressed
    update_texture()
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2(0.95, 1.3), 0.05)
    tween.parallel().tween_property(self, "rotation", PI / 20, 0.05)
    await tween.finished
    var reset_tween = create_tween().parallel()
    reset_tween.tween_property(self, "scale", Vector2(1, 1), 0.1)
    reset_tween.tween_property(self, "rotation", 0, 0.1)

func vanish_animation():
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2(0.05, 1.5), 0.1)
    tween.parallel().tween_property(self, "rotation", PI / 20, 0.1)
    await tween.finished


func update_texture():
    if is_pressed:
        self.texture = pressed_textures[dir]
    else:
        self.texture = textures[dir]
