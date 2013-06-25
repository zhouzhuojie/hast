url = "http://192.168.1.130:3000/"
casper = require('casper').create
  verbose: true

info = (message) ->
  casper.echo '==================================='
  casper.echo message
  casper.echo '-----------------------------------'

casper.on 'remote.message', (msg) ->
  @echo 'remote message caught: ' + msg

casper.start url, ->
  info 'Starting...'
  @test.assert @getCurrentUrl() is url, 'url is the one expected.'
  @evaluate ->
    localStorage.clear()

casper.then ->
  info 'At home page'

  @test.assertEval ->
    Meteor?
  , 'Load meteor'

  @test.assertEval ->
    Session.get('isDemoMode') is true
  , 'In demo mode'

  @test.assertEval ->
    Meteor.userId() is null
  , 'No user is logged in'

  @test.assertEval ->
    panel.editor.getValue()?
  , 'Editor has loaded data'

  @test.assertEval ->
    panel.editor.getTheme() is 'ace/theme/chrome'
  , 'Editor has set the theme'

  @test.assertEval ->
    panel.editor.getSession().getMode().$id is 'ace/mode/markdown'
  , 'Editor has set the mode markdown'

  @test.assertEval ->
    panel.editor.getSession().getUseWrapMode() is true
  , 'Editor has set wrap mode'

  @test.assertEval ->
    panel.isOwner is false
  , 'is not for the owner'

  @test.assertEval ->
    Session.get('isInFullScreen') is false
  , 'is not in full screen'

  @test.assertEval ->
    panel.currentSlide is 0
  , 'Initial Slide Number'

  @test.assertEval ->
    __utils__.visible('.save-btn')
  , 'Visible for save-btn'

  @wait 800, ->
    @test.assertEval ->
      MathJax?
    , 'Loaded MathJax'

    @test.assertEval ->
      localStorage.getItem('demoContent') is panel.editor.getValue()
    , 'LocalStorage has loaded data'

    @test.assertEval ->
      panel.pageNum?
    , 'Initial pageNum'

    @test.assertEval ->
      panel.pageNum.length is ($.deck('getSlides').length - 1)
    , 'Slide number checked'

    @test.assertEval ->
      $.deck('go', 2)
      panel.editor.getSelection().getRange().start.row isnt 0
    , 'deck -> editor'

    @test.assertEval ->
      panel.editor.getSelection().setRange(
        panel.getPageRange($.deck('getSlides').length - 1)
      )
      panel.currentSlide is ($.deck('getSlides').length - 1)
    , 'editor -> deck'

casper.then ->
  info 'Logging in...'
  @evaluate ->
    Meteor.loginWithPassword 'test1@1.com', '111111'
    return
  @wait 1200

casper.then ->
  @test.assertEval ->
    Session.get('isDemoMode') is true
  , 'In demo mode'

  @test.assertEval ->
    Meteor.userId()?
  , 'User is logged in'

  @test.assertEval ->
    Files.findOne()?
  , 'old hasts loaded'

casper.then ->
  info 'Clicking Save-btn, creating a hast'
  @click '.save-btn'
  @wait 800

casper.then ->
  @test.assertEval ->
    Session.get('isDemoMode') is false
  , 'In hastId mode'

  @test.assertEval ->
    Session.get('hastId')?
  , 'Has hastId'

  @test.assertEval ->
    Files.findOne(Session.get('hastId'))?
  , 'Has hastId file data'

  @test.assertEval ->
    panel.editor.getValue()?
  , 'Editor has loaded data'

  @test.assertEval ->
    panel.editor.getTheme() is 'ace/theme/chrome'
  , 'Editor has set the theme'

  @test.assertEval ->
    panel.editor.getSession().getMode().$id is 'ace/mode/markdown'
  , 'Editor has set the mode markdown'

  @test.assertEval ->
    panel.editor.getSession().getUseWrapMode() is true
  , 'Editor has set wrap mode'

  @test.assertEval ->
    panel.isOwner is true
  , 'is owner'

  @test.assertEval ->
    Session.get('isInFullScreen') is false
  , 'is not in full screen'

  @test.assertEval ->
    panel.currentSlide is 0
  , 'Initial Slide Number'

  @test.assertEval ->
    __utils__.visible('.save-btn') is false
  , 'Invisible for save-btn'


  @wait 800, ->
    @test.assertEval ->
      MathJax?
    , 'Loaded MathJax'

    @test.assertEval ->
      localStorage.getItem('demoContent') is panel.editor.getValue()
    , 'LocalStorage has loaded data'

    @test.assertEval ->
      panel.pageNum?
    , 'Initial pageNum'

    @test.assertEval ->
      panel.pageNum.length is $.deck('getSlides').length - 1
    , 'Slide number checked'

    @test.assertEval ->
      $.deck('go', 2)
      panel.editor.getSelection().getRange().start.row isnt 0
    , 'deck -> editor'

    @test.assertEval ->
      panel.editor.getSelection().setRange(
        panel.getPageRange($.deck('getSlides').length - 1)
      )
      panel.currentSlide is ($.deck('getSlides').length - 1)
    , 'editor -> deck'

casper.then ->
  @click '.full-screen-btn'

casper.then ->
  @test.assertEval ->
    __utils__.visible('.full-screen-btn') is false
  , '.full-screen-btn invisible in Full Screen Mode'

  @test.assertEval ->
    __utils__.visible('.exit-full-screen-btn') is true
  , '.exit-full-screen-btn visible in Full Screen Mode'

casper.then ->
  @click '.full-screen-btn'

casper.then ->
  @test.assertEval ->
    __utils__.visible('.full-screen-btn') is true
  , '.full-screen-btn invisible in Full Screen Mode'

  @test.assertEval ->
    __utils__.visible('.exit-full-screen-btn') is false
  , '.exit-full-screen-btn visible in Full Screen Mode'

casper.then ->
  info 'Removing the test hast'
  @evaluate ->
    Files.remove Session.get 'hastId'
  @wait 800

casper.then ->
  @test.assertEval ->
    Files.findOne(Session.get('hastId')) is undefined
  , 'Has hastId file data deleted'

casper.then ->
  info 'Logging out...'
  @evaluate ->
    Meteor.logout()
    return
  @wait 800

casper.then ->
  @test.assertEval ->
    Meteor.userId() is null
  , 'User is logged out'

casper.run()
