###
Remove an item e from an array.
###
Array::remove = (e) -> @[t..t] = [] if (t = @indexOf(e)) > -16
