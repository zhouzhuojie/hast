Template.newHast.rendered = function(){

  (function () {
  var head = document.getElementsByTagName("head")[0], script;
  script = document.createElement("script");
  script.type = "text/x-mathjax-config";
  script[(window.opera ? "innerHTML" : "text")] =
    "MathJax.Hub.Config({" +
    "  tex2jax: { inlineMath: [['$','$'], ['\\\\(','\\\\)']] }," +
    "  processEscapes: true" +
    "});"
  head.appendChild(script);
  script = document.createElement("script");
  script.type = "text/javascript";
  script.src  = "http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML";
  head.appendChild(script);
  })();

  window.currentSlide = 0;
  $(document).on('deck.change', function(event, from, to){
    currentSlide = to;
  });

  window.editor = ace.edit("editor");
  window.converter = new Markdown.Converter();
  editor.setTheme("ace/theme/chrome");
  editor.getSession().setMode("ace/mode/markdown");
  editor.getSession().setUseWrapMode(true);
  if (window.test === false){
    editor.setValue(Files.findOne(window.hastId) || 'Loading...', -1);
  }
  else{
    editor.setValue(localStorage.getItem('testContent') || Files.findOne(window.hastId) || 'Loading...', -1);
  }

  window.refreshDeck = function(){
    var slidesMd = editor.getValue().split('////');
    var getSlidesHtmls = function(Mds, c){
      return  _.reduce(
        _.map(Mds, function(slide, key){
        if (key === 0){
          return '<section class="slide" id="title-slide">' + c.makeHtml(slide) + '</section>';
        };
        return '<section class="slide">' + c.makeHtml(slide) + '</section>';
      }),
      function(a,b){return a+b;}
      );
    };
    $('#deck-container').html(getSlidesHtmls(slidesMd, converter));
    $.deck('.slide');
    $.deck('go', currentSlide);
  };

  refreshDeck();
  window.flashMessage = function(message){
    $('#saving-btn').html(message).fadeIn(500).fadeOut(3000);
  }

  var myTimer = function(){

    var timer;

    this.setSave = function(saveFormCB) {
      timer = Meteor.setTimeout(function() {
        saveFormCB();
      }, 3000);
    };

    this.setRefresh= function(saveFormCB) {
      timer = Meteor.setTimeout(function() {
        saveFormCB();
      }, 300);
    };

    this.clear = function() {
      Meteor.clearInterval(timer);
    };

    return this;
  }();

  editor.on("change", function(){
    myTimer.clear();
    myTimer.setRefresh(function(){
      refreshDeck();
    });
    myTimer.setSave(function(){
      if (window.test === false){
        Files.update(window.hastId, {$set: {content: editor.getValue()}});
        flashMessage('Saved in server');
      }
      else{
        localStorage.setItem('testContent', editor.getValue());
        flashMessage('Saved in local');
      }
      if (window.MathJax){
        MathJax.Hub.Queue(["Typeset",MathJax.Hub,"deck-container"]);
      }
    });
  });
  Meteor.setTimeout(function() {
    if (window.MathJax){
      MathJax.Hub.Queue(["Typeset",MathJax.Hub,"deck-container"]);
    }
  }, 3000);

};

Template.newHast.events({
  'click .save-btn': function(){
    if(Meteor.user()){
      var getTitle = function(){
        var titleString = converter.makeHtml(editor.getValue().split('////')[0]).split('\n')[0]
        if (titleString.indexOf('<h1>') == 0){
          return titleString.slice(4,-5);
        }
        else{
          return '';
        }
      };
      var file = Files.findOne()
      Meteor.call('addFile', {title: getTitle(), content: editor.getValue(), test: file.test, fileId: file._id}, function(error, result){
        flashMessage(result.message);
        Meteor.Router.to('/hast/' + result.fileId);
      });
    }
    else{
      flashMessage('Please log in to save your own files');
    }
  },
  'click .mathjax-btn': function(){
    if (window.MathJax){
      MathJax.Hub.Queue(["Typeset",MathJax.Hub,"deck-container"]);
    }
  }
});
