Template.Hast.rendered = ->
  class Panel
    constructor: ->
      @editor = ace.edit('editor')
      @editor.setTheme "ace/theme/chrome"
      @editor.getSession().setMode "ace/mode/markdown"
      @editor.getSession().setUseWrapMode true
      @markedOptions =
        langPrefix: "language-"
      @converter = (md) ->
        marked(md, @markOptions)
      @currentSlide = 0
      @isSyncDeck = false
      @timerRefresh = undefined
      @timerSave = undefined
      @isOwner = false
      @pageDivider = '////'

    getPageNumFromEditor: =>
      currentRow = @editor.getCursorPosition().row
      textLines = @editor.getValue().split('\n')
      pageNum =
        (
          (if _.str.contains(val, @pageDivider) \
          and i <= currentRow then 1 else 0
          ) for val, i in textLines
        )
      result = _.countBy pageNum, (num)->
        if num is 1 then 'count' else 'junk'
      @currentSlide = result.count?=0

    setTimerSave: (callback) ->
      @timerRefresh = Meteor.setTimeout(->
        callback()
      , 3000)
    setTimerRefresh: (callback) ->
      @timerSave = Meteor.setTimeout(->
        callback()
      , 300)
    setTimerClear: =>
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
        @currentSlide = to
        $.deck("getSlide", from).attr "id", ""
        $.deck("getSlide", to).attr "id", "deck-current"
        if Session.get('isDemoMode') is false \
        and @isOwner is true \
        and Session.get('isInFullScreen') is true \
        and @isSyncDeck is true
          Files.update Session.get("hastId"), $set:
            currentSlide: @currentSlide

    handleEditorChange: ->
      @editor.on "change", (data)=>
        @setTimerClear()
        @setTimerRefresh =>
          @refreshDeck()
          @refreshMathJax("deck-current")
        @setTimerSave =>
          @saveData()
          @refreshMathJax("deck-container")
      @editor.on "changeSelection", =>
        $.deck "go", @getPageNumFromEditor()

    init: ->
      @handleEditorChange()
      @setData()
      @refreshDeck()
      @handleDeckChange()
      @setMathJax()
      @setFullScreenHandler()

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
      @flashMessage('Saving...')
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
      $("#deck-container").html getSlidesHtmls(slidesMd, @converter) + '
        <a href="#" class="deck-prev-link" title="Previous">&#8592;</a>
        <a href="#" class="deck-next-link" title="Next">&#8594;</a>
        <p class="deck-status">
        <span class="deck-status-current"></span>
        /
        <span class="deck-status-total"></span>
        </p>
      '
      $("#deck-container").find('a').attr('target', '_blank')
      Prism.highlightAll()
      $.deck ".slide"
      $.deck "go", @currentSlide

    setReadOnlyMode: =>
      unless @isOwner
        @editor.setReadOnly true
        $('.editor-header-message').html('(Read Only)')
        Meteor.subscribe 'Hast', Session.get('hastId')
        Files.find(Session.get('hastId')).observeChanges
          changed: (id, fields) =>
            if fields.content?
              @editor.setValue fields.content, -1
            if @isSyncDeck is true and fields.currentSlide?
              $.deck("go", fields.currentSlide)
            @refreshDeck
            @refreshMathJax

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
        $('.save-btn').removeClass('no-display')
        Meteor.call 'demoContent', (err, demoContent)=>
          @editor.setValue(
            localStorage.getItem('demoContent') or demoContent or "loading..."
            -1
          )
      Session.whenFalse 'isDemoMode', =>
        $('.save-btn').addClass('no-display')
        Meteor.call 'getHast', Session.get('hastId'), (err, file) =>
          if file
            @editor.setValue file.content or "loading...", -1
            @isOwner = if file.userId is Meteor.userId() then true else false
            @setReadOnlyMode()
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
