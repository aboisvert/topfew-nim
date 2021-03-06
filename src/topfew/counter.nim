import
  std/tables,
  std/algorithm,
  utils

type KeyCount* = object
  ## KeyCount represents a key's occurrence count.
  key*:   string
  count*: int64

type Counter* = object
  ## Counter represents a bunch of keys and their occurrence counts, with the highest counts tracked.
  ## threshold represents the minimum count value to qualify for consideration as a top count
  ## the "top" map represents the keys & counts encountered so far which are higher than threshold
  counts*:    CountTable[string]
  top*:       CountTable[string]
  threshold*: int64
  size*:      int

type SegmentCounter* = CountTable[string]
  ## SegmentCounter tracks key occurrence counts for a single segment.


# forward declarations
proc compact(t: var Counter): void
proc topAsSortedList*(t: var Counter): seq[KeyCount]

proc initCountTableForRelease[T](capacity: int): CountTable[T] =
  when defined(release) or defined(danger):
    initCountTable[string](capacity)
  else:
    initCountTable[string](0)


proc initCounter*(size: int): Counter =
  ## creates a new empty counter, ready for use. size controls how many top items to track.
  result.size = size
  result.counts = initCountTableForRelease[string](1024)
  result.top = initCountTableForRelease[string](size * 2)


proc inc*(t: var Counter, bytes: string) {.inline.} =
  # add one occurrence to the counts for the indicated key.
  t.counts.inc(bytes)

  debug Counter, "inc ", bytes
  let count = t.counts[bytes]
  # big enough to be a top candidate?
  if count >= t.threshold:
    t.top[bytes] = count
    if len(t.top) >= (t.size * 2):
      t.compact()


proc compact(t: var Counter) =
  # sort the top candidates, shrink the list to the top t.size, put them back in a map
  t.top.sort()
  var newTable = initCountTableForRelease[string](t.size * 2)
  var i = 0
  for key, count in t.top:
    newTable[key] = count # @alex - not ideal to downcast to int
    i += 1
    if i >= t.size:
      t.threshold = count
      break
  t.top = newTable

proc compare(kc1: KeyCount, kc2: KeyCount): int =
  if kc1.count < kc2.count: 1 else: -1

proc topAsSortedList*(t: var Counter): seq[KeyCount] =
  result = newSeqOfCap[KeyCount](len(t.top))
  for key, count in t.top:
    result.add KeyCount(key: key, count: count)
  result.sort(compare)


proc getTop*(t: var Counter): seq[KeyCount] =
  # returns the top occuring keys & counts in order, with highest count first.
  result = t.topAsSortedList()
  if len(result) > t.size:
    return result[0 ..< t.size]


# merge applies the counts from the SegmentCounter into the Counter.
# Once merged, the SegmentCounter should be discarded.
proc merge*(t: var Counter, counter: SegmentCounter) =
  for key, count in counter:
    t.counts.inc(key, count)

    let count = t.counts[key] # @note(alex) - ideally we wouldn'thave to lookup the key again :-/

    # big enough to be a top candidate?
    if count >= t.threshold:
      # if it wasn't in t.counts then we already know its not in t.top
      t.top[key] = count
      # has the top set grown enough to compress?
      if len(t.top) >= (t.size * 2):
        t.compact()


proc initSegmentCounter*(): SegmentCounter =
  initCountTableForRelease[string](16 * 1024)


proc incKey*(s: var SegmentCounter, key: string) {.inline.} =
  debug Counter, "incKey ", $key
  s.inc(key)
