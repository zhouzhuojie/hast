Meteor.methods({
  addFile: function(fileAttributes){
    var user = Meteor.user();
    if (!user){
      throw new Meteor.Error(401, 'You need to login to post new stories');
    }
    if (!fileAttributes.title){
      throw new Meteor.Error(422, 'Please fill in a headline in title page');
    }
    if (fileAttributes.test){
      var file = _.extend(_.pick(fileAttributes, 'title', 'content'), {
        userId: user._id,
        author: user.username,
        submitted: new Date().getTime(),
        type: 'private',
        test: false,
      });

      var fileId = Files.insert(file);
      return {message: 'New Hast Created!', fileId: fileId};
    }
    else{
      var file_to_update = _.extend(_.pick(fileAttributes, 'title', 'content'), {
        submitted: new Date().getTime(),
      });
      Files.update(fileAttributes.fileId, {$set: file_to_update});
      return {message: 'Hast Updated!', fileId: fileAttributes.fileId};
    }

  }
});
