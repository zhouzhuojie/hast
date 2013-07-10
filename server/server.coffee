Meteor.publish "hast", (hastId) ->
  check hastId, String

  file = Files.findOne hastId
  if file and (file.userId is @userId or file.type is 'public')
    return Files.find hastId,
      fields:
        content: 1
        test: 1
        userId: 1
        type: 1
        currentSlide: 1
        theme : 1
        transition : 1
  else
    return null

Meteor.publish "oldHast", ->
  Files.find
    userId: @userId
  ,
    fields:
      title: 1
      submitted: 1
      type: 1
      userId: 1
      currentSlide: 1

Meteor.methods
  demoContent: () ->
    return Files.findOne({test:true}).content

  getHast: (hastId) ->
    check hastId, String

    file = Files.findOne hastId
    if file and (file.userId is Meteor.userId() or file.type is 'public')
      return file
    else
      return null

  addFile: (fileAttributes) ->
    check fileAttributes,
      title: String
      content: String

    user = Meteor.user()
    unless user
      throw new Meteor.Error(401, "You need to login to post new stories")
    unless fileAttributes.title
      throw new Meteor.Error(422, "Please fill in a headline in title page")

    file = _.extend(_.pick(fileAttributes, "title", "content"),
      userId: user._id
      author: user.username
      submitted: new Date().getTime()
      type: "private"
      test: false
    )
    fileId = Files.insert(file)

    message: "New Hast Created!"
    fileId: fileId

  updateType: (hastId, isPublic) ->
    check hastId, String
    check isPublic, Boolean
    user = Meteor.user()
    unless user
      throw new Meteor.Error(401, "You need to login to post new stories")
    file = Files.findOne(hastId)
    unless file.userId is user._id
      throw new Meteor.Error(402, "You need to own this hast")
    Files.update hastId,
      $set:
        type: if isPublic then 'public' else 'private'
    message: "Hast Updated!"
    fileId: hastId

Winston.add Winston_Loggly, winstonOptions || {}

UserStatus.on "sessionLogin", (userId, sessionId, ipAddr) ->
  Winston.info
    type: 'login'
    userId: userId
    sessionId: sessionId
    ipAddr: ipAddr

UserStatus.on "sessionLogout", (userId, sessionId) ->
  Winston.info
    type: 'logout'
    userId: userId
    sessionId: sessionId

Fiber = Npm.require 'fibers'

__meteor_bootstrap__.app.use (req, res, next) ->
  Fiber(->
    Winston.info
      type: 'connect'
      ipAddr: req.headers['x-forwarded-for']
    next()
  ).run()
