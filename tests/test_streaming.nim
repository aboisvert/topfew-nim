import
  std/tables,
  std/unittest,
  topfew/keyfinder,
  topfew/filter,
  topfew/streaming

{.used.}

suite "Streaming":
  test "test1KLinesStream":
    let file = open("tests/data/small")
    check: file != nil
    defer: file.close()

    let kf = initKeyFinder(@[1.uint])
    let f = Filters()
    let x = fromStream(file, f, kf, 5)

    let wanted = {
      "96.48.229.116":   74,
      "71.227.232.164":  24,
      "122.169.54.96":   13,
      "185.156.175.199": 13,
      "203.189.152.127": 13
    }.toTable


    check: len(x) == len(wanted)

    for kc in x:
      check: kc.count == wanted[kc.key].uint64
