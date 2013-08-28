Meteor.subscribe "oldHast"

Template.oldHast.files = ->
  Files.find(
    {userId: Meteor.userId()}, {sort: {submitted: -1}})
  .fetch()

Template.oldHast.timeFromNow = (utc)->
  moment(utc).fromNow()

Template.oldHast.checkedStatus = (type)->
  if type is 'public' then 'checked' else 'unchecked'

Template.oldHast.rendered = ->
  $('.switch')
    .bootstrapSwitch()
    .on 'switch-change', (e, data) ->
      $el = $(data.el)
      Meteor.call "updateType", $el.attr('data-hastId'), data.value

Template.oldHast.events
  'click .delete-btn': (event) ->
    hastId = event.target.attributes['data-hastId'].value
    bootbox.confirm "Are you sure to delete?", (result) ->
      if result is true
        Files.remove hastId
  'click .getShortUrl-btn': (event) ->
    hastId = event.target.attributes['data-hastId'].value
    $('#shorturl-modal').modal()
    $('.submit-shorturl-btn').attr('data-hastId', hastId)
    $('#shortUrlInput').keyup ->
      if /^[0-9a-zA-Z_.\-]+$/.test @value
        $('.submit-shorturl-btn').show()
        $('.shortUrlInputMsg').hide()
      else
        $('.submit-shorturl-btn').hide()
        $('.shortUrlInputMsg').html('Please input numbers or characters.').show()
  'click .submit-shorturl-btn': (event) ->
    hastId = event.target.attributes['data-hastId'].value
    Meteor.call 'getShortUrl', hastId, $('#shortUrlInput').val()
