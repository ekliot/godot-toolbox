##[ filename: state_machine.gd
A StateMachine class
]##

import
  godot, node, input
import state


gdobj StateMachine of Node:
  var HOST*: Node = nil
  var START_STATE*: string = ""

  var active: State = nil
  var states: Dictionary = new_dictionary()
  var state_data: Dictionary = new_dictionary()

  method init*() =
    # emitted after the previous state is left, but before the next state is entered
    # NIMIFY is there a more elegant way to do this?
    add_user_signal(
      "state_change",
      new_array(to_variant "state_from", to_variant "state_to")
    )

  method ready*() =
    self.HOST = get_parent() as Node

    for child in get_children():
      let state: State = as_object[State](child)
      if not is_nil(state):
        # DEV // BE WARNED, HERE BE TYPING HELL
        #     dict[] sig := `proc `[]=`(self: Dictionary; key, value: Variant)`
        #     thus we need to cast:
        #     - state.ID -> Variant
        let state_id: Variant = to_variant state.ID
        #     - {} -> Variant
        state_data[state_id] = to_variant new_dictionary()
        #     - state -> Variant (since `state` was cast as State from `child: Variant`, we can just use `child`)
        states[state_id] = child
        if state.has_method("set_host"):
          state.set_host(self.HOST)


  ##[
  === CORE METHODS
  ]##

  proc start*(start_state_id: string): void {.gdExport.} =
    ## enters a given starting state if the state has not been started yet

    if has_state(start_state_id) and is_nil active:
      self.START_STATE = start_state_id
      active = get_state(start_state_id)
      active.enter(get_state_data(start_state_id))

  proc enter*(state_to: string): void {.gdExport.} =
    ## leave the currently active state, and enter a given State node
    ## if we're already in that state, a state_change signal is not emitted

    # let state_to: Variant = to_variant state
    if not has_state(state_to):
      # NIMIFY does this return work?
      return

    # first, handle our active State
    let state_from: string = if not is_nil active: active.ID else: ""
    if len(state_from) > 0:
      # if we're already in this state...
      if state_from == state_to:
        # tell it to enter itself from itself, but don't emit a state change
        get_state(state_to).enter(
          get_state_data(state_from), state_from
        )
        # NIMIFY does this return work?
        return
      else:
        # otherwise, tell it to leave (deactivate)
        get_state(state_from).leave()

    # then, switch over to the next state
    emit_signal(
      "state_change",
      to_variant state_from, to_variant state_to
    )
    let new_state: State = get_state(state_to)
    active = new_state

    new_state.enter(get_state_data(state_to), state_from)


  ##[
  === STATE WRAPPERS
      These methods are here to wrap typical game loop signals such that only the currently
      active state will handle them
  ]##

  method input*(ev: InputEvent) =
    ## handle input based on the currently active state

    if not is_nil active:
      var next_state = active.on_input(ev)
      if len(next_state) > 0 and has_state(next_state):
        enter(next_state)

  method unhandled_input*(ev: InputEvent) =
    ## handle input based on the currently active state

    if not is_nil active:
      var next_state = active.on_unhandled_input(ev)
      if len(next_state) > 0 and has_state(next_state):
        enter(next_state)

  method process*(delta: float) =
    ## handle game loop based on currently active state

    if not is_nil active:
      var next_state = active.on_process(delta)
      if len(next_state) > 0 and has_state(next_state):
        enter(next_state)

  method physics_process*(delta: float) =
    ## handle game physics loop based on currently active state

    if not is_nil active:
      var next_state = active.on_physics_process(delta)
      if len(next_state) > 0 and has_state(next_state):
        enter(next_state)


  ##[
  === GETTERS
  ]##

  proc has_state*(id: string): bool {.gdExport.} =
    return to_variant(id) in states.keys

  proc get_state*(id: string): State {.gdExport.} =
    if has_state(id): as_object[State](states[id]) else: nil

  proc get_state_data*(id: string): Dictionary {.gdExport.} =
    if has_state(id): as_dictionary state_data[id] else: nil

  proc set_state_data*(id: string, data: Dictionary): void {.gdExport.} =
    if has_state(id):
      var current: Dictionary = get_state_data(id)
      for k in data.keys():
        current[k] = data[k]
