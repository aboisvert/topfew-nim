# Package

version = "0.0.1"
author = "Alex Boisvert"
description = "Nim port of 'Topfew' utility by Tim Bray"
license = "GPLv3"
srcDir = "src"
bin = @["topfew"]

# Dependencies
requires "nim >= 1.4.0"
requires "https://github.com/aboisvert/nim_aboisvert_utils.git#head"

# Tasks
import std/[os, strutils, sequtils, sugar, strformat]

proc general_tests() =
  for dtest in listFiles("tests/"):
    if dtest.startsWith("t") and dtest.endsWith(".nim"):
      echo("Testing: " & $dtest)
      exec "nimble c -r $1" % [dtest]

proc error(msg: string) =
  raise newException(Exception, msg)
  quit(1)

proc escapeSingleQuotes(str: string): string =
  str.multiReplace(("'", "\\'"))

proc hyperfine(benchmark: string, commands: seq[tuple[name: string,
    cmd: string]]) =
  ## Runs `hyperfine` benchmarking tool on the provided `commands`
  var commands = commands

  if existsEnv("USE_TIME"):
    commands = commands.mapIt(
      (name: it.name, cmd: "/usr/bin/time -v -a -o benchmark-time.txt -- " & it.cmd)
    )

  let commandStrs = commands.mapIt((
    let name = escapeSingleQuotes(it.name);
    let cmd = escapeSingleQuotes(it.cmd);
    fmt"-n '{name}' '{cmd}'"
  )).join(" ")

  echo fmt"Running {benchmark} test ..."
  exec fmt"echo '## {benchmark}' >> benchmark-results.md"
  exec fmt"echo '```sh' >> benchmark-results.md"
  let protoCommand = escapeSingleQuotes(commands[0].cmd)
  exec fmt"echo '$ {protoCommand}' >> benchmark-results.md"
  exec fmt"echo '```' >> benchmark-results.md"

  let verbose = false
  let showOutput = if verbose: "--show-output" else: ""

  exec fmt"hyperfine {showOutput} --warmup 3 --min-runs 5 --export-markdown benchmark-tmp.md {commandStrs}"
  exec "cat benchmark-tmp.md >> benchmark-results.md"
  exec "rm benchmark-tmp.md"

  exec "echo '' >> benchmark-results.md"

proc benchmarks() =
  ## Runs the benchmarks: Nim vs Go (optional) vs Rust (optional)

  # compile Nim topfew with all optimizations
  exec "nimble -d:danger --opt:speed --passC:-flto --passL:-flto build"

  var execs = @[
    (name: "Nim", cmd: "./topfew")
  ]

  if existsEnv("GO_CMD"):
    execs.add (name: "Go", cmd: getEnv("GO_CMD"))

  if existsEnv("RUST_CMD"):
    execs.add (name: "Rust", cmd: getEnv("RUST_CMD"))

  let file = "access.log.xlarge"

  let args = @[
    (name: "single-threaded", args: "-w 1 -f 7"),
    (name: "multi-threaded", args: "-f 7"),
    (name: "regex filter", args: "-f 7 -g \"googlebot|bingbot|Twitterbot\""),
    (name: "sed substitutions", args: "-f 4 -s \"\\\\[[^:]*:\" \"\" -s \":.*\\$\" \"\" -n 24")
  ]

  # clean out the results file
  exec "echo '' > benchmark-results.md"
  exec "echo '' > benchmark-time.txt"

  exec "echo '# Benchmark Results' >> benchmark-results.md"

  # group together the same bench for each language
  for arg in args:
    var commands = newSeq[tuple[name: string, cmd: string]]()
    for exec in execs:
      commands.add (name: exec.name, cmd: fmt"{exec.cmd} {arg.args} {file}")
    hyperfine(arg.name, commands)

  exec "echo '## Date' >> benchmark-results.md"
  exec "date >> benchmark-results.md"

  exec "echo '## System Information' >> benchmark-results.md"
  exec "uname -a >> benchmark-results.md"
  exec "echo '' >> benchmark-results.md"
  exec "echo '```' >> benchmark-results.md"
  exec "lscpu >> benchmark-results.md"
  exec "echo '```' >> benchmark-results.md"

  echo "Results written in benchmark-results.md"

task test, "Runs the test suite":
  general_tests()

task bench, "Runs the benchmark suite":
  benchmarks()
