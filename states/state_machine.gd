extends Node

signal state_change

onready var host = get_parent()
var stack = []

var states = {}

func _ready():
  for state in get_children():
    print( state )
    states[state.ID] = state

# enter a given State node
# returns the new size of the stack
func enter( state ):
  # first, handle our current state

  if state == '~':
    print( 'returning to last state' )
    leave()
    return stack.size()

  print( 'entering %s ' % [ state ] )

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

# push a given State node to the stack
# this is here so that "fallback" States can be pushed preceding another State
# returns the new size of the stack
func push( state ):
  if not states.has( state ):
    return null

  print( 'pushing on %s' % [ state ] )

  stack.push_front( states[state] )
  return stack.size()

# leaves the current state and activates the previous one
# returns the left state
func leave():
  var state = stack.pop_front()
  emit_signal( 'state_change' )

  print( "leaving state %s" % [state.ID] )
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
