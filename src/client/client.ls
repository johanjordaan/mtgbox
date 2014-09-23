_  = require 'prelude-ls'

errorController = ($scope,Errors) ->
  $scope.errors = Errors

  $scope.clear = ->
    Errors.length = 0

menuController = ($scope) ->
  $scope.menuItems = [
    { label: 'home'       ,path: '/'          ,require_auth: false }
    { label: 'capture'    ,path: '/capture'   ,require_auth: false }
    { label: 'explore'    ,path: '/explore'   ,require_auth: false }
  ]

menuItemController = ($scope,$location) ->
  $scope.select = ->
    $location.path "#{$scope.menuItem.path}"

  $scope.isSelected = ->
    return "#{$scope.menuItem.path}" == $location.path()

  $scope.isAuthed = ->
    true
    #if !$scope.menu_item.require_auth
    #  return true
    #else
    #  return auth.authenticated


homeController = ($scope,Errors,Api) ->


captureController = ($scope,Errors,Api) ->
  $scope.ready = false

  $scope.totalCards = 0

  $scope.cards = []
  $scope.cardsByMultiverseid = {}
  Api.getCards (cards) ->
    $scope.cards = cards
    for card in cards
      $scope.cardsByMultiverseid[card.multiverseid] = card
    Api.getCollection (collectionCards) ->
      collectionCards |> _.each (card) ->
        if $scope.cardsByMultiverseid[card.multiverseid]?
          $scope.cardsByMultiverseid[card.multiverseid].count = card.count
          $scope.cardsByMultiverseid[card.multiverseid].fcount = card.fcount

          $scope.totalCards += card.count + card.fcount

      $scope.ready = true


  $scope.filter = ''
  $scope.filteredCards = [{name:'...'}]
  $scope.$watch 'filter', (oldValue,newValue) ->
    if $scope.cards? and $scope.filter.length>2
      $scope.filteredCards = $scope.cards |> _.filter (card) ->
        card.name.toLowerCase().indexOf($scope.filter.toLowerCase()) == 0
    else
      $scope.filteredCards = []

  $scope.clearFilter = ->
    $scope.filter = ''

  $scope.isReady = ->
    $scope.ready


  $scope.updateCount = (multiverseid,delta,foil) ->


    Api.updateCollection { multiverseid: multiverseid, delta:delta, fdelta:fdelta }, ->
      if !$scope.cardsByMultiverseid[multiverseid].count?
        $scope.cardsByMultiverseid[multiverseid].count = 0
      $scope.cardsByMultiverseid[multiverseid].count += 1


  $scope.incCount = (multiverseid) ->
    Api.incCount { multiverseid: multiverseid, delta:1, fdelta:0 }, ->
      if !$scope.cardsByMultiverseid[multiverseid].count?
        $scope.cardsByMultiverseid[multiverseid].count = 0
      $scope.cardsByMultiverseid[multiverseid].count += 1

  $scope.decCount = (multiverseid) ->
    Api.incCount { multiverseid: multiverseid, delta:-1, fdelta:0 }, ->
      if !$scope.cardsByMultiverseid[multiverseid].count?
        $scope.cardsByMultiverseid[multiverseid].count = 0
      $scope.cardsByMultiverseid[multiverseid].count += -1

  $scope.incFCount = (multiverseid) ->
    Api.incCount { multiverseid: multiverseid, delta:0, fdelta:1 }, ->
      if !$scope.cardsByMultiverseid[multiverseid].fcount?
        $scope.cardsByMultiverseid[multiverseid].fcount = 0
      $scope.cardsByMultiverseid[multiverseid].fcount += 1

  $scope.decFCount = (multiverseid) ->
    Api.incCount { multiverseid: multiverseid, delta:0, fdelta:-1 }, ->
      if !$scope.cardsByMultiverseid[multiverseid].count?
        $scope.cardsByMultiverseid[multiverseid].fcount = 0
      $scope.cardsByMultiverseid[multiverseid].count += -1


exploreController = ($scope,Errors,Api) ->


apiFactory = ($resource,ErrorHandler) ->
  do
    getCards: (cb) ->
      $resource '/api/v1/cards', null
      .query {}, {}, cb, ErrorHandler

    getCollection: (cb) ->
      $resource '/api/v1/collections', null
      .query {}, {}, cb, ErrorHandler

    incCount: (data, cb) ->
      $resource '/api/v1/collections', null
      .save {}, data, cb, ErrorHandler


errorHandlerFactory = (Errors) ->
  (err) ->
    Errors.push err.data.message

config = ($routeProvider) ->
  $routeProvider
  .when '/home', do
    templateUrl: 'home.html'
    controller: 'homeController'

  .when '/capture', do
    templateUrl: 'capture.html'
    controller: 'captureController'

  .when '/explore', do
    templateUrl: 'explore.html'
    controller: 'exploreController'

  .otherwise do
    redirectTo: '/home'


app = angular.module 'app',['ngResource','ngRoute']

app.factory 'Api',['$resource','ErrorHandler',apiFactory]
app.factory 'ErrorHandler',['Errors',errorHandlerFactory]
app.value 'Errors',[]

app.controller 'menuController', ['$scope',menuController]
app.controller 'menuItemController', ['$scope','$location',menuItemController]
app.controller 'errorController', ['$scope','Errors',errorController]


app.controller 'homeController', ['$scope','Errors','Api',homeController]
app.controller 'captureController', ['$scope','Errors','Api',captureController]
app.controller 'exploreController', ['$scope','Errors','Api',exploreController]


app.config ['$routeProvider',config]
