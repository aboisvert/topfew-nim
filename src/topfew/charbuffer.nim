
import system/io

const
  NewLineChars* = {'\r', '\n'}
  BufferSize = 16 * 1024

let EmptyLine = "".toOpenArray(0, -1)

type CharBuffer* = object
  ## In-memory character buffer from reading file
  file: File
  buffer: array[BufferSize, char]
  currentPos: int
  lastValidPos: int # excluded
  isEOF: bool

proc initCharBuffer*(file: File): CharBuffer =
  result.file = file

proc asOpenArray*(cb: var CharBuffer): openArray[char] =
  cb.buffer.toOpenArray(cb.currentPos, cb.lastValidPos)

proc shift(cb: var CharBuffer, n: int) =
  ## Shift buffer's current position to zero'th position
  copyMem(
    dest = addr cb.buffer[0],
    source = addr cb.buffer[n],
    size = cb.lastValidPos - n)
  cb.lastValidPos -= n
  cb.currentPos -= n

proc fill*(cb: var CharBuffer): int =
  ## Fill buffer with as much content from `file` as possible
  result = cb.file.readChars(cb.buffer.toOpenArray(cb.lastValidPos, BufferSize - 1))
  cb.lastValidPos += result

proc readLine*(cb: var CharBuffer, includeEol = false): tuple[line: openArray[char], EOF: bool] =
  ## Read the next line (until either CR or CR+LF)
  ##
  ## If `includeEol` is true, also include the trailing CR or CR+LF characters in the result.
  ##
  ## Result indicates end-of-file reached through the `EOF` flag.

  if cb.isEOF: return (line: EmptyLine, EOF: true)

  var start = cb.currentPos
  const maxSize = BufferSize - 1
  while cb.currentPos - start < maxSize:
    # find next CR/LF within available buffer
    var c1: char
    while cb.currentPos < cb.lastValidPos:
      c1 = cb.buffer[cb.currentPos]
      cb.currentPos += 1
      if c1 == '\r' or c1 == '\n': break

    # ensure we have at least another char to read (to check for CR+LF)
    if cb.lastValidPos - cb.currentPos == 0:
      if start > BufferSize div 2:
        cb.shift(start)
        start = 0
      if cb.fill() == 0:
        cb.isEOF = true
        let eolPos =
          if (not includeEol) and (c1 == '\r' or c1 == '\n'): max(start - 1, cb.currentPos - 2)
          else: cb.currentPos - 1
        return (cb.buffer.toOpenArray(start, eolPos), false)

    # check for CR or CR+LF
    if c1 == '\r' or c1 == '\n':
      var eolPos = max(start - 1, cb.currentPos - 2)
      if includeEol: eolPos += 1

      # peek at next char
      let c2 = cb.buffer[cb.currentPos]
      if c1 == '\r' and c2 == '\n':
        cb.currentPos += 1
        if includeEol: eolPos += 1
      return (cb.buffer.toOpenArray(start, eolPos), false)

  # shut up compiler warning about `result` possibly not being initialized :-/
  result = (EmptyLine, true)

  raise newException(IOError, "Line size exceeded: " & $cb.buffer.toOpenArray(start, cb.currentPos - 1))
