import
  std/os,
  std/strutils,
  std/strformat,
  topfew/counter,
  topfew/filter,
  topfew/keyfinder,
  topfew/segmenter

from topfew/sampler import nil
from topfew/streaming import nil

const instructions = """
Usage: tf
  -n, --number (output line count) [default 10]
  -f, --fields (field list) [default is the whole record]
  -g, --grep (regexp) [may repeat]
  -v, --vgrep (regexp) [may repeat]
  -s, --sed (regexp) (replacement) [may repeat]
  -w, --width (segment count) [default is result of runtime.numCPU()]
  --sample
  -h, -help, --help
  (filename) [optional, stdin if omitted]

Field list is comma-separated integers, e.g. -f 3 or --fields 1,3,7

The regexp-valued fields work as follows:
-g/--grep discardsrecords that don't match the regexp (g for grep)
-v/--vgrep discards records that do match the regexp (v for grep -v)
-s/--sed works on extracted fields, replacing regexp with replacement

The regexp-valued fields can be supplied multiple times; the filtering
will be performed in the order supplied.

It can be difficult to get the regular expressions right. "--sample"
causes topfew to read records and print out the results of the
filtering activities. It only works on standard input.
"""

proc usage(error: string, exception: ref Exception = nil) =
  echo instructions
  echo ""
  if error != "":
    echo "Problem: ", error
  if exception != nil:
    echo exception.getStackTrace()
  if error != "" or exception != nil:
    quit(1)
  else:
    quit(0)

# forward declarations
proc parseFields(spec: string): seq[uint]


proc main() =
  var size = 10
  var error: ref Exception
  var err: string = ""
  var fields: seq[uint]
  var cpuprofile: string
  var tracefname: string
  var fname: string
  var filters: Filters
  var sample = false
  var width = 0

  var i = 1
  while i <= paramCount():
    case paramStr(i):
    of "-n", "--number":
      i += 1
      try: size = parseInt(paramStr(i))
      except ValueError:
        error = getCurrentException()
        err = fmt"invalid number: {paramStr(i)}"
    of "-f", "--fields":
      i += 1
      fields = parseFields(paramStr(i))
    of "--cpuprofile":
      i += 1
      cpuprofile = paramStr(i)
    of "--trace":
      i += 1
      tracefname = paramStr(i)
    of "-g", "--grep":
      i += 1
      filters.addGrep(paramStr(i))
    of "-v", "--vgrep":
      i += 1
      filters.addVgrep(paramStr(i))
    of "-s", "--sed":
      filters.addSed(paramStr(i+1), paramStr(i+2))
      i += 2
    of "--sample":
      sample = true
    of "-h", "-help", "--help":
      usage("")
    of "-w", "--width":
      i += 1
      try: width = parseInt(paramStr(i))
      except ValueError:
        error = getCurrentException()
        err = fmt"invalid width: {paramStr(i)}"
    else:
      let arg = paramStr(i)
      if arg[0] == '-':
        err = fmt"Unexpected flag argument: {arg}"
      else:
        fname = arg

    if err != "":
      stderr.write err
      stderr.write '\n'
      quit(1)

    i += 1

  let kf = initKeyFinder(fields)
  var topList: seq[KeyCount] = @[]

  if fname == "":
    if sample:
      for i, sed in filters.seds:
        echo fmt"SED {i}: s/{sed.replaceThis.str}/{sed.withThat}/"
      sampler.sample(stdin, filters, kf)
    else:
      topList = streaming.fromStream(stdin, filters, kf, size)
  else:
    var counter = initCounter(size)
    readFileInSegments(fname, filters, counter, kf, width)
    #echo "counter: ", counter
    topList = counter.getTop()


  for kc in topList:
    echo fmt"{kc.count} {kc.key}"


proc parseFields(spec: string): seq[uint] =
  let parts = spec.split(",")
  var num: int
  for part in parts:
    num = parseInt(part)
    result.add(num.uint)


when isMainModule:
  main()