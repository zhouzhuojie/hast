Meteor.Router.add({
  '/': { as: 'home', to: function(){
    Session.set('test', true);
    return 'newHast';
  }},
  '/archives': { to: 'oldHast', as: 'archives'},
  '/hast/:id': { to: function(id){
    Session.set('test', false);
    Session.set('hastId', id);
    return 'newHast';
  }},
  '*': 'not_found'
});
