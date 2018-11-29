import strutils
import
  godot, node, input

# NIMIFY does this... break things?
# yes, yes it does
type
  StateMachine = Node

gdobj State of Node:
  var FSM*: StateMachine = nil
  var ID*: string = nil

  var active: bool = false

  method init*() =
    add_user_signal("state_enter")
    add_user_signal("state_leave")

  proc gen_state_id(): string =
    # TODO host.name + self.name ?
    result = self.name.to_lower()

  method ready*() =
    self.FSM = get_parent()
    self.ID = gen_state_id()

  proc enter*(state_data = new_dictionary(), last_state: string = nil): void =
    on_enter(state_data, last_state)
    if not self.active:
      emit_signal("state_enter")
      self.active = true

  proc leave*(): void =
    on_leave()
    if self.active:
      emit_signal("state_leave")
      self.active = false

  ##[
  === OVERRIDEABLES
      These are methods that extending classes are meant to override
      Almost all of these are called by the StateMachine host
  ]##

  method on_enter*(state_data = new_dictionary(), last_state: string = nil): void =
    ##[
      Logic to execute when entering the state
      Returns the state ID of the next state to change to, or nil if no change needed
      fsm :- the StateMachine host
      state_data :- any relevant data this State may expect upon entering
      last_state :- the last State the host was in
    ]##
    discard

  method on_leave*(): void =
    ##[
      Logic to execute when leaving the state
      Returns the state ID of the next state to change to, or nil if no change needed
      fsm :- the StateMachine host
    ]##
    discard

  method on_process*(delta: float): string =
    ##[
      A wrapper for Node._process(), called by the StateMachine host only when this State is active
      Returns the state ID of the next state to change to, or nil if no change needed
      fsm :- the StateMachine host
      delta :- delta time provided by Node._process()
    ]##
    result = nil

  method on_physics_process*(delta: float): string =
    ##[
      A wrapper for Node._physics_process(), called by the StateMachine host only when this State is active
      Returns the state ID of the next state to change to, or nil if no change needed
      fsm :- the StateMachine host
      delta :- delta time provided by Node._process()
    ]##
    result = nil

  method on_input*(ev: InputEvent): string =
    ##[
      A wrapper for Node._input(), called by the StateMachine host only when this State is active
      Returns the state ID of the next state to change to, or nil if no change needed
      fsm :- the StateMachine host
      ev :- input event provided by Node._input()
    ]##
    result = nil

  method on_unhandled_input*(ev: InputEvent): string =
    ##[
      A wrapper for Node._unhandled_input(), called by the StateMachine host only when this State is active
      Returns the state ID of the next state to change to, or nil if no change needed
      fsm :- the StateMachine host
      ev :- input event provided by Node._unhandled_input()
    ]##
    result = nil

  method on_animation_finished*(ani_name: string): string =
    result = nil


gdobj StateMachine of Node:
  var HOST*: Node = nil

  var active: State = nil
  var states: Dictionary = new_dictionary()
  var state_data: Dictionary = new_dictionary()

  method init*() =
    # emitted after the previous state is left, but before the next state is entered
    # NIMIFY is there a more elegant way to do this?
    add_user_signal(
      "state_change",
      new_array(new_variant "state_from", new_variant "state_to")
    )

  method ready*() =
    self.HOST = get_parent() as Node

    for state in get_children():
      if state of State:
        states[state.id] = state
        state_data[state.id] = new_dictionary()
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

  proc set_state_data*(id: string, data: Dictionary): string {.gdExport.} =
    result = state_data.contains(id)
    if result:
      for k in data.keys():
        state_data[id][k] = data[k]
