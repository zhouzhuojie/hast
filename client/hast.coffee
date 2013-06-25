EventHorizon.fireWhenTrue 'loggedIn', ->
  return Meteor.userId()?

EventHorizon.on 'loggedIn', ->
  location.reload()

Deps.autorun ->
  Meteor.subscribe "hast", Session.get("hastId")

Template.Hast.mode = ->
  Session.get 'isDemoMode'

Template.Hast.rendered = ->
  class Panel
    constructor: ->
      @editor = ace.edit('editor')
      @editor.setTheme "ace/theme/chrome"
      @editor.getSession().setMode "ace/mode/markdown"
      @editor.getSession().setUseWrapMode true
      @Range = ace.require('ace/range').Range
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
      @timerRefresh = undefined
      @timerSave = undefined
      @isOwner = false
      @pageDivider = '////'
      @timerSaveInterval = 800
      @timerRefreshInterval= 300

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
        i for val, i in textLines when _.str.contains(val, @pageDivider)
      )

    getPageNumFromEditor: ->
      currentRow = @editor.getCursorPosition().row
      @setPageNum()
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
        $.deck("getSlide", from).removeAttr 'id'
        $.deck("getSlide", to).attr "id", "deck-current"
        unless @editor.isFocused()
          @editor.getSelection().setRange(@getPageRange(to))
          @editor.centerSelection()
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
        @setTimerSave =>
          @saveData()
          @refreshDeck()
          @refreshMathJax("deck-container")

      @editor.getSelection().on "changeCursor", =>
        targetSlide = @getPageNumFromEditor()
        $.deck "go", targetSlide

    init: ->
      @setData()
      @refreshDeck()
      @setMathJax()
      @setFullScreenHandler()
      @handleEditorChange()
      @handleDeckChange()
      @editor.focus()
      return null

    setFullScreenHandler: ->
      Session.whenTrue 'isInFullScreen',
        ->
          $('.full-screen-related').addClass('inFullScreen')
        , true
      Session.whenFalse 'isInFullScreen',
        ->
          $('.full-screen-related').removeClass('inFullScreen')
        , true

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

    flashMessage: (message)->
      $("#message-notice")
        .stop(true, true)
        .html(message)
        .show()
        .fadeOut(3000)

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

    refreshCurrentDeck: ->
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
              if $.windowActive is false or @isOwner is false
                @editor.setValue fields.content, -1
            if @isSyncDeck is true and fields.currentSlide?
              $.deck("go", fields.currentSlide)
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
        ""

    setData: ->
      Session.whenTrue 'isDemoMode', =>
        $('.sync-deck-btn').addClass('no-display')
        $('.save-btn').removeClass('no-display')
        Meteor.call 'demoContent', (err, demoContent)=>
          @editor.setValue(
            localStorage.getItem('demoContent') or demoContent or "loading..."
            -1
          )
          @setPageNum()
      Session.whenFalse 'isDemoMode', =>
        $('.sync-deck-btn').removeClass('no-display')
        $('.save-btn').addClass('no-display')
        Meteor.call 'getHast', Session.get('hastId'), (err, file) =>
          if file
            @editor.setValue file.content or "loading...", -1
            @setPageNum()
            @isOwner = if file.userId is Meteor.userId() then true else false
            @setDataListener()
          else
            Meteor.Router.to '/404'

  window.panel = new Panel
  window.panel.init()

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
      )
    else
      panel.flashMessage "Please log in to save your own files"

  "click .mathjax-btn": ->
    window.panel.refreshMathJax 'deck-container'

  "click .full-screen-btn": ->
    Session.set 'isInFullScreen', true

  "click .exit-full-screen-btn": ->
    window.panel.saveData()
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
