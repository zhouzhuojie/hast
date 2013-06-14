Meteor.subscribe "oldHast"

Template.oldHast.files = ->
  Files.find(
    {userId: @userId},
    {sort: {submitted: -1}, reactive: false})
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
      Meteor.call "updateType",
        $el.attr('data-hastId'),
        data.value, (error, result)->
          console.log error, result
