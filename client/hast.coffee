EventHorizon.fireWhenTrue 'loggedIn', ->
  return Meteor.userId()?

EventHorizon.on 'loggedIn', ->
  location.reload()

Deps.autorun ->
  Meteor.subscribe "hast", Session.get("hastId")

Template.Hast.mode = ->
  Session.get 'isDemoMode'

class Panel
  constructor: ->
    @markedOptions =
      gfm: true,
      tables: true,
      breaks: false,
      pedantic: false,
      sanitize: true,
      smartLists: true,
      smartypants: false,
      langPrefix: 'language-',
    @converter = (md) ->
      marked(md, @markOptions)
    @currentSlide = 0
    @isSyncDeck = true
    @isOwner = false
    @timeSave = undefined
    @timeRefresh = undefined
    @pageDivider = /\/{4,}/
    @timerSaveInterval = 1800
    @timerRefreshInterval= 300
    @windowActive = false
    @normalFitRatio = 4
    @fullScreenFitRatio = 6.5

  setEditor: ->
    @editor = ace.edit('editor')
    @editor.setTheme "ace/theme/chrome"
    @editor.getSession().setMode "ace/mode/markdown"
    @editor.getSession().setUseWrapMode true
    @Range = ace.require('ace/range').Range

  getPageRange: (page)->
    if @pageNum?.length >= 1
      if page is 0
        [r1, r2] = [0, @pageNum[0]]
      else if page >= (@pageNum.length)
        [r1, r2] = [
          @pageNum[@pageNum.length - 1]
        , @editor.getSession().getLength() - 1
        ]
      else
        [r1, r2] = [@pageNum[page - 1], @pageNum[page]]
      return r = new @Range(r1, 0, r2, 0)
    else
      return r = new @Range(0, 0, 0, 0)

  setPageNum: ->
    textLines = @editor.getValue().split('\n')
    @pageNum = (
      i for val, i in textLines when @pageDivider.test(val)
    )
    @editor.getSession().setAnnotations(
      {row:row, column:0, text:'Page Divider', type: 'info'}\
      for row in @pageNum
    )

  getPageNumFromEditor: ->
    currentRow = @editor.getCursorPosition().row
    unless @pageNum.length is 0
      result = _.map(@pageNum, (num)-> if num<currentRow then 1 else 0)
      result = _.reduce(result, (s,t) -> s + t)
      return @currentSlide = result
    return @currentSlide = 0

  setTimerSave: (callback) ->
    @timerSave= Meteor.setTimeout(=>
      callback()
    , @timerSaveInterval)
  setTimerRefresh: (callback) ->
    @timerRefresh= Meteor.setTimeout(=>
      callback()
    , @timerRefreshInterval)
  setTimerClear: ->
    Meteor.clearTimeout @timerRefresh
    Meteor.clearTimeout @timerSave

  saveData: ->
    if @editor.getReadOnly() is false
      if Session.get('isDemoMode')
        localStorage.setItem 'demoContent', @editor.getValue()
        @flashMessage "Saved in local"
      else
        Files.update Session.get("hastId"), $set:
          content: @editor.getValue()
          title: @getTitle()
        @flashMessage "Saved in server"

  handleDeckChange: ->
    $(document).off "deck.change"
    $(document).on "deck.change", (event, from, to) =>
      unless @editor.isFocused()
        @editor.getSelection().setRange(@getPageRange(to))
        @editor.centerSelection()
      $.deck("getSlide", from).removeAttr 'id'
      $.deck("getSlide", to).attr "id", "deck-current"
      if Session.get('isDemoMode') is false \
      and @isOwner is true \
      and Session.get('isInFullScreen') is true \
      and @isSyncDeck is true
        Files.update Session.get("hastId"), $set:
          currentSlide: @currentSlide

  handleEditorChange: ->
    @editor.getSession().getDocument().on "change", (data)=>
      @setTimerClear()
      @setTimerRefresh =>
        @refreshCurrentDeck()
        @setPageNum()
      @setTimerSave =>
        @saveData()
        @refreshDeck()
        @refreshMathJax("deck-container")

    @editor.getSelection().on "changeCursor", =>
      targetSlide = @getPageNumFromEditor()
      $.deck "go", targetSlide

  init: ->
    @setEditor()
    @setFullScreenHandler()
    @flashMessage('Loading...', 10000)
    setData = @setData()
    setData.done =>
      @flashMessage('Loaded', 1000)
      @refreshDeck()
      @handleEditorChange()
      @handleDeckChange()
      @setPageNum()
      @setMathJax()
      @refreshTheme()
      @refreshTransition()
    @setPanelActiveListener()
    return

  setFullScreenHandler: ->
    Session.whenTrue 'isInFullScreen',
      =>
        $('.full-screen-related').addClass('inFullScreen')
        $("#deck-container").fitText(@fullScreenFitRatio)
      , true
    Session.whenFalse 'isInFullScreen',
      =>
        $('.full-screen-related').removeClass('inFullScreen')
        $("#deck-container").fitText(@normalFitRatio)
      , true

    $(document).keydown (e) ->
      if e.keyCode is 27
        Session.set 'isInFullScreen', false

  refreshTheme: ->
    if @theme?
      themeCss = "/theme/#{@theme}.css"
      $('#theme-link').attr('href', themeCss)

  refreshTransition: ->
    if @transition?
      transitionCss = "/transition/#{@transition}.css"
      $('#transition-link').attr('href', transitionCss)

  setTheme: ->
    if @theme?
      if Session.get('isDemoMode') is true
        localStorage.setItem 'theme', @theme
      else
        if @isOwner is true
          Files.update Session.get("hastId"), $set:
            theme : @theme

  setTransition: ->
    if @transition?
      if Session.get('isDemoMode') is true
        localStorage.setItem 'transition', @transition
      else
        if @isOwner is true
          Files.update Session.get("hastId"), $set:
            transition : @transition

  setMathJax: ->
    do ->
      head = document.getElementsByTagName("head")[0]
      script = undefined
      script = document.createElement("script")
      script.type = "text/x-mathjax-config"
      script[((if window.opera then "innerHTML" else "text"))] =
        "MathJax.Hub.Config({" +
        "  tex2jax: { inlineMath: [['$','$'], ['\\\\(','\\\\)']] }," +
        "  processEscapes: true," +
        "  showProcessingMessages: false" +
        "});"
      head.appendChild script
      script = document.createElement("script")
      script.type = "text/javascript"
      script.src = "http://cdn.mathjax.org/mathjax/latest/MathJax.js" +
        "?config=TeX-AMS-MML_HTMLorMML"
      head.appendChild script
    Meteor.setTimeout (=> @refreshMathJax("deck-container")), 1000

  refreshMathJax: (elementId) ->
    MathJax.Hub.Queue ["Typeset", MathJax.Hub, elementId]

  flashMessage: (message, time=3000) ->
    $("#message-notice")
      .stop(true, true)
      .html(message)
      .show()
      .fadeOut(time)

  setPanelActiveListener: ->
    window.focus =>
      @windowActive = true
    window.blur =>
      @windowActive = false

  refreshDeck: ->
    slidesMd = @editor.getValue().replace(/\\\\/g, "\\\\\\\\") \
      .split(@pageDivider)
    getSlidesHtmls = (Mds, c) ->
      _.reduce _.map(Mds, (slide, index) ->
        if index is 0
          "<section class=\"slide\" id=\"title-slide\">
          #{c(slide)}
          </section>"
        else
          "<section class=\"slide\">#{c(slide)}</section>"
      ), (a, b) -> (a + b)
    $("#deck-container").html getSlidesHtmls(slidesMd, @converter)
    $("#deck-container").find('a').attr('target', '_blank')
    Prism.highlightAll()
    $.deck ".slide"
    $.deck "go", @currentSlide
    $("#deck-container").fitText(@normalFitRatio)


  refreshCurrentDeck: ->
    if @editor.getReadOnly() is false
      @flashMessage('Saving...')
    slideMd = @editor.getValue().replace(/\\\\/g, "\\\\\\\\") \
      .split(@pageDivider)[@currentSlide]
    $.deck('getSlide', @currentSlide).html(@converter(slideMd))
    Prism.highlightAll()
    @refreshMathJax("deck-current")

  setDataListener: ->
    unless @isOwner
      @editor.setReadOnly true
      $('.editor-header-message').html('(Read Only)')
    Files.find(Session.get('hastId')).observeChanges
      changed: _.debounce(
        (id, fields) =>
          if fields.content?
            if @editor.isFocused() is false or @isOwner is false
              @editor.setValue fields.content, -1
          if @isSyncDeck is true and fields.currentSlide?
            $.deck("go", fields.currentSlide)
          if @isSyncDeck is true and fields.theme?
            @theme = fields.theme
            @refreshTheme()
          if @isSyncDeck is true and fields.transition?
            @transition = fields.transition
            @refreshTransition()
          @refreshDeck
          @refreshMathJax
        , 100
        , false
      )

  getTitle: ->
    titleString = @converter(
      @editor.getValue().split(@pageDivider)[0]
    ).split("\n")[0]

    if titleString.indexOf("<h1>") is 0
      titleString.slice 4, -5
    else
      "Untitled"

  setData: ->
    dataDeferred = $.Deferred()
    if Session.get('isDemoMode') is true
      $('.sync-deck-btn').addClass('no-display')
      $('.save-btn').removeClass('no-display')
      @editor?.setValue(
        localStorage.getItem('demoContent') or demoContent or "loading..."
        -1
      )
      @theme = localStorage.getItem 'theme'
      @transition = localStorage.getItem 'transition'
      dataDeferred.resolve()
    else
      $('.sync-deck-btn').removeClass('no-display')
      $('.save-btn').addClass('no-display')
      Meteor.call 'getHast', Session.get('hastId'), (err, file) =>
        if file?
          @editor?.setValue file.content or "loading...", -1
          @theme = file.theme
          @transition = file.transition
          @isOwner = if file.userId is Meteor.userId() then true else false
          @setDataListener()
          dataDeferred.resolve()
        else
          Meteor.Router.to '/404'
    return dataDeferred.promise()

