##
# net-cluster
# ===========
#
# Copyright (c) 2012 Ian Hansen (//github.com/supershabam)
# MIT License
#
# a drop-in replacement for node's net module that works in a sane way when clustered 
# -----------------------------------------------------------------------------------

net = require 'net'
cluster = require 'cluster'
dns = require 'dns'
nop = require 'nop'
TCP = process.binding('tcp_wrap').TCP

# utility function
extend = (obj, mixin) ->
  obj[name] = method for name, method of mixin    
  obj

# functions equivalent to those from node's net module
toNumber = (x) ->
  x = Number(x)
  if x >= 0
    return x
  return false

isPipeName = (s) ->
  typeof s is 'string' and toNumber(s) is false

errnoException = (errorno, syscall) ->
  e = new Error(syscall + ' ' + errorno)
  e.errno = e.code = errorno
  e.syscall = syscall
  return e

##
# Server class extending node's net.Server
#
# Only intercepts functionality when neccessary in order to make
# listening on port 0 work as Al Gore intended
class Server extends net.Server

  ##
  # manually create a tcp handle and pass it to the _listen2 function. 
  # If we already have a handle then _listen2 won't try and make one.
  _netClusterListen: (address, port, addressType) ->
    handle = new TCP()
    errno = 0

    if addressType is 6
      errno = handle.bind6 address, port
    else
      errno = handle.bind address,port

    if errno
      handle.close()
      error = errnoException(errno, 'listen')
      process.nextTick =>
        @.emit 'error', error
      
    else
      # set handle so that default listen doesn't try to make one
      @._handle = handle
      @._listen2.apply(@, arguments)

  ##
  # whether or not we should intercept the call to listen
  #
  # requirements:
  # * must be a worker in a cluster environment
  # * must be attempting to listen on port 0
  _doNetClusterIntercept: ->
    # only intercept if we're a worker
    if !cluster.isWorker
      return false

    port = toNumber arguments[0]

    # copying if else if statement from node's net module
    # only intercept if we're attaching to the net and the port is 0
    if arguments.length is 0 or typeof arguments[0] is 'function'
      return true
    else if arguments[0] and typeof arguments[0] is 'object'
      return false
    else if isPipeName(arguments[0])
      return false
    else if typeof arguments[1] is 'undefined' || typeof arguments[1] is 'function' || typeof arguments[1] is 'number'
      return port == 0
    else
      return port == 0

  ##
  # helper function to parse from an arguments array the parameters to pass to _netClusterListen
  _getPortArguments: (args, cb) ->
    port = toNumber args[0]
    backlog = toNumber(args[1] || toNumber(args[2]))

    if args.length is 0 or typeof args[0] is 'function'
      return cb(null, ['0.0.0.0', 0, null, backlog])
    else if typeof args[1] is 'undefined' || typeof args[1] is 'function' || typeof args[1] is 'number'
      return cb(null, ['0.0.0.0', port, 4, backlog])
    else
      dns.lookup args[1], (err, ip, addressType) ->
        return cb(err) if err
        unless ip
          ip = '0.0.0.0'
          addressType = 4
        return cb(null, [ip, port, addressType, backlog])

  ##
  # overrides node's listen method with one that makes me happy
  listen: ->
    # skip this override if possible
    if !@_doNetClusterIntercept.apply(@, arguments)
      return super

    # emulate overridden listen callback functionality since we're doing our own thing now
    cb = nop
    lastArg = arguments[arguments.length - 1]
    if typeof lastArg is 'function'
      cb = lastArg
    @once 'listening', cb

    @_getPortArguments arguments, (err, portArgs) =>
      return @emit 'error', err if err
      @_netClusterListen.apply(@, portArgs)

# provide everything that the net module does
extend(module.exports, net)

# but override the createServer function to use our server
module.exports.createServer = ->
  new Server(arguments[0], arguments[1])

# also override the original net.Server
module.exports.Server = Server
