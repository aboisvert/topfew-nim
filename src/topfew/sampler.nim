import
  keyfinder,
  filter,
  aboisvert_utils/stringbuilder


proc sample*(file: File, filters: Filters, kf: KeyFinder) =
  ## prints out what amounts to a debugging feed, showing how the filtering
  ## and keyrewriting are working.
  var record = newStringOfCap(100)
  while true:
    if not file.readLine(record): break

    if filters.filterRecord(record):
      echo "   ACCEPT: ", record
    else:
      echo "   REJECT: ", record

    var key = ""
    var sb = initStringBuilder()
    kf.getKey(record, key)
    var filtered = key
    filters.filterField(filtered, sb)
    if filtered == "":
      echo "  REJECT: %s\n", filtered
    elif key == filtered:
      echo "KEY AS IS: %s\n", filtered
    else:
      echo "   KEY IN: %s\n", key
      echo " FILTERED: %s\n", filtered
