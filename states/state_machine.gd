"""
filename: state_machine.gd
"""

extends Node

# utility signal, for States that want to connect to the FSM host
signal ready
# emitted after the previous state is left, but before the next state is entered
signal state_change(state_from, state_to)

onready var HOST = get_parent()
var START_STATE = null

var active = null setget ,get_active_state
var states = {}
var state_data = {}

func _ready():
  for state in get_children():
    if state.has_method('get_state_id'):
      states[state.ID] = state
      state_data[state.ID] = {}
  emit_signal('ready')

"""
=== CORE METHODS
"""

func start(start_state_id):
  if start_state_id in states:
    START_STATE = start_state_id
    active = states[start_state_id]
    active.enter(state_data[START_STATE])

func enter(state_to):
  """
  leave the currently active state, and enter a given State node
  if we're already in that state, a state_change signal is not emitted
  """
  if not states.has(state_to):
    return null

  # first, handle our active State
  var state_from = get_active_id()
  if state_from:
    # if we're already in this state...
    if state_from == state_to:
      # tell it to enter itself from itself, but don't emit a state change
      return states[state_to].enter(get_state_data(state_from), state_from)
    else:
      # otherwise, tell it to leave (deactivate)
      get_state(state_from).leave()

  # then, switch over to the next state
  emit_signal('state_change', state_from, state_to)
  var new_state = states[state_to]
  active = new_state
  return new_state.enter(get_state_data(state_to), state_from)

"""
=== STATE WRAPPERS
    These methods are here to wrap typical game loop signals such that only the currently
    active state will handle them
"""

func _input(ev):
  """
  handle input based on the currently active state
  """
  if get_active_state():
    var next_state = get_active_state()._parse_input(ev)
    if next_state:
      enter(next_state)

func _unhandled_input(ev):
  """
  handle input based on the currently active state
  """
  if get_active_state():
    var next_state = get_active_state()._parse_unhandled_input(ev)
    if next_state:
      enter(next_state)

func _process(delta):
  """
  handle game loop based on currently active state
  """
  if get_active_state():
    var next_state = get_active_state()._update(delta)
    if next_state:
      enter(next_state)

func _physics_process(delta):
  """
  handle game physics loop based on currently active state
  """
  if get_active_state():
    var next_state = get_active_state()._physics_update(delta)
    if next_state:
      enter(next_state)

"""
=== GETTERS
"""

func get_active_state():
  return active

func get_active_id():
  if active:
    return get_active_state().ID
  return null

func get_state(id):
  if id in states:
    return states[id]
  return null

func get_state_data(id):
  if id in state_data:
    return state_data[id]
  return null

func set_state_data(id, data):
  if id in state_data:
    state_data[id] = data
  return id in state_data
