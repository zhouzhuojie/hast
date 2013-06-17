Template.Hast.isDemoMode = ->
  Session.get 'isDemoMode'

Template.Hast.isInFullScreen= ->
  Session.get 'isInFullScreen'

Template.Hast.rendered = ->
  class Panel
    constructor: ->
      @editor = ace.edit('editor')
      @editor.setTheme "ace/theme/chrome"
      @editor.getSession().setMode "ace/mode/markdown"
      @editor.getSession().setUseWrapMode true
      @converter = new Markdown.Converter
      @currentSlide = 0
      @timer = undefined
      @isOwner = false
      @isDemoMode = Session.get 'isDemoMode'

    setTimerSave: (callback) ->
      @timer = Meteor.setTimeout(->
        callback()
      , 3000)
    setTimerRefresh: (callback) ->
      @timer = Meteor.setTimeout(->
        callback()
      , 500)
    setTimerClear: =>
      Meteor.clearTimeout @timer

    saveData: =>
      if @editor.getReadOnly() is false
        if @isDemoMode
          localStorage.setItem 'demoContent', @editor.getValue()
          @flashMessage "Saved in local"
        else
          Files.update Session.get("hastId"), $set:
            content: @editor.getValue()
            title: @getTitle()
          @flashMessage "Saved in server"

    init: ->
      $(document).on "deck.change", (event, from, to) =>
        @currentSlide = to
        $.deck("getSlide", from).attr "id", ""
        $.deck("getSlide", to).attr "id", "deck-current"

      @editor.on "change", =>
        @setTimerClear()
        @setTimerRefresh =>
          @refreshDeck()
          @refreshMathJax("deck-current")

        @setTimerSave =>
          @saveData()
          @refreshMathJax("deck-container")

      @setData()
      @setMathJax()
      if Session.get('isInFullScreen') is true
        $('.full-screen-related').addClass('inFullScreen')
      else
        $('.full-screen-related').removeClass('inFullScreen')

    setMathJax: ->
      (->
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
      )()
      Meteor.setTimeout (=> @refreshMathJax("deck-container")), 1000

    refreshMathJax: (elementId) ->
      MathJax.Hub.Queue ["Typeset", MathJax.Hub, elementId]

    flashMessage: (message)->
      $("#message-notice").html(message).fadeIn(500).fadeOut(2000)

    refreshDeck: ->
      slidesMd = @editor.getValue().replace(/\\\\/g, "\\\\\\\\").split("////")
      getSlidesHtmls = (Mds, c) ->
        _.reduce _.map(Mds, (slide, index) ->
          if index is 0
            "<section class=\"slide\" id=\"title-slide\">
            #{c.makeHtml(slide)}
            </section>"
          else
            "<section class=\"slide\">#{c.makeHtml(slide)}</section>"
        ), (a, b) -> (a + b)
      $("#deck-container").html getSlidesHtmls(slidesMd, @converter)
      $.deck ".slide"
      $.deck "go", @currentSlide

    setReadOnlyMode: =>
      unless @isOwner
        @editor.setReadOnly true
        $('.editor-header-message').html('(Read Only)')
        query = Files.find(Session.get('hastId'))
        handle = query.observeChanges
          changed: (id, fields) =>
            @editor.setValue fields.content, -1
            @refreshDeck
            @refreshMathJax

    getTitle: ->
      titleString = @converter.makeHtml(
        @editor.getValue().split("////")[0]
      ).split("\n")[0]

      if titleString.indexOf("<h1>") is 0
        titleString.slice 4, -5
      else
        ""

    setData: ->
      if @isDemoMode is true
        Meteor.subscribe "newHast", =>
          file = Files.findOne(test: true)
          Session.set "hastId", file._id
          @editor.setValue localStorage.getItem('demoContent') or
            file.content or "loading...",
            -1
      else
        Meteor.subscribe "Hast", Session.get("hastId"), =>
          file = Files.findOne(Session.get("hastId"))
          if file
            @editor.setValue file.content or "loading...", -1
            @isOwner = if file.userId is Meteor.userId() then true else false
            @setReadOnlyMode()
          else
            @flashMessage "Not found!"
      @refreshDeck()

  window.panel = new Panel
  window.panel.init()

Template.Hast.events
  "click .save-btn": ->
    panel = window.panel
    if Meteor.user()
      file = Files.findOne(Session.get('hastId'))
      Meteor.call "addFile",
        title: panel.getTitle()
        content: panel.editor.getValue()
        test: file.test
        fileId: file._id
      , (error, result) ->
        panel.flashMessage result.message
        Meteor.Router.to "/hast/" + result.fileId

    else
      panel.flashMessage "Please log in to save your own files"

  "click .mathjax-btn": ->
    window.panel.refreshMathJax 'deck-container'

  "click .full-screen-btn": ->
    Session.set 'isInFullScreen', true

  "click .exit-full-screen-btn": ->
    window.panel.saveData()
    Session.set 'isInFullScreen', false

