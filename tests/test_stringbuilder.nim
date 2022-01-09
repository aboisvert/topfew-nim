import
  std/re,
  std/unittest,
  topfew/stringbuilder

{.used.}

suite "StringBuilder":
  test "add":
    var sb = initStringBuilder()
    sb.add("foo")
    sb.add("bar")
    check: $sb == "foobar"

  test "assignment :=":
    var sb = initStringBuilder()
    sb.add("foo")
    sb.add("bar")
    var str = ""
    str := sb
    check: $sb == "foobar"

  test "clear":
    var sb = initStringBuilder()
    sb.add("foo")
    sb.clear()
    check: $sb == ""

  test "replace substring prefix":
    var str = "foobar"
    var sb = initStringBuilder()
    replaceSed(str, re"foo", "bar", sb)
    check: str == "barbar"

  test "replace substring suffix":
    var str = "foobar"
    var sb = initStringBuilder()
    replaceSed(str, re"bar", "", sb)
    check: str == "foo"

  test "replace with empty substring":
    var str = "foobar"
    var sb = initStringBuilder()
    replaceSed(str, re"foo", "", sb)
    check: str == "bar"

  test "replace with capture groups":
    var str = "foobar"
    var sb = initStringBuilder()
    replaceSed(str, re"(b)a(r)", "123", sb)
    check: str == "foo123"

  test "replace with capture group substitutions":
    var str = "foobarz"
    var sb = initStringBuilder()
    replaceSed(str, re"(.)a(r)", "$1o$2", sb)
    check: str == "fooborz"
