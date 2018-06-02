# state_machine.gd

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
  if not states.has( start_state ):
    return null

  START_STATE = start_state
  active = states[start_state]
  active.enter( self, null, get_state_data( START_STATE ) )

# enter a given State node
func enter( state_to ):
  if not states.has( state_to ):
    return null

  # first, handle our current states
  var state_from = get_active_id()
  if state_from:
    # if we're already in this state...
    if state_from == state_to:
      # tell it to enter itself but don't modify the stack
      return states[state_from].enter( self, null, get_state_data( state_from ) )
    else:
      # otherwise, tell it to leave (deactivate)
      get_state( state_from ).leave( self )

  # then, switch over to the next state
  emit_signal( 'state_change', state_from, state_to )
  active = states[state_to]
  return get_active().enter( self, state_from, get_state_data( state_to ) )

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

func get_state( id ):
  if states.has( id ):
    return states[id]
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
