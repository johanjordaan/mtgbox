_ = require 'prelude-ls'

errorController = ($scope,Errors) ->
  $scope.errors = Errors

  $scope.clear = ->
    Errors.length = 0

menuController = ($scope,FB,FBStatus) ->
  $scope.menuItems = [
    { label: 'home'       ,path: '/home'      ,requireAuth: false }
    { label: 'capture'    ,path: '/capture'   ,requireAuth: true }
    ##{ label: 'explore'    ,path: '/explore'   ,requireAuth: true }
    { label: 'stats'    ,path: '/stats'   ,requireAuth: true }

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

captureController = ($scope,$timeout,Api,Data) ->

  $scope.applyFilters = ->

  # Capture
  #
  $scope.ready = false
  Api.getCollection ->
    $scope.ready = true

  $scope.filter = ''
  $scope.filteredCards = []

  $scope.timeout = null
  $scope.$watch 'filter', (oldValue,newValue) ->
    if $scope.timeout? then $timeout.cancel $scope.timeout
    $scope.timeout = $timeout ->
      $scope.applyFilter!
      $scope.timeout = null
    ,500

  $scope.clearFilter = ->
    $scope.filter = ''

  $scope.setFilterEnabled = false
  $scope.textFilterEnabled = true

  $scope.$watch 'setFilterEnabled', (val) ->
    $scope.applyFilter!

  $scope.$watch 'textFilterEnabled', (val) ->
    $scope.applyFilter!

  $scope.applyFilter = ->
    setFilter = []
    Data.setFilter |> _.keys |> _.each (key) ->
      if Data.setFilter[key] then setFilter.push key

    $scope.filteredCards = []
    filter = $scope.filter.toLowerCase()
    if Data.cards? and ($scope.filter.length > 2 or !$scope.textFilterEnabled)
       Data.cards |> _.each (card) ->
        switch
        | $scope.setFilterEnabled and $scope.textFilterEnabled =>
          if card.searchName.indexOf(filter) >= 0 and card.set.code in setFilter
            $scope.filteredCards.push card
        | !$scope.setFilterEnabled and $scope.textFilterEnabled =>
          if card.searchName.indexOf(filter) >= 0
            $scope.filteredCards.push card
        | $scope.setFilterEnabled and !$scope.textFilterEnabled =>
          if card.setCode in setFilter
            $scope.filteredCards.push card

    #$scope.filteredCards = _.take 1000,filteredCards
    #if filteredCards.length > 1000
    #  $timeout ->
    #    for i to 1000
    #      $scope.filteredCards.push filteredCards[i+1000]
    #  ,500


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

setFilterController = ($scope,Data) ->
  $scope.Data = Data

  $scope.selectAll = ->
    for set in $scope.Data.sets
      $scope.Data.setFilter[set.code] = true

  $scope.clearAll = ->
    for set in $scope.Data.sets
      $scope.Data.setFilter[set.code] = false




importController = ($scope,Api,Data) ->
  $scope.status = 'selecting'
  $scope.cardsToImport = []
  $scope.errorLines = []
  $scope.total = 0
  $scope.ftotal = 0

  $scope.read = ->
    reader = new FileReader()
    reader.onload = (event) ->
      data = event.target.result
      lines = data.split('\n')
      lines |> _.each (line) ->
        console.log line
        if line.length>0
          tokens = line.split /\"[\s]*,[\s]*\"/ |> _.map (item) ->
            item.replace /\"/g, ''
            .trim!
          |> _.filter (item) ->
            item.length > 0

          console.log Data.cardsByName[tokens[2]]
          switch
          | tokens.length>=5 =>
            # Find the card
            #
            name = tokens[2]
            setName = tokens[1]
            count = Number(tokens[3])
            fcount = Number(tokens[4])
            card = Data.cardsByName[name] |> _.find (card) -> card.set.name == setName
            switch card?
            | false => $scope.errorLines.push line
            | otherwise =>
              $scope.cardsToImport.push do
                mid: card.mid
                count: count
                fcount: fcount

              $scope.total += count
              $scope.ftotal += fcount
          | otherwise =>

      $scope.status = 'validating'
      $scope.$apply!

    reader.readAsText $scope.importFile

  $scope.import = ->
    Api.importCollection { cardsToImport: $scope.cardsToImport }, (data) ->
      console.log data
      $scope.status = 'done'

exportController = ($scope,Api,Data) ->

exploreController = ($scope,Errors,Api) ->

statsController = ($scope,Api,Data) ->
    $scope.options = do
        chart:
            type: 'discreteBarChart'
            height: 450
            margin :
                top: 20
                right: 20
                bottom: 60
                left: 55
            x: (d) -> d.label
            y: (d) -> d.value
            showValues: true
            valueFormat: (d) ->
                d3.format(',.4f')(d)
            transitionDuration: 500
            xAxis:
                axisLabel: 'X Axis'
            yAxis:
                axisLabel: 'Y Axis'
                axisLabelDistance: 30

    $scope.data = [
        key: "Cumulative Return"
        values: [
            { "label" : "A" , "value" : -29.765957771107 },
            { "label" : "B" , "value" : 0 },
            { "label" : "C" , "value" : 32.807804682612 },
            { "label" : "D" , "value" : 196.45946739256 },
            { "label" : "E" , "value" : 0.19434030906893 },
            { "label" : "F" , "value" : -98.079782601442 },
            { "label" : "G" , "value" : -13.925743130903 },
            { "label" : "H" , "value" : -5.1387322875705 }
            ]
        ]

apiFactory = ($resource,Data,ErrorHandler) ->
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
      _updateCounts = (collectionCards,cb) ->


        collectionCardsByMid = {}
        for card in collectionCards
          collectionCardsByMid[card.mid] = card

        for card in Data.cards
          collectionCard = collectionCardsByMid[card.mid]
          switch collectionCard?
          | true =>
            card.count = collectionCard.count
            card.fcount = collectionCard.fcount
          | otherwise =>
            card.count = 0
            card.fcount = 0
        cb!

      $resource '/api/v1/collections', null
      .query {}, {}, (collectionCards) ->
        Data.allDataLoaded.then ->
          _updateCounts collectionCards, cb
      , ErrorHandler

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
    cardsByName: {}
    loaded:false
    setFilter: {}

  retVal.setsLoaded = $http.get '/api/v1/sets'
  retVal.cardsLoaded = $http.get '/api/v1/cards'

  retVal.allDataLoaded = $q.all [
    retVal.setsLoaded
    retVal.cardsLoaded
  ]
  .then (responses) ->
    sets = responses[0].data
    cards = responses[1].data

    retVal.sets = sets
    for set in sets
      retVal.setsByCode[set.code] = set
      retVal.setFilter[set.code] = false

    retVal.cards = cards
    for card in cards
      if !retVal.cardsByName[card.name]?
        retVal.cardsByName[card.name] = []
      retVal.cardsByName[card.name].push card
      retVal.cardsByMultiverseid[card.mid] = card
      card.count = 0
      card.fcount = 0
      card.set = retVal.setsByCode[card.setCode]
      card.searchName = card.name
      .replace /Æ/g, 'Ae'
      .replace /é/g,'e'
      .replace /à|â|á/g,'a'
      .toLowerCase!

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

  .when '/setFilter', do
    templateUrl: 'setFilter.html'
    controller: 'setFilterController'


  .when '/import', do
    templateUrl: 'import.html'
    controller: 'importController'

  .when '/export', do
    templateUrl: 'export.html'
    controller: 'exportController'

  .when '/stats', do
    templateUrl: 'stats.html'
    controller: 'statsController'


  .otherwise do
    redirectTo: '/home'

app = angular.module 'app',[
  'ngResource'
  'ngRoute'
  'ui.bootstrap'
  'trNgGrid'
  'nvd3'
  'ngFacebook'
]

app.factory 'Api',['$resource','Data','ErrorHandler',apiFactory]
app.factory 'ErrorHandler',['Errors',errorHandlerFactory]
app.factory 'Data', ['$http','$q',dataFactory]

app.value 'Errors',[]

app.controller 'menuController', ['$scope','FB','FBStatus',menuController]
app.controller 'menuItemController', ['$scope','$location','FBStatus',menuItemController]
app.controller 'errorController', ['$scope','Errors',errorController]

app.controller 'homeController', ['$scope','FBStatus',homeController]
app.controller 'captureController', ['$scope','$timeout','Api','Data',captureController]


app.controller 'setFilterController', ['$scope','Data',setFilterController]
app.controller 'importController', ['$scope','Api','Data',importController]
app.controller 'exportController', ['$scope','Api','Data',exportController]

app.controller 'statsController', ['$scope','Errors','Api',statsController]
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
