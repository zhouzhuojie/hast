@Files = new Meteor.Collection("files")
ownFile = (userId, file) ->
  file and file.userId is userId

@Files.allow
  update: ownFile
  remove: ownFile

@Files.deny update: (userId, file, fieldNames) ->
  _.without(fieldNames, "content", "title").length > 0
