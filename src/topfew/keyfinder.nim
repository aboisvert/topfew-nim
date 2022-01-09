
## Extract a key from a record based on a list of keys. If the list is empty, the key is the whole record.
##  Otherwise there's a list of fields. They are extracted, joined with spaces, and that's the key

## First implementation was regexp based but Golang regexps are slow.  So we'll use a hand-built state machine that
##  only cares whether each byte encodes space-or-tab or not.

## NER is the error message returned when the input has less fields than the KeyFinder is configured for.
const NER = "not enough bytes in record"

type KeyFinder* = object
  ## KeyFinder extracts a key based on the specified fields from a record.
  ## fields is a slice of small integers representing field numbers;
  ## 1-based on the command line, 0-based here.
  fields: seq[uint]
  #key:    string


proc initKeyFinder*(keys: seq[uint]): KeyFinder =
  ## creates a new key finder with the supplied field numbers, the input should be 1 based.
  ## KeyFinder is not threadsafe, you should Clone it for each goroutine that uses it.
  result = KeyFinder(fields: keys #[, key: ""]#)


proc clone*(kf: KeyFinder): KeyFinder =
  ## returns a new KeyFinder with the same configuration. Each goroutine should use its own
  ## KeyFinder instance.
  return KeyFinder(
    fields: kf.fields,
    #[ key:    "" ]#
  )

template findNextFieldIndex(record: openArray[char], index: var int) =
  # eat leading space
  let len = record.len
  while index < len and (record[index] == ' ' or record[index] == '\t'):
    index += 1

  if index == len:
    raise newException(ValueError, "findNextFieldIndex " & NER)

  # find next space
  while index < len and record[index] != ' ' and record[index] != '\t':
    index += 1

template gather(key: var string, record: openArray[char], index: var int) =
  ## pull in the bytes from a desired field

  # eat leading space
  let len = record.len
  while index < len and (record[index] == ' ' or record[index] == '\t'):
    index += 1

  if index == len:
    raise newException(ValueError, "gather " & NER)

  # copy key bytes
  while index < len and record[index] != ' ' and record[index] != '\t' and record[index] != '\n':
    key.add record[index]
    index += 1

proc extractKey(dest: var string, src: openArray[char]) =
  dest.setLen 0
  for c in src:
    if c == '\r' or c == '\n': break
    dest.add c


proc getKey*(kf: KeyFinder, record: openArray[char], key: var string) {.inline.} =
  ## extracts a key from the supplied record. This is applied to every record,
  ## so efficiency matters.

  # if there are no keyfinders just return the record, minus any trailing newlines
  if len(kf.fields) == 0:
    if record.len > 0 and record[^1] == '\n': extractKey(key, record)
    else: extractKey(key, record)
    return

  key.setLen 0
  var field = 1.uint  # fields are 1-based
  var index = 0
  var first = true

  # for each field in the key
  for keyField in kf.fields:
    # bypass fields before the one we want
    while field < keyField:
      findNextFieldIndex(record, index)
      field += 1

    # join(' ', keyfields)
    if first: first = false
    else: key.add(' ')

    # attach desired field to key
    gather(key, record, index)
    field += 1
