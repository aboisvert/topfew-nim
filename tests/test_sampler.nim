import
  std/unittest,
  topfew/filter,
  topfew/keyfinder,
  topfew/sampler

{.used.}

suite "Sampler":

  test "Sampler":
    # This isn't much of a test but at least gets the code to compile + run for some simple file
    let file = open("tests/data/small")
    let filters = Filters()
    let kf = initKeyFinder(@[1])
    sample(file, filters, kf)