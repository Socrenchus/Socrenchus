_.extend( Template.group,
  id: Meteor.uuid()
  name: -> @name
  asd: true
  show_replies: => @asd
  posts: ->
    unless @name == 'incubator'
      return @posts
    else
      return [@posts[0]]
  events: {
    "click h1[name='tag-name']": (event) =>
      alert("boooo")
      @asd = !@asd
      Meteor.flush()
  }
)
