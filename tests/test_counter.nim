import
  std/unittest,
  std/re,
  std/tables,
  topfew/counter

{.used.}

# forward declarations
proc assertKeyCountsEqual(exp: openarray[KeyCount], act: openarray[KeyCount])


suite "Counter":

  test "Test1KLines":

    var table = initCounter(5)
    let regex = re("\\s+")
    for line in lines("tests/data/small"):
      let fields = line.split(regex) # re.Split(scanner.Text(), 2)
      table.inc(fields[0])

    let x = table.getTop()

    let wanted = {
      "96.48.229.116":   74,
      "71.227.232.164":  24,
      "122.169.54.96":   13,
      "185.156.175.199": 13,
      "203.189.152.127": 13
    }.toTable

    check: len(x) == len(wanted)

    for kc in x:
      check:
        kc.count == wanted[kc.key]

  test "TestTable_Add":
    var table = initCounter(5)
    let keys = [
      "a", "b", "c", "d", "e", "f", "g", "h",
      "a", "b", "c", "d", "e", "f", "g",
      "a", "c", "d", "e", "f", "g",
      "a", "c", "e", "f", "g",
      "c", "e", "f", "g",
      "c", "e", "g",
      "c", "g",
      "c"
    ]

    for key in keys: table.inc(key)

    let n4 = 4
    let n5 = 5
    let n6 = 6
    let n7 = 7
    let n8 = 8

    block:
      let wanted = [
        KeyCount(key: "c", count: n8),
        KeyCount(key: "g", count: n7),
        KeyCount(key: "e", count: n6),
        KeyCount(key: "f", count: n5),
        KeyCount(key: "a", count: n4)
      ]

      assertKeyCountsEqual(wanted, table.getTop())

    block:
      var table = initCounter(3)
      for key in keys: table.inc(key)

      let wanted = [
        KeyCount(key: "c", count: n8),
        KeyCount(key: "g", count: n7),
        KeyCount(key: "e", count: n6)
      ]

      assertKeyCountsEqual(wanted, table.getTop())


  test "newTable":
    var table = initCounter(333)
    let top = table.getTop()
    check: len(top) == 0


  test "merge":
    var a = initCounter(10)
    var b = initSegmentCounter()
    var c = initSegmentCounter()
    for i in 0 ..< 50:
      b.incKey("A")
      b.incKey("B")
      c.incKey("C")
      c.incKey("A")

    c.incKey("C")
    a.merge(b)
    a.merge(c)
    let exp = [
      KeyCount(key: "A", count: 100),
      KeyCount(key: "C", count: 51),
      KeyCount(key: "B", count: 50)
    ]

    assertKeyCountsEqual(exp, a.getTop())

proc assertKeyCountsEqual(exp: openarray[KeyCount], act: openarray[KeyCount]) =
  checkpoint($getStackTraceEntries()[^2])
  check: len(exp) == len(act)

  for i in 0 ..< min(len(exp), len(act)):
    checkpoint($i)
    checkpoint($exp[i])
    checkpoint($act[i])
    check:
      exp[i].key   == act[i].key
      exp[i].count == act[i].count