class SingletonPanel
  instance = null
  @get : ->
    if instance?
      instance.init()
      return instance
    else
      return @new()
  @new : ->
    instance = new Panel()
    instance.init()
    return instance

Template.Hast.rendered = ->
  window.panel = SingletonPanel.get()

Template.Hast.events
  "click .save-btn": ->
    panel = window.panel
    if Meteor.user()
      Meteor.call(
        "addFile"
        title: panel.getTitle()
        content: panel.editor.getValue()
        (error, result) ->
          panel.flashMessage result.message
          Meteor.Router.to "/hast/" + result.fileId
          panel.setData()
          bootbox.alert "
            Congratulations! Your hast has been saved in the cloud.
            You can easily manage them in the archives.
          "
      )
    else
      bootbox.alert "
        Oops, please log in to save and share your own hast in the cloud.
        Your current hast is already saved in localStorage anyway.
      "

  "click .mathjax-btn": ->
    window.panel.refreshMathJax 'deck-container'

  "click .full-screen-btn": ->
    Session.set 'isInFullScreen', true

  "click .exit-full-screen-btn": ->
    Session.set 'isInFullScreen', false

  "click .sync-deck-btn": ->
    panel = window.panel
    if panel.isSyncDeck is true
      panel.isSyncDeck = false
      panel.handleDeckChange()
      $('.sync-deck-btn').html('Sync Play: Off').removeClass('btn-info')
    else
      panel.isSyncDeck = true
      panel.handleDeckChange()
      $('.sync-deck-btn').html('Sync Play: On').addClass('btn-info')

  "click .theme-selection": (event)->
    panel = window.panel
    panel.theme = $(event.target).html().toLowerCase()
    panel.refreshTheme()
    panel.setTheme()

  "click .transition-selection": (event)->
    panel = window.panel
    panel.transition = $(event.target).html().toLowerCase()
    panel.refreshTransition()
    panel.setTransition()
