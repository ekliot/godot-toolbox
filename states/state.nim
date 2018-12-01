##[ filename: state.gd
A State class for use with the StateMachine
]##

import strutils
import
  godot, node, input
# import state_machine
import states


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
    self.FSM = get_parent() as StateMachine
    self.ID = gen_state_id()

  proc enter*(state_data = new_dictionary(), last_state = ""): void {.gdExport.} =
    on_enter(state_data, last_state)
    if not self.active:
      emit_signal("state_enter")
      self.active = true

  proc leave*(): void {.gdExport.} =
    on_leave()
    if self.active:
      emit_signal("state_leave")
      self.active = false

  ##[
  === OVERRIDEABLES
      These are methods that extending classes are meant to override
      Almost all of these are called by the StateMachine host
  ]##

  proc set_host*(host: Node): void {.gdExport.} =
    discard

  method on_enter*(state_data: Dictionary, last_state: string): void =
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
    result = ""

  method on_physics_process*(delta: float): string =
    ##[
      A wrapper for Node._physics_process(), called by the StateMachine host only when this State is active
      Returns the state ID of the next state to change to, or nil if no change needed
      fsm :- the StateMachine host
      delta :- delta time provided by Node._process()
    ]##
    result = ""

  method on_input*(ev: InputEvent): string =
    ##[
      A wrapper for Node._input(), called by the StateMachine host only when this State is active
      Returns the state ID of the next state to change to, or nil if no change needed
      fsm :- the StateMachine host
      ev :- input event provided by Node._input()
    ]##
    result = ""

  method on_unhandled_input*(ev: InputEvent): string =
    ##[
      A wrapper for Node._unhandled_input(), called by the StateMachine host only when this State is active
      Returns the state ID of the next state to change to, or nil if no change needed
      fsm :- the StateMachine host
      ev :- input event provided by Node._unhandled_input()
    ]##
    result = ""

  method on_animation_finished*(ani_name: string): string =
    result = ""
