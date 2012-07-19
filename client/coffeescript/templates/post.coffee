_.extend( Template.post,
  content: ->
    escaped = Handlebars._escape(@content)
    showdown_converter = new Showdown.converter()
    post_content_html = showdown_converter.makeHtml(escaped)
    return post_content_html
  identifier: -> @_id
  link_href: ->
    return "/#{ @_id }"
  parent_href: ->
    if @parent_id?
      return "/#{ @parent_id }"
    else
      return false
  author: -> @author_id
  author_short: -> @author_id.slice(0, 5)
    #hack to get a short author name.  remove
    #  when we have access to usernames.  
)
