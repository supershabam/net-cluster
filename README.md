net-cluster
===========

[![Build Status](https://secure.travis-ci.org/supershabam/net-cluster.png?branch=master)](http://travis-ci.org/supershabam/net-cluster)

### a drop-in replacement for node's net module that works in a sane way when clustered

## listening on random port

```javascript
server.listen(0)
```
http://nodejs.org/api/cluster.html

from the documentation:

> Normally, this will case servers to listen on a random port. However, in a cluster, each worker will receive the same "random" port each time they do listen(0). In essence, the port is random the first time, but predictable thereafter. If you want to listen on a unique port, generate a port number based on the cluster worker ID.

### 2 problems with this functionality
* listen(0) should always bind to a random port
* the listen(cluster.workerId) is unreliable
  - *you can't gurantee that the port cluster.workerId is available*

### how net-cluster operates
listen(0) always binds to a random port

### usage
net-cluster strictly implements node's net module.

```javascript
/**
 * uses net-cluster instead of net to create a server
 * 
 * Note: 2 servers will be created and they will be listening
 * on 2 distinct random ports. Try using node's net module instead
 * of net-cluster and see what happens.
 */
var cluster = require('cluster')
  , net = require('net-cluster')
  ;
  
if (cluster.isMaster) {
  cluster.fork();
  cluster.fork();
} else if (cluster.isWorker) {
  var server = net.createServer();
  server.listen(function() {
    var port = server.address().port;
    console.log('listening on port: ' + port);
  });
}
```

## use cases
* network application that needs to open multiple non-pre-determined ports
* if you provide a module that listens on port 0
  - **this is a difficult bug for people using your module**. Not 
    only will every instance of your module code be sharing the same 
    socket, but **ANY** other piece of code using listen(0) will be
    sharing the same socket (other modules or even the user's code)

## license
MIT
