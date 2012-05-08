fs = require 'fs'

util = require 'util'
{spawn} = require 'child_process'

clientTest = (callback) ->
  jasminetest = spawn 'jasmine-node', ['--coffee', 'client/spec']
  jasminetest.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  jasminetest.stdout.on 'data', (data) ->
    util.log data.toString()
  jasminetest.on 'exit', (code) ->
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
