import std/re
import stringbuilder

type Sed* = object
  ## Sed represents a sed(1) s/a/b/g operation.
  replaceThis*: tuple[str: string, re: Regex]
  withThat*:    string


type Filters* = object
  ## Filters contains the filters to be applied prior to top-few computation.
  greps*:  seq[Regex]
  vGreps*: seq[Regex]
  seds*:   seq[Sed]


proc isEnabled*(f: Filters): bool {.inline.} = f.greps.len > 0 or f.vGreps.len > 0

proc addSed*(f: var Filters, replaceThis: string, withThat: string) =
  ## appends a new Sed operation to the filters.
  (f.seds).add Sed(replaceThis: (replaceThis, re(replaceThis)), withThat: withThat)

proc addGrep*(f: var Filters, s: string) =
  ## appends a new grep/regex to the filters. Only items that match
  ## this regex will be counted.
  (f.greps).add re(s)

proc addVgrep*(f: var Filters, s: string) =
  ## appends a new inverse grep/regex to the filters (ala grep -v).
  ## Only items that don't match the regex will be counted.
  (f.vGreps).add re(s)

func filterRecord*(f: Filters, line: string): bool {.inline.} =
  ## returns true if the supplied record passes all the filter
  ## criteria.
  if f.greps.len == 0 and f.vGreps.len == 0: return true

  # Grrrr.  Effect system currently complains about `contains` being side-effecting
  {.noSideEffect.}:
    for re in f.greps:
          if not line.contains(re): return false
    for re in f.vGreps:
      if line.contains(re): return false

  return true


proc filterField*(f: Filters, field: var string, sb: var StringBuilder) =
  ## returns a key that has had all the sed operations applied to it.
  for sed in f.seds:
    replaceSed(field, sed.replaceThis.re, sed.withThat, sb)
