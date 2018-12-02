##[ filename: logger.nim
logging utility for godotnim Nodes
]##

import strutils
import
  godot, node
from gd_os import get_ticks_msec

type
  LogLevel = enum
    lvInfo, lvDebug, lvWarn, lvError
  Levels = array[lvInfo..lvError, string]

const LOG_LEVELS: Levels = ["INFO", "DEBUG", "WARN", "ERROR"]
proc `$`(lvl: LogLevel): string =
  result = LOG_LEVELS[lvl]

const LEN_LVL = 8
const LEN_SRC = 24
const FMT_LEVEL = "[$#]"
const FMT_MSG = "$# <$#> $# // $#"

##[
# TODO set this somewhere/somehow
# TODO interpret these somewhere/somehow
const BLOCKED_PATHS = []
const BLOCKED_TYPES = []
const BLOCKED_GROUPS = []
]##

var logging_lvl = 0 # TODO set this somewhere/somehow

proc format_msg(src_str: string, lvl: LogLevel, msg: string): string =
  let prefix: string = src_str.align(LEN_SRC)
  let tstamp: string = align($get_ticks_msec(), LEN_LVL)
  let level = align(FMT_LEVEL % $lvl, LEN_LVL)
  result = FMT_MSG % [prefix, tstamp, level, msg]

proc log(src: Node, lvl: LogLevel, msg: string): void =
  if ord(lvl) < logging_lvl:
    return

  let src_str: string = "$#/$#" % [src.get_parent().name, src.name]
  # TODO check for blocking
  print(src_str.format_msg(lvl, msg))

proc info*(src: Node, msg: string): void =
  log(src, lvInfo, msg)

proc debug*(src: Node, msg: string): void =
  log(src, lvDebug, msg)

proc warning*(src: Node, msg: string): void =
  log(src, lvWarn, msg)

proc warn*(src: Node, msg: string): void =
  warning(src, msg)

proc error*(src: Node, msg: string): void =
  log(src, lvError, msg)
