fs = require 'fs'

util = require 'util'
{spawn} = require 'child_process'

clientTest = (callback) ->
  d = spawn 'cd', ['client/']
  d.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  d.stdout.on 'data', (data) ->
    util.log data.toString()
    t = spawn 'cake', ['test']
    t.stderr.on 'data', (data) ->
      process.stderr.write data.toString()
    t.stdout.on 'data', (data) ->
      util.log data.toString()
    t.on 'exit', (code) ->
      callback?() if code is 0
  d.on 'exit', (code) ->
    callback?() if code is 0

serverTest = (callback) ->
  pythontest = spawn 'python', ['server/test.py']
  pythontest.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  pythontest.stdout.on 'data', (data) ->
    util.log data.toString()
  pythontest.on 'exit', (code) ->
    callback?() if code is 0

task 'test', 'run the client and server tests', ->
  clientTest()
  serverTest()
