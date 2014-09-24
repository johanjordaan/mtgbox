
fbDirective = (FB,FBStatus) ->
  post = (scope, iElem, iAttrs, controller) ->
    fbAppId = iAttrs.appId || ''

    fbParams = do
      appId: iAttrs.appId || "",
      cookie: iAttrs.cookie || true,
      status: iAttrs.status || true,
      xfbml: iAttrs.xfbml || true

    window.fbAsyncInit = ->
        FB._init fbParams

        if 'fbInit' in iAttrs
            iAttrs.fbInit!

        FB.getLoginStatus (response) ->
          switch response.status
          | 'connected' =>
            FBStatus.loggedIn = true
            FB.api '/me', (response) ->
              FBStatus.ready = true
              FBStatus.name = response.name
              console.log FBStatus
              scope.$apply!
          | otherwise =>
            FBStatus.ready = true
            FBStatus.loggedIn = false
            FBStatus.name = ''
            console.log FBStatus
            scope.$apply!


    load = (d, s, id, fbAppId) ->
      fjs = d.getElementsByTagName(s)[0];
      if (d.getElementById(id)) then return;
      js = d.createElement(s); js.id = id; js.async = true;
      js.src = "//connect.facebook.net/en_US/all.js";
      fjs.parentNode.insertBefore(js, fjs);

    load document,'script','facebook-jssdk', fbAppId

  retVal = do
    restrict: "E",
    replace: true,
    template: "<div id='fb-root'></div>",
    compile: (tElem, tAttrs) -> { post: post }

fbFactory = ($rootScope,FBStatus) ->
  _fb = do
    _init: (params) ->
      if window.FB
        angular.extend(window.FB, _fb)
        angular.extend(_fb, window.FB)

        FBStatus.loaded = true

        window.FB.init params

        if !$rootScope.$$phase then $rootScope.$apply!

module = angular.module 'ngFacebook', []
module.directive 'ngFacebook', ['FB','FBStatus', fbDirective]
module.factory 'FB', ['$rootScope','FBStatus',fbFactory]
module.value 'FBStatus', { loaded:false , name:'', loggedIn:false, ready:false}
