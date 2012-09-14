net = require '../index'
cluster = require 'cluster'
hub = require 'clusterhub'
workerCount = 2

describe 'net', ->
  it 'should be magic', (done) ->
    if cluster.isMaster
      isDone = false
      usedPorts = {}

      # ensure ports are allocated and that they are unique
      hub.on 'allocate:port', (port) ->
        if usedPorts[port] and !isDone
          isDone = true
          return done("tried allocating #{port} twice")
        usedPorts[port] = true

        if Object.keys(usedPorts).length is workerCount
          callback = ->
            if !isDone
              return done()
          setTimeout callback, 200

      for i in [1..workerCount]
        cluster.fork()
    else
      server = net.createServer()
      server.listen 0, ->
        port = server.address().port
        hub.emit 'allocate:port', port
    