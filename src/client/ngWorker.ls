
workerFactory = ($q) ->
  worker = new Worker('worker.js')
  defer = null
  worker.addEventListener 'message', (e) ->
    #e.data
    defer.resolve(e.data);
  ,false

  # Data has to be some function and its parameters
  #
  doWork : (data) ->
    defer = $q.defer!
    worker.postMessage data
    defer.promise;


module = angular.module 'ngWorker', []
module.factory 'worker', ['$q',workerFactory]
