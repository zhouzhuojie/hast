Url = new Meteor.Collection("url")

Router.map ->
  @route 'shortUrl', {
    where: 'server',
    path: '/s/:shortUrlName',
    action: ->
      shortUrlName = @params.shortUrlName
      u = Url.findOne shortUrlName
      if u
        hastId = u.hastId
        @response.writeHead '302', {'Location': "/hast/#{hastId}"}
      else
        @response.writeHead '302', {'Location': "/404"}
  }

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
      shortUrl: 1

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

  getShortUrl: (hastId, shortUrlName) ->
    check hastId, String
    check shortUrlName, String
    user = Meteor.user()
    unless user
      throw new Meteor.Error(401, "You need to login to post new stories")
    u = Url.findOne shortUrlName
    if u
      throw new Meteor.Error(401, "The name has been taken")
    else
      Url.insert
        _id: shortUrlName
        hastId: hastId
      file = Files.findOne hastId
      Files.update hastId,
        $set:
          shortUrl: "hast.me/s/#{shortUrlName}"
    message: "ShortUrl Updated!"
    fileId: hastId
