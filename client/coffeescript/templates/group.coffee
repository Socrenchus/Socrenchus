_.extend( Template.group,
  name: -> @name
  show_replies: ->
    @show ?= true
    @context = Meteor.deps.Context.current
    return @context.run(=>
      return @show
    )
  posts: ->
    unless @name == 'incubator'
      return @posts
    else
      return [@posts[0]]
  events: {
    "click h1[name='tag-name']": (event) ->
      if !event.isImmediatePropagationStopped()
        @show = !@show
        @context.invalidate()
        Meteor.flush()
        event.stopImmediatePropagation()
  }
)
