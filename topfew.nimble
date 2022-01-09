# Package

version       = "0.0.1"
author        = "Alex Boisvert"
description   = "Nim port of 'Topfew' utility by Tim Bray"
license       = "GPLv3"
srcDir        = "src"
bin           = @["topfew"]

# Dependencies
requires "nim >= 1.4.0"
requires "https://github.com/aboisvert/nim_aboisvert_utils.git#head"

# Tasks
import os, strutils

proc general_tests() =
  for dtest in listFiles("tests/"):
    if dtest.startsWith("t") and dtest.endsWith(".nim"):
      echo("Testing: " & $dtest)
      exec "nimble c -r $1" % [dtest]


task test, "Runs the test suite":
  general_tests()
