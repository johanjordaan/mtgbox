_ = require 'prelude-ls'

errorController = ($scope,Errors) ->
  $scope.errors = Errors

  $scope.clear = ->
    Errors.length = 0

menuController = ($scope,FB,FBStatus) ->
  $scope.menuItems = [
    { label: 'home'       ,path: '/'          ,requireAuth: false }
    { label: 'capture'    ,path: '/capture'   ,requireAuth: true }
    { label: 'explore'    ,path: '/explore'   ,requireAuth: true }
  ]

  $scope.FBStatus = FBStatus

  $scope.login = ->
    FB.login  (response) ->
      FB.getLoginStatus (response) ->
        switch response.status
        | 'connected' =>
          FBStatus.loggedIn = true
          FB.api '/me', (response) ->
            FBStatus.name = response.name
            $scope.$apply!
            console.log FBStatus
        | otherwise =>
          FBSTatus.loggedIn = false
          FBStatus.name = ''
          $scope.$apply!
          console.log FBStatus

    , { scope: 'public_profile,email' }

menuItemController = ($scope,$location,FBStatus) ->
  $scope.select = ->
    $location.path "#{$scope.menuItem.path}"

  $scope.isSelected = ->
    return "#{$scope.menuItem.path}" == $location.path()

  $scope.isAuthed = ->
    if !$scope.menuItem.requireAuth
      true
    else
      FBStatus.loggedIn




homeController = ($scope,FBStatus) ->
  $scope.FBStatus = FBStatus


captureController = ($scope,Errors,Api,Data) ->
  $scope.ready = false

  Api.getCollection (collectionCards) ->
    collectionCards |> _.each (card) ->
      if Data.cardsByMultiverseid[card.mid]?
        Data.cardsByMultiverseid[card.mid].count = card.count
        Data.cardsByMultiverseid[card.mid].fcount = card.fcount

    $scope.ready = true


  $scope.filter = ''
  $scope.filteredCards = [{name:'...'}]
  $scope.$watch 'filter', (oldValue,newValue) ->
    if Data.cards? and $scope.filter.length>2
      $scope.filteredCards = Data.cards |> _.filter (card) ->
        card.name.toLowerCase().indexOf($scope.filter.toLowerCase()) == 0
    else
      $scope.filteredCards = []

  $scope.clearFilter = ->
    $scope.filter = ''

  $scope.isReady = ->
    $scope.ready


  $scope.updateCount = (mid,delta,fdelta) ->
    Api.updateCollection { mid: mid, delta:delta, fdelta:fdelta }, ->
      if !Data.cardsByMultiverseid[mid].count?
        Data.cardsByMultiverseid[mid].count = 0
      Data.cardsByMultiverseid[mid].count += delta
      if !Data.cardsByMultiverseid[mid].fcount?
        Data.cardsByMultiverseid[mid].fcount = 0
      Data.cardsByMultiverseid[mid].fcount += fdelta


exploreController = ($scope,Errors,Api) ->


apiFactory = ($resource,ErrorHandler) ->
  do
    getCards: (cb) ->
      $resource '/api/v1/cards', null
      .query {}, {}, cb, ErrorHandler

    getSets: (cb) ->
      $resource '/api/v1/sets', null
      .query {}, {}, cb, ErrorHandler


    getCollection: (cb) ->
      $resource '/api/v1/collections', null
      .query {}, {}, cb, ErrorHandler

    updateCollection: (data, cb) ->
      $resource '/api/v1/collections', null
      .save {}, data, cb, ErrorHandler


errorHandlerFactory = (Errors) ->
  (err) ->
    Errors.push err.data.message

dataFactory = (Api) ->
  retVal = do
    sets: []
    setsByCode: {}
    cards: []
    cardsByMultiverseid: {}
    loaded:false

  Api.getSets (sets) ->
    retVal.sets = sets
    for set in sets
      retVal.setsByCode[set.code] = set

    Api.getCards (cards) ->
      retVal.cards = cards
      for card in cards
        retVal.cardsByMultiverseid[card.mid] = card
        card.set = retVal.setsByCode[card.setCode]

      retVal.loaded = true

  retVal


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


app = angular.module 'app',['ngResource','ngRoute','ngFacebook']

app.factory 'Api',['$resource','ErrorHandler',apiFactory]
app.factory 'ErrorHandler',['Errors',errorHandlerFactory]
app.factory 'Data', ['Api',dataFactory]

app.value 'Errors',[]

app.controller 'menuController', ['$scope','FB','FBStatus',menuController]
app.controller 'menuItemController', ['$scope','$location','FBStatus',menuItemController]
app.controller 'errorController', ['$scope','Errors',errorController]


app.controller 'homeController', ['$scope','FBStatus',homeController]
app.controller 'captureController', ['$scope','Errors','Api','Data',captureController]
app.controller 'exploreController', ['$scope','Errors','Api',exploreController]

app.config ['$routeProvider',config]
