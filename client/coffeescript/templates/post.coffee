_.extend( Template.post,
  content: -> 
    escaped = Handlebars._escape(@content)
    showdownConverter = new Showdown.converter()
    postContentHtml = showdownConverter.makeHtml(escaped)
    return postContentHtml
  identifier: -> @_id
)
