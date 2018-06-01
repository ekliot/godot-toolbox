extends Node

# emitted after the stack changes, and the previous state
# is left, but before the next state is entered
signal state_change # state_from, state_to

onready var host = get_parent()
var START_STATE = null
var active = null
var states = {}

var state_data = {}

func _ready():
  for state in get_children():
    states[state.ID] = state
    state_data[state.ID] = {}

func start( start_state ):
  if not states.has( state_to ):
    return 1 / 0

  START_STATE = start_state
  active = states[start_state]
  active.enter( self )

# enter a given State node
func enter( state_to ):
  if not states.has( state_to ):
    return null

  # first, handle our current states
  var state_from = get_active().get_id()
  if state_from:
    # if we're already in this state...
    if state_from == state_to:
      # tell it to enter itself but don't modify the stack
      return cur_state.enter( self )
    else:
      # otherwise, tell it to leave (deactivate)
      cur_state.leave( self )

  # then, switch over to the next state
  emit_signal( 'state_change', state_from, state_to )
  active = state_to
  return states[state_to].enter( self, state_from )

# handle input
func _input( ev ):
  if get_active():
    var next_state = get_active()._parse_input( self, ev )
    if next_state:
      enter( next_state )

func _unhandled_input( ev ):
  if get_active():
    var next_state = get_active()._parse_unhandled_input( self, ev )
    if next_state:
      enter( next_state )

func _process( delta ):
  if get_active():
    var next_state = get_active()._update( self, delta )
    if next_state:
      enter( next_state )

func _physics_process( delta ):
  if get_active():
    var next_state = get_active()._physics_update( self, delta )
    if next_state:
      enter( next_state )

func get_active():
  return active

func get_active_id():
  if active:
    return active.get_id()
  return null

func get_state_data( id ):
  if state_data.has( id ):
    return state_data[id]

  return null

func set_state_data( id, data ):
  if state_data.has( id ):
    state_data[id] = data
    return true

  return false
