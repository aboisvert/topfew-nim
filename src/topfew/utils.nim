import
  std/macros,
  std/tables

macro toString(name: untyped): untyped =
  newLit(name.repr)

template debug*(name: untyped, strs: varargs[string]) =
  when defined(debug) and defined(name):
    var args = ""
    for str in strs: args.add str
    echo toString(name), ": ", args

proc initCountTableForRelease*[T](capacity: int): CountTable[T] =
  when defined(release):
    initCountTable[string](capacity)
  else:
    initCountTable[string](0)

proc `$`*(table: CountTable): string =
  result = newStringOfCap(1024)
  var sep = false
  result.add "{"
  for k, v in table.pairs:
    if sep: result.add ", " else: sep = true
    result.add '"'
    result.add k
    result.add '"'
    result.add ": "
    result.add $v
  result.add "}"