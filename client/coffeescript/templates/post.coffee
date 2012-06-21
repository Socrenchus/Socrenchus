_.extend( Template.post,
  content: ->
    showdownConverter = new Showdown.converter()
    postContentHtml = showdownConverter.makeHtml(@content)
    return postContentHtml
  identifier: -> @_id
)
