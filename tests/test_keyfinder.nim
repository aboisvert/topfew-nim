import
  std/unittest,
  topfew/keyfinder

{.used.}

suite "KeyFinder":

  let records = @[
    "a x c\n",
    "a b c\n",
    "a b c d e\n"
  ]

  var key = ""

  test "KeyFinder":

    block:
      let kf = initKeyFinder(@[])
      let kf2 = initKeyFinder(@[])

      for record in records:
        block:
          kf.getKey(record, key)
          check: key & "\n" == record

        block:
          kf2.getKey(record, key)
          check: key & "\n" == record

    block:
      let singles = @["x", "b", "b"]
      let kf = initKeyFinder(@[2.uint])
      for i, record in records:
        kf.getKey(record, key)
        check: key == singles[i]

    block:
      let kf = initKeyFinder(@[1.uint, 3])
      for recordstring in records:
        let record = recordstring
        kf.getKey(record, key)
        check: key == "a c"

    block:
      let kf = initKeyFinder(@[1.uint, 4])
      let tooShorts = @["a", "a b", "a b c"]
      for tooShort in tooShorts:
        expect(ValueError):
          kf.getKey(tooShort, key)

      kf.getKey("a b c d", key)
      check: key == "a d"
