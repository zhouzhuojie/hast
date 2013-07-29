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

Template.setup.rendered = ->
  if !window._gaq?
    window._gaq = []
    _gaq.push(['_setAccount', 'UA-42227346-1'])
    _gaq.push(['_trackPageview'])

    (->
      ga = document.createElement('script')
      ga.type = 'text/javascript'
      ga.async = true
      gajs = '.google-analytics.com/ga.js'
      ga.src = if 'https:' is document.location.protocol then\
        'https://ssl'+gajs else\
        'http://www'+gajs
      s = document.getElementsByTagName('script')[0]
      s.parentNode.insertBefore(ga, s)
    )()
