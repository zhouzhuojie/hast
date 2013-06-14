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

    setTimerSave: (callback) ->
      @timer = Meteor.setTimeout(->
        callback()
      , 3000)
    setTimerRefresh: (callback) ->
      @timer = Meteor.setTimeout(->
        callback()
      , 300)
    setTimerClear: =>
      Meteor.clearInterval @timer

    init: ->
      @isDemoMode = Session.get 'test'
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
          if @isDemoMode
            localStorage.setItem Session.get("hastId"), @editor.getValue()
            @flashMessage "Saved in local"
          else
            Files.update Session.get("hastId"), $set:
              content: @editor.getValue()
            @flashMessage "Saved in server"
          @refreshMathJax("deck-container")

      @setData()
      @setMathJax()
      if Session.get('isInFullScreen') is true
        $('.deck-container').addClass('inFullScreen')
        $('.navbar').addClass('inFullScreen')
        $('.editor-box').addClass('inFullScreen')
      else
        $('.deck-container').removeClass('inFullScreen')
        $('.navbar').removeClass('inFullScreen')
        $('.editor-box').removeClass('inFullScreen')

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
      $("#message-notice").html(message).fadeIn(500).fadeOut 3000

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

    setData: ->
      if @isDemoMode is true
        Meteor.subscribe "newHast", =>
          file = Files.findOne(test: true)
          Session.set "hastId", file._id
          @editor.setValue localStorage.getItem(Session.get("hastId")) or
            file.content or "loading...",
            -1
      else
        Meteor.subscribe "Hast", Session.get("hastId"), =>
          file = Files.findOne(Session.get("hastId"))
          if file
            @editor.setValue file.content or "loading...", -1
          else
            @flashMessage "Not found!"
      @refreshDeck()

  window.panel = new Panel
  window.panel.init()

Template.Hast.events
  "click .save-btn": ->
    if Meteor.user()
      panel = window.panel
      getTitle = ->
        titleString = panel.converter.makeHtml(
          panel.editor.getValue().split("////")[0]
        ).split("\n")[0]
        if titleString.indexOf("<h1>") is 0
          titleString.slice 4, -5
        else
          ""
      file = Files.findOne(Session.get('hastId'))
      Meteor.call "addFile",
        title: getTitle()
        content: panel.editor.getValue()
        test: file.test
        fileId: file._id
      , (error, result) ->
        panel.flashMessage result.message
        Meteor.Router.to "/hast/" + result.fileId

    else
      panel.flashMessage "Please log in to save your own files"

  "click .mathjax-btn": ->
    panel = window.panel
    panel.refreshMathJax 'deck-container'

  "click .full-screen-btn": ->
    Session.set 'isInFullScreen', true

