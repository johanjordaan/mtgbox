_ = require 'prelude-ls'

errorController = ($scope,Errors) ->
  $scope.errors = Errors

  $scope.clear = ->
    Errors.length = 0

menuController = ($scope,FB,FBStatus) ->
  $scope.menuItems = [
    { label: 'home'       ,path: '/home'      ,requireAuth: false }
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

  Data.allDataLoaded.then ->
    Api.getCollection (collectionCards) ->
      collectionCards |> _.each (card) ->
        if Data.cardsByMultiverseid[card.mid]?
          Data.cardsByMultiverseid[card.mid].count = card.count
          Data.cardsByMultiverseid[card.mid].fcount = card.fcount

    $scope.ready = true


  $scope.filter = ''
  $scope.filteredCards = [{name:'...'}]
  $scope.$watch 'filter', (oldValue,newValue) ->
    $scope.filteredCards.length = 0
    filter = $scope.filter.toLowerCase()
    if Data.cards? and $scope.filter.length>2
       Data.cards |> _.each (card) ->
        switch card.name.toLowerCase().indexOf(filter) >= 0
        | false =>
        | otherwise => $scope.filteredCards.push card
    else
      $scope.filteredCards = []

  $scope.clearFilter = ->
    $scope.filter = ''

  $scope.isReady = ->
    $scope.ready


  $scope._updateCount = (mid,countDefault,delta,fcountDefault,fdelta) ->
    if !Data.cardsByMultiverseid[mid].count?
      Data.cardsByMultiverseid[mid].count = 0
    Data.cardsByMultiverseid[mid].count += delta
    if !Data.cardsByMultiverseid[mid].fcount?
      Data.cardsByMultiverseid[mid].fcount = 0
    Data.cardsByMultiverseid[mid].fcount += fdelta


  $scope.updateCount = (mid,delta,fdelta) ->
    Api.updateCollection { mid: mid, delta:delta, fdelta:fdelta }, ->
      $scope._updateCount mid,0,delta,0,fdelta


importController = ($scope,Api,Data) ->
  $scope.status = 'selecting'
  $scope.lines = []

  $scope.read = ->
    $scope.lines.length = 0
    reader = new FileReader()
    reader.onload = (event) ->
      data = event.target.result
      lines = data.split('\n')
      lines |> _.each (line) ->
        if line.length>0
          tokens = line.split /\"[\s]*,[\s]*\"/ |> _.map (item) ->
            item.replace /\"/g, ''
            .trim!
          |> _.filter (item) ->
            item.length > 0

          $scope.lines.push tokens
      $scope.status = 'mapping'

      $scope.lookup = ['Card Name','Set Name','Count','Foil Count']
      $scope.columns = []
      for i to $scope.lines[0].length-1
        $scope.columns.push ''

      $scope.$apply!

      #Api.importCollection { data: event.target.result }, (result) ->
      #  console.log result

    reader.readAsText $scope.importFile

  $scope.validateMapping = (index) ->
    for i to $scope.columns.length-1
      switch i==index
      | true =>
      | otherwise =>
        switch $scope.columns[i] == $scope.columns[index]
        | false =>
        | otherwise => $scope.columns[i] = ''


  $scope.errorLines = []
  $scope.mapAndValidate = ->
    $scope.errorLines.length = 0
    $scope.status = 'validating'
    for line in $scope.lines
      matches = Data.cards |> _.filter (item) ->
        item.name == line[2] and item.set.name == line[1]
      switch matches.length
      | 0 => $scope.errorLines.push line
      | 1 =>
      | otherwise => $scope.errorLines.push line

  $scope.import = ->
    $scope.status = 'done'











exploreController = ($scope,Errors,Api) ->


apiFactory = ($resource,ErrorHandler) ->
  do
    importCollection: (data,cb) ->
      $resource '/api/v1/collections/import', null
      .save {}, data, cb, ErrorHandler

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

dataFactory = ($http,$q) ->
  retVal = do
    sets: []
    setsByCode: {}
    cards: []
    cardsByMultiverseid: {}
    loaded:false

  retVal.setsLoaded = $http.get '/api/v1/sets'
  retVal.cardsLoaded = $http.get '/api/v1/cards'

  retVal.allDataLoaded = $q.all [retVal.setsLoaded, retVal.cardsLoaded]
  .then (responses) ->
    sets = responses[0].data
    cards = responses[1].data

    retVal.sets = sets
    for set in sets
      retVal.setsByCode[set.code] = set

    retVal.cards = cards
    for card in cards
      retVal.cardsByMultiverseid[card.mid] = card
      card.set = retVal.setsByCode[card.setCode]
  , (error) ->
    console.log 'Some error ',error
  , ->
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

  .when '/import', do
    templateUrl: 'import.html'
    controller: 'importController'

  .otherwise do
    redirectTo: '/home'

  switch window.File? and window.FileReader? and window.FileList? and window.Blob?
  | true =>
  | otherwise => alert "The File APIs are not fully supported in this browser.#{window.File},#{window.FileReader} "


app = angular.module 'app',['ngResource','ngRoute','ngFacebook']

app.factory 'Api',['$resource','ErrorHandler',apiFactory]
app.factory 'ErrorHandler',['Errors',errorHandlerFactory]
app.factory 'Data', ['$http','$q',dataFactory]

app.value 'Errors',[]

app.controller 'menuController', ['$scope','FB','FBStatus',menuController]
app.controller 'menuItemController', ['$scope','$location','FBStatus',menuItemController]
app.controller 'errorController', ['$scope','Errors',errorController]


app.controller 'homeController', ['$scope','FBStatus',homeController]
app.controller 'captureController', ['$scope','Errors','Api','Data',captureController]
app.controller 'importController', ['$scope','Api','Data',importController]
app.controller 'exploreController', ['$scope','Errors','Api',exploreController]

app.config ['$routeProvider',config]


app.directive 'file', ->    # This needs to be extracted and made to handle multiple files
  require:"ngModel",
  restrict: 'A',
  link: (scope, el, attrs, ngModel) ->
    el.bind 'change', (event) ->
      files = event.target.files
      file = files[0]
      ngModel.$setViewValue file
      scope.$apply!
