extends Node

signal state_enter
signal state_leave

var active = false
var ID = '_'

func enter( fsm ):
  _on_enter( fsm )
  if not active:
    emit_signal( 'state_enter' )
    active = true

func leave( fsm ):
  _on_leave( fsm )
  if active:
    emit_signal( 'state_leave' )
    active = false

# ============= #
# OVERRIDEABLES #
# ============= #

func _on_enter( fsm ):
  return

func _on_leave( fsm ):
  return

func _update( fsm, delta ):
  return

func _physics_update( fsm, delta ):
  return

func _parse_input( fsm, ev ):
  return

func _parse_unhandled_input( fsm, ev ):
  return

func _on_animation_finished( fsm, ani_name ):
  return
