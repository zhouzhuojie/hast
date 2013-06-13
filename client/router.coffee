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
      Session.set "test", true
      if getParameterByName('isInFullScreen') is 'true'
        Session.set "isInFullScreen", true
      else
        Session.set "isInFullScreen", false
      "Hast"
  "/archives":
    to: "oldHast"
    as: "archives"
  "/hast/:id":
    to: (id) ->
      Session.set "test", false
      Session.set "hastId", id
      if getParameterByName('isInFullScreen') is 'true'
        Session.set "isInFullScreen", true
      else
        Session.set "isInFullScreen", false
      "Hast"
  "*": "not_found"
