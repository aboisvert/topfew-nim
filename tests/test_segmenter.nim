import
  std/unittest,
  topfew/counter,
  topfew/filter,
  topfew/keyfinder,
  topfew/segmenter

{.used.}

suite "Segmenter":

  test "Segmenter":
    let fname = "tests/data/small"
    let filters = Filters()
    var counter = initCounter(2)
    let kf = initKeyFinder(@[1])

    readFileInSegments(fname, filters, counter, kf, numSegments = 1)

    check: counter.getTop() == @[
      KeyCount(key: "96.48.229.116",  count: 74),
      KeyCount(key: "71.227.232.164", count: 24)
    ]
