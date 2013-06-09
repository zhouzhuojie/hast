Files = new Meteor.Collection("files");

ownFile = function(userId, file){
  return file && file.userId === userId;
};

Files.allow({
  update: ownFile,
  remove: ownFile,
});

Files.deny({
  update: function(userId, file, fieldNames) {
    // may only edit the following fields:
    return (_.without(fieldNames, 'content').length > 0);
  }
});
