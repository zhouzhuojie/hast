Deps.autorun ->
  Meteor.subscribe "hast", Session.get("hastId") || ''

Template.Hast.mode = ->
  Session.get 'isDemoMode'

Handlebars.registerHelper '$or', (a, b) ->
  return (a || b)

Meteor.startup ->
  window.flashMessage =  (message, time=5000) ->
    $("#message-notice")
      .stop(true, true)
      .html(message)
      .show()
      .fadeOut(time)

  class Panel
    constructor: ->
      kramed.options
        katex: true
      @cache = kizzy 'local-hast'
      @cacheExpire = 1000*3600*48 # expires after 2 days
      @markedOptions =
        gfm: true,
        tables: true,
        breaks: false,
        pedantic: false,
        sanitize: true,
        smartLists: true,
        smartypants: false,
        langPrefix: 'language-',
      @converter = (md) -> kramed md
      @currentSlide = 0
      @isSyncDeck = true
      @isOwner = false
      @timeSave = undefined
      @timeRefresh = undefined
      @pageDivider = /\/{4,}/
      @timerSaveInterval = 3000
      @timerRefreshInterval= 600
      @windowActive = false
      @normalFitRatio =
        lineRatio: 1.8
        fontRatio: 60
      @fullScreenFitRatio =
        lineRatio: 1.7
        fontRatio: 70

    init: ->
      if document.getElementById('editor')?
        @setEditor()
        @setFullScreenHandler()
        flashMessage('Loading...', 10000)
        setData = @setData()
        setData.done =>
          flashMessage('Loaded', 1000)
          @refreshDeck()
          @handleDeckChange()
          @setPageNum()
          @refreshTheme()
          @refreshTransition()
          @handleEditorChange()
        @setPanelActiveListener()

    setEditor: ->
      @editor = ace.edit('editor')
      @editor.setTheme "ace/theme/chrome"
      @editor.getSession().setMode "ace/mode/markdown"
      @editor.getSession().setUseWrapMode true
      @editor.setFontSize 15
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
          @cache.set 'demoContent', @editor.getValue(), @cacheExpire
          flashMessage "Saved in local"
        else
          Files.update Session.get("hastId"), $set:
            content: @editor.getValue()
            title: @getTitle()
          flashMessage "Saved in server"

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
      @editor.getSession().getDocument().on "change", =>
        @setTimerClear()
        @setTimerRefresh =>
          @refreshCurrentDeck()
          @setPageNum()
        @setTimerSave =>
          @saveData()
          @refreshDeck()

      @editor.getSelection().on "changeCursor", _.debounce(
        =>
          targetSlide = @getPageNumFromEditor()
          $.deck "go", targetSlide
        , 200)

    setFullScreenHandler: ->
      Deps.autorun =>
        if Session.equals 'isInFullScreen', true
          $('.full-screen-related').addClass('inFullScreen')
          $("#deck-container").flowtype(@fullScreenFitRatio)
        if Session.equals 'isInFullScreen', false
          $('.full-screen-related').removeClass('inFullScreen')
          $("#deck-container").flowtype(@normalFitRatio)

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
          @cache.set 'theme', @theme, @cacheExpire
        else
          if @isOwner is true
            Files.update Session.get("hastId"), $set:
              theme : @theme

    setTransition: ->
      if @transition?
        if Session.get('isDemoMode') is true
          @cache.set 'transition', @transition, @cacheExpire
        else
          if @isOwner is true
            Files.update Session.get("hastId"), $set:
              transition : @transition

    setPanelActiveListener: ->
      window.focus =>
        @windowActive = true
      window.blur =>
        @windowActive = false

    refreshDeck: ->
      slidesMd = @editor.getValue().split(@pageDivider)
      getSlidesHtmls = (Mds, c) ->
        _.reduce _.map(Mds, (slide, index) ->
          if index is 0
            "<section class=\"slide\" id=\"title-slide\">
            #{c(slide)}
            </section>"
          else
            "<section class=\"slide\">#{c(slide)}</section>"
        ), (a, b) -> (a + b)
      renderedHtml = getSlidesHtmls(slidesMd, @converter)
      $("#deck-container").html renderedHtml
      $("#deck-container").find('a').attr('target', '_blank')
      Prism.highlightAll()
      $.deck ".slide"
      $.deck "go", @currentSlide

    refreshCurrentDeck: ->
      if @editor.getReadOnly() is false
        flashMessage('Saving...')
      slideMd = @editor.getValue().split(@pageDivider)[@currentSlide]
      $.deck('getSlide', @currentSlide).html(@converter(slideMd))
      Prism.highlightAll()

    setDataListener: ->
      unless @isOwner
        @editor.setReadOnly true
        $('.editor-header-message').html('(Read Only)')
        Session.set "isInFullScreen", true
      Files.find(Session.get('hastId')).observeChanges
        changed: _.debounce(
          (id, fields) =>
            if fields.content?
              if @editor.isFocused() is false or @isOwner is false
                @editor.setValue fields.content, -1
                $.deck("go", @currentSlide)
            if @isSyncDeck is true and fields.currentSlide?
              $.deck("go", fields.currentSlide)
            if @isSyncDeck is true and fields.theme?
              @theme = fields.theme
              @refreshTheme()
            if @isSyncDeck is true and fields.transition?
              @transition = fields.transition
              @refreshTransition()
            @refreshDeck
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
          @cache.get('demoContent') or demoContent
          -1
        )
        @theme = @cache.get 'theme'
        @transition = @cache.get 'transition'
        dataDeferred.resolve()
      else
        $('.sync-deck-btn').removeClass('no-display')
        $('.save-btn').addClass('no-display')
        Meteor.call 'getHast', Session.get('hastId'), (err, file) =>
          if file?
            @editor?.setValue file.content, -1
            @theme = file.theme
            @transition = file.transition
            @isOwner = if file.userId is Meteor.userId() then true else false
            @setDataListener()
            dataDeferred.resolve()
          else
            Router.go '/404'
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

  window.SingletonPanel = SingletonPanel

Template.Hast.rendered = ->
  window.panel = window.SingletonPanel?.get()

Deps.autorun ->
  Session.get "isDemoMode"
  window.panel = window.SingletonPanel?.get()

Template.Hast.events
  "click .deck-prev-link": ->
    $.deck('prev')
  "click .deck-next-link": ->
    $.deck('next')
  "click .save-btn": ->
    panel = window.panel
    if Meteor.user()
      Meteor.call(
        "addFile"
        title: panel.getTitle()
        content: panel.editor.getValue()
        (error, result) ->
          flashMessage result.message
          Router.go '/hast/' + result.fileId
          bootbox.alert "
            Congratulations! Your hast has been saved in the cloud.
            You can easily manage them in the archives.
          "
      )
    else
      flashMessage "Oops, please log in to save.", 6000

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

  "click .phone-controll-btn-prev": ->
    $.deck "prev"

  "click .phone-controll-btn-next": ->
    $.deck "next"
