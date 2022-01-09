import std/re

const Digits* = {'0'..'9'}
  ## The set of digits.

type StringBuilder* = object
  ## A string builder/wrapper with optimized string-handling primitives
  str: string

proc `$`*(sb: StringBuilder): string =
  $sb.str

proc initStringBuilder*(initialSize: int = 240): StringBuilder =
  result.str = newStringOfCap(initialSize)
  result

func add*(sb: var StringBuilder, chars: openArray[char]) =
  for c in chars:
    sb.str.add c

func add*(sb: var StringBuilder, str: string) =
  sb.str.add str

func add*(sb: var StringBuilder, c: char) =
  sb.str.add c

func clear*(sb: var StringBuilder) =
  sb.str.setLen 0

proc invalidFormatString(msg: string) {.noinline, noreturn.} =
  var e: ref RegexError
  new(e)
  e.msg = msg
  raise e

func formatCaptureGroups(sb: var StringBuilder, formatstr: string, source: string, capturedGroups: openArray[tuple[first, last: int]]) =
  # Internal:  Append into `sb` elements of string `source` based on `formatstr` with captured groups
  var i = 0
  var num = 0
  let cg = capturedGroups
  while i < len(formatstr):
    if formatstr[i] == '$' and i+1 < len(formatstr):
      case formatstr[i+1]
      of '#':
        if num > cg.high: invalidFormatString(formatstr)
        sb.add source.toOpenArray(cg[num].first, cg[num].last)
        inc i, 2
        inc num
      of '$':
        sb.add "$"
        inc(i, 2)
      of '1'..'9', '-':
        var j = 0
        inc(i) # skip $
        var negative = formatstr[i] == '-'
        if negative: inc i
        while i < formatstr.len and formatstr[i] in Digits:
          j = j * 10 + ord(formatstr[i]) - ord('0')
          inc(i)
        let idx = if not negative: j-1 else: cg.len-j
        if idx < 0 or idx > cg.high: invalidFormatString(formatstr)
        sb.add source.toOpenArray(cg[idx].first, cg[idx].last)
      else:
        invalidFormatString(formatstr)
    else:
      sb.add formatstr[i]
      inc(i)

proc add*(s: var string, chars: openArray[char]) {.inline.} =
  for c in chars:
    s.add c

proc `:=`*(s: var string, sb: StringBuilder) {.inline.} =
  s = sb.str

proc replaceSed*(source: var string, sub: Regex, by: string, sb: var StringBuilder = initStringBuilder()) =
  ## Replace occurrences of regex `sub` in string `source` by the string/template `by`.
  ##
  ## This is the equivalent of the Sed expression `s/source/sub/g`.
  ##
  ## The optionally-provided string builder `sb` is used as a temporary buffer
  ##
  var caps: array[MaxSubpatterns, tuple[first, last: int]]
  var prev = 0
  sb.clear()
  while prev < source.len:
    var match = findBounds(source, sub, caps, prev)
    if match.first < 0: break
    sb.add(source.toOpenArray(prev, match.first - 1))
    sb.formatCaptureGroups(by, source, caps)
    if match.last + 1 == prev: break
    prev = match.last + 1
  if prev < source.len:
    sb.add(source.toOpenArray(prev, source.len - 1))
  source = sb.str
