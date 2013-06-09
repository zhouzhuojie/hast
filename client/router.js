Meteor.Router.add({
  '/': { as: 'home', to: function(){
    Meteor.subscribe('newHast', function(){
      var file = Files.findOne({test:true});
      window.hastId = file._id;
      window.test = true;
      editor.setValue(localStorage.getItem('testContent') || file.content || 'loading...', -1);
      refreshDeck();
    });
    return 'newHast';
  }},
  '/archives': { to: 'oldHast', as: 'archives'},
  '/hast/:id': { to: function(id){
    Meteor.subscribe('Hast', id.toString(), function(){
      var file = Files.findOne(id);
      if(file){
        window.hastId = file._id;
        window.test = false;
        editor.setValue(file.content || 'loading...', -1);
        refreshDeck();
      }
      else{
        flashMessage("Not found!");
      }
    });
    return 'newHast';
  }},
  '*': 'not_found'
});
