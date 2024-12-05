extends Node

class State:
    pass

class RoundRunning:
    extends State

    var sudden_death_timeout := 40.0
    var sudden_death_countdown := sudden_death_timeout

class SuddenDeath:
    extends State

class RoundOver:
    extends State

var state: State = RoundRunning.new():
    set(val):
        state = val
        state_changed.emit()

@warning_ignore("unused_signal")
signal state_changed()

@warning_ignore("unused_signal")
signal player_killed(player: Player)

@warning_ignore("unused_signal")
signal kill_streak_changed(player: Player)