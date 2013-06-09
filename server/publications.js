Meteor.publish('newHast', function() {
  return Files.find({test: true}, {limit: 1, fields: {content: 1, test: 1}});
});

Meteor.publish('Hast', function(fileId) {
  return Files.find({_id: fileId, $or: [{userId: this.userId}, {type: 'public'}]}, {fields: {content: 1, test: 1}});
});

Meteor.publish('oldHast', function() {
  return Files.find({userId: this.userId}, {fields: {title: 1}});
});
