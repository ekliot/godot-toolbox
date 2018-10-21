"""
filename: state.gd
"""

extends Node

signal state_enter
signal state_leave

var ID = '_' setget ,get_state_id
var active = false setget ,is_active

func enter(fsm, last_state=null, state_data={}):
  _on_enter(fsm, last_state, state_data)
  if not active:
    emit_signal('state_enter')
    active = true

func leave(fsm):
  _on_leave(fsm)
  if active:
    emit_signal('state_leave')
    active = false

"""
=== OVERRIDEABLES
    These are methods that extending classes are meant to override
    Almost all of these are called by the StateMachine host
"""

func _on_enter(fsm, state_data={}, last_state=null):
  """
  Logic to execute when entering the state
  Returns the state ID of the next state to change to, or null if no change needed
  fsm :- the StateMachine host
  state_data :- any relevant data this State may expect upon entering
  last_state :- the last State the host was in
  """
  return null

func _on_leave(fsm):
  """
  Logic to execute when leaving the state
  Returns the state ID of the next state to change to, or null if no change needed
  fsm :- the StateMachine host
  """
  return null

func _update(fsm, delta):
  """
  A wrapper for Node._process(), called by the StateMachine host only when this State is active
  Returns the state ID of the next state to change to, or null if no change needed
  fsm :- the StateMachine host
  delta :- delta time provided by Node._process()
  """
  return null

func _physics_update(fsm, delta):
  """
  A wrapper for Node._physics_process(), called by the StateMachine host only when this State is active
  Returns the state ID of the next state to change to, or null if no change needed
  fsm :- the StateMachine host
  delta :- delta time provided by Node._process()
  """
  return null

func _parse_input(fsm, ev):
  """
  A wrapper for Node._input(), called by the StateMachine host only when this State is active
  Returns the state ID of the next state to change to, or null if no change needed
  fsm :- the StateMachine host
  ev :- input event provided by Node._input()
  """
  return null

func _parse_unhandled_input(fsm, ev):
  """
  A wrapper for Node._unhandled_input(), called by the StateMachine host only when this State is active
  Returns the state ID of the next state to change to, or null if no change needed
  fsm :- the StateMachine host
  ev :- input event provided by Node._unhandled_input()
  """
  return null

func _on_animation_finished(fsm, ani_name):
  return null

"""
=== GETTERS
"""

func get_state_id():
  return ID

func is_active():
  return active
