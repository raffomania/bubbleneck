extends Control

class State:
    pass

class ShowingText:
    extends State

class Idle:
    extends State

var state: State = Idle.new()

signal state_changed

@onready var label = $Label
@onready var animation_player = $AnimationPlayer
@onready var particles_left = $ParticlesLeft
@onready var particles_right = $ParticlesRight

func _ready() -> void:
    label.visible = false
    particles_left.emitting = false
    particles_right.emitting = false

    show_text("Orange Player is unstoppable!", Color.HONEYDEW)

    Globals.kill_streak_changed.connect(_kill_streak_changed)

func _kill_streak_changed(player: Player):
    if player.kill_streak >= 4:
        var color_desc = player.get_color_description()
        show_text("%s is unstoppable!" % color_desc, player.player_color)

func idle():
    particles_left.emitting = false
    particles_right.emitting = false
    if label.visible == true:
        $AnimationPlayer.play_backwards("Appear")
        await $AnimationPlayer.animation_finished
        label.visible = false
    state = Idle.new()
    state_changed.emit()


func show_text(text: String, color: Color):
    while state is ShowingText:
        await state_changed

    state = ShowingText.new()
    label.text = text
    label.add_theme_color_override("font_color", color)
    label.add_theme_color_override("font_outline_color", color.darkened(.5))
    # The material is the same for both particle systems so we only set the color once
    particles_left.process_material.color = color
    particles_left.emitting = true
    particles_right.emitting = true
    # Wait for particles to appear
    await get_tree().create_timer(0.25).timeout
    animation_player.play("Appear")
    await get_tree().create_timer(2.0).timeout
    idle()
