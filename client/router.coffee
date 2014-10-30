Router.configure
  layoutTemplate: 'layout'

Router.map ->

  @route 'home',
    path: '/'
    template: 'Hast'
    onBeforeAction: ->
      Session.set "isDemoMode", true
      if @params.f is 'true'
        Session.set "isInFullScreen", true
      else
        Session.set "isInFullScreen", false
      @next()

  @route 'oldHast',
    template: 'oldHast'
    path: '/archives'
    waitOn: ->
      Meteor.subscribe "oldHast"
    data: ->
      files = Files.find({userId: Meteor.userId()}, {sort: {submitted: -1}})
      return {
        files: files
      }

  @route 'hast',
    path: '/hast/:_id'
    template: 'Hast'
    onBeforeAction: ->
      id = @params._id
      Session.set "isDemoMode", false
      Session.set "hastId", id
      if @params.f is 'true'
        Session.set "isInFullScreen", true
      else
        Session.set "isInFullScreen", false
      @next()

  @route 'not_found',
    path: "*"
