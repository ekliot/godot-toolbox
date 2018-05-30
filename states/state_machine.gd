extends Node

signal state_change

const OP_POP = '~'

onready var host = get_parent()
var states = {}
var stack = []

var state_data = {}

func _ready():
  for state in get_children():
    states[state.ID] = state
    state_data[state.ID] = {}

# enter a given State node
# returns the new size of the stack
func enter( state ):
  # first, handle our current states

  if state == OP_POP:
    leave()
    return stack.size()

  if not states.has( state ):
    return null

  var cur_state = get_active()
  if cur_state:
    # if we're already in this state...
    if cur_state.ID == state:
      # tell it to enter itself but don't modify the stack
      cur_state.enter( self )
      return stack.size()
    else:
      # otherwise, tell it to leave (deactivate)
      cur_state.leave( self )

  # then, switch over to the next state

  push( state )
  emit_signal( 'state_change' )

  states[state].enter( self )

  return stack.size()

# push a given State to the stack
# this is here so that "fallback" States can be pushed preceding another State
# returns the new size of the stack
func push( state ):
  if not states.has( state ):
    return null

  stack.push_front( states[state] )
  return stack.size()

# leaves the current state and activates the previous one
# returns the left state
func leave():
  var state = stack.pop_front()
  emit_signal( 'state_change' )

  state.leave( self )

  if get_active():
    get_active().enter( self )

  return state

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
  if stack.size() > 0:
    return stack[0]
  return null

func clear( remaining=0 ):
  emit_signal( 'state_change' )

  var cleared = []

  while stack.size() > remaining:
    var state = stack.pop_front()
    state.leave( self )
    cleared.push( state )

  return cleared

func get_state_data( id ):
  if state_data.has( id ):
    return state_data[id]

  return null

func set_state_data( id, data ):
  if state_date.has( id ):
    state_data[id] = data
    return true

  return false
