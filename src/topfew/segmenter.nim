import
  system/io,
  std/cpuinfo,
  std/strformat,
  std/threadpool,
  aboisvert_utils/filebuffer,
  aboisvert_utils/stringbuilder,
  counter,
  filter,
  keyfinder,
  utils

when defined(profiling):
  # note: also compile with the --profiler:on and --stacktrace:on flags
  import nimprof


type Segment* = object
  ## Segment represents a segment of a file.
  ## Is required to begin at the start of a line, i.e. start of file or after a \n.
  start:    int
  `end`:    int
  filename: string


type SegmentResult = object
  ## one of these will be set
  err:      Exception
  counters: SegmentCounter


# forward declarations
proc initSegment(fname: string, start: int, `end`: int): Segment
proc readAll(s: Segment, filter: Filters, kf: KeyFinder): SegmentResult {.gcsafe.}


proc readFileInSegments*(fname: string, filter: Filters, counter: var Counter, kf: KeyFinder, numSegments: int) =
  ## ReadFileInSegments breaks the file up into multiple segments and then reads them in parallel. counter
  ## will be updated with the resulting occurrence counts.

  # find file size
  let file = open(fname)
  let fileSize = file.getFileSize()
  file.close()
  debug readFileInSegments, fmt"{fileSize=}"

  # if user doesn't specify segment parallelism, we ask Go how many cores it thinks
  # the CPU has and assign one segment per CPU
  let segSizeHeuristic =
    if numSegments == 0:
      let cores = countProcessors()
      debug readFileInSegments, fmt"{cores=}"
      fileSize div cores
    else:
      fileSize div numSegments

  let segSize = max(4096, segSizeHeuristic)
  debug readFileInSegments, fmt"{segSize=}"

  # compute segments and put them in a slice
  var segments: seq[Segment]
  var base = 0
  while base < fileSize:
    # each segment starts at the beginning of a line and `end`s after a newline (or at EOF)
    let segment = initSegment(fname, base, base + segSize.int)
    segments.add segment
    base = segment.`end`

  debug readFileInSegments, fmt"{segments=}"
  if numSegments == 1:
    let result = readAll(segments[0], filter, kf)
    counter.merge result.counters
  else:
    # Fire 'em off, wait for them to report back
    var results = newSeq[FlowVar[SegmentResult]]()
    for segment in segments:
      let flowVar = spawn readAll(segment, filter, kf)
      results.add flowVar

    for r in results:
      let result = ^r
      counter.merge result.counters


proc initSegment(fname: string, start: int, `end`: int): Segment =
  return Segment(start: start, `end`: `end`, filename: fname)

proc `$`(src: openArray[char]): string =
  result = newStringOfCap(4096)
  for c in src: result.add c

proc `:=`(dest: var string, src: openArray[char]) =
  dest.setLen 0
  for c in src: dest.add c

## we've already opened the file and seek'ed to the right place
proc readAll(s: Segment, filter: Filters, kf: KeyFinder): SegmentResult {.gcsafe.} =
  # get the file ready to go
  debug readAll, "readAll ", $s, " start: ", $s.start

  var current = s.start
  var counters = initSegmentCounter()

  let reader = open(s.filename)
  defer: reader.close()

  reader.setFilePos(s.start)
  var buffer = initFileBuffer(reader)

  if s.start != 0:
    # read and discard partial line
    let r  = buffer.readLine(includeEol = true)
    current += r.line.len

  # hoisted outside of loop to reduce GC thrashing
  var record = ""
  var key = newStringOfCap(16 * 1024)
  var sb = initStringBuilder()

  while current < s.end:
    debug readAll, fmt"{current=}"
    let read = buffer.readLine(includeEol = true)
    if read.EOF: break

    debug readAll, "read ", record
    current += read.line.len

    if filter.isEnabled:
      record := read.line
      if not filter.filterRecord(record): continue

    try:
      kf.getKey(read.line, key)
    except ValueError:
      stderr.write fmt"Can't extract key from {read.line}"
      stderr.write "\n"
      continue

    if filter.seds.len > 0: filter.filterField(key, sb)
    counters.incKey(key)

  debug readAll, "SegmentResult ", $counters
  SegmentResult(counters: counters)
