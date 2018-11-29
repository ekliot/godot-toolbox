##[ filename: state_machine.gd
A StateMachine class
]##

import
  godot, input

import state

gdobj StateMachine of Node:
  var HOST*: Variant = nil

  var active: State = nil
  var states: Dictionary = new_dictionary()
  var state_data: Dictionary = new_dictionary()

  method init*() =
    # emitted after the previous state is left, but before the next state is entered
    add_user_signal("state_change", "state_from", "state_to")

  method ready*() =
    self.HOST = get_parent()

    for state in get_children():
      if state of State:
        states[state.ID] = (state as State)
        state_data[state.ID] = new_dictionary()
        if state.has_method("set_host"):
          state.set_host(self.HOST)


  ##[
  === CORE METHODS
  ]##

  proc start*(start_state_id: string): void {.gdExport.} =
    ## enters a given starting state if the state has not been started yet
    if is_nil active and states.contains(start_state_id):
      let self.START_STATE: string = start_state_id
      active = states[start_state_id]
      active.enter(state_data[START_STATE])

  proc enter*(state_to: string): void {.gdExport.} =
    ## leave the currently active state, and enter a given State node
    ## if we're already in that state, a state_change signal is not emitted

    if not states.contains(state_to):
      # NIMIFY does this return work?
      return

    # first, handle our active State
    let state_from = if not is_nil active: active.ID else: nil
    if not is_nil state_from:
      # if we're already in this state...
      if state_from == state_to:
        # tell it to enter itself from itself, but don't emit a state change
        states[state_to].enter(
          get_state_data(state_from), state_from
        )
        # NIMIFY does this return work?
        return
      else:
        # otherwise, tell it to leave (deactivate)
        get_state(state_from).leave()

    # then, switch over to the next state
    emit_signal("state_change", state_from, state_to)
    let new_state = states[state_to]
    active = new_state

    discard new_state.enter(get_state_data(state_to), state_from)


  ##[
  === STATE WRAPPERS
      These methods are here to wrap typical game loop signals such that only the currently
      active state will handle them
  ]##

  method input*(ev: InputEvent) =
    ## handle input based on the currently active state

    if not is_nil active:
      var next_state = active.on_input(ev)
      if not is_nil next_state and states.contains(next_state):
        discard enter(next_state)

  method unhandled_input*(ev: InputEvent) =
    ## handle input based on the currently active state

    if not is_nil active:
      var next_state = active.on_unhandled_input(ev)
      if not is_nil next_state and states.contains(next_state):
        discard enter(next_state)

  method process*(delta: float) =
    ## handle game loop based on currently active state

    if not is_nil active:
      var next_state = active.on_process(delta)
      if not is_nil next_state and states.contains(next_state):
        discard enter(next_state)

  method physics_process*(delta: float) =
    ## handle game physics loop based on currently active state

    if not is_nil active:
      var next_state = active.on_physics_process(delta)
      if not is_nil next_state and states.contains(next_state):
        discard enter(next_state)


  ##[
  === GETTERS
  ]##

  proc get_state*(id: string): State {.gdExport.} =
    if states.contains(id):
      result = states[id]

  proc get_state_data*(id: string): Dictionary {.gdExport.} =
    if state_data.contains(id):
      result = state_data[id]

  proc set_state_data*(id, data): string {.gdExport.} =
    result = state_data.contains(id)
    if result:
      for k in data.keys():
        state_data[id][k] = data[k]
