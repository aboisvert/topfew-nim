import
  std/strformat,
  counter,
  filter,
  keyfinder,
  stringbuilder

proc fromStream*(file: File, filters: Filters, kf: KeyFinder, size: int): seq[KeyCount] =
  ## FromStream reads a stream and hand each line to the top-occurrence counter. Really only used on stdin.
  var counter = initCounter(size)
  var record = newStringOfCap(4096)
  var key = ""
  var sb = initStringBuilder()
  while true:
    if not file.readLine(record): break
    if not filters.filterRecord(record): continue

    try:
      kf.getKey(record, key)
    except ValueError:
      ## bypass
      stderr.write fmt"Can't extract key from record: {getCurrentExceptionMsg()}"
      stderr.write "\n"
      stderr.write (if $record == "": "[empty line in input]" else: $record)
      stderr.write "\n"
      continue

    filters.filterField(key, sb)
    counter.inc(key)
  return counter.getTop()
