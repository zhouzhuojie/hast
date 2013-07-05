@getParameterByName = (name) ->
  name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]")
  regex = new RegExp("[\\?&]" + name + "=([^&#]*)")
  results = regex.exec(location.search)
  if results?
    decodeURIComponent(results[1].replace(/\+/g, " "))
  else
    ''

Meteor.Router.add
  "/":
    as: "home"
    to: ->
      Session.set "isDemoMode", true
      if getParameterByName('f') is 'true'
        Session.set "isInFullScreen", true
      else
        Session.set "isInFullScreen", false
      "Hast"
  "/archives":
    to: ->
      "oldHast"
    as: "archives"
  "/hast/:id":
    as: 'hastIdRoute'
    to: (id) ->
      Session.set "isDemoMode", false
      Session.set "hastId", id
      if getParameterByName('f') is 'true'
        Session.set "isInFullScreen", true
      else
        Session.set "isInFullScreen", false
      "Hast"
  "*":
    as: "not_found"
    to: "not_found"

# Google Analytics, Change to your own id
`
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

  ga('create', 'UA-42227346-1', 'hast.me');
  ga('send', 'pageview');
`
