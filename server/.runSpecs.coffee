#to run: jasmine-node runSpecs.coffee . --coffee --verbose

jasmine = require("jasmine-node")
sys = require("sys")
for key of jasmine
  global[key] = jasmine[key]
isVerbose = true
showColors = true
process.argv.forEach (arg) ->
  switch arg
    when "--color"
      showColors = true
    when "--noColor"
      showColors = false
    when "--verbose"
      isVerbose = true

jasmine.executeSpecsInFolder __dirname + "/spec", ((runner, log) ->
  if runner.results().failedCount is 0
    process.exit 0
  else
    process.exit 1
), isVerbose, showColors
