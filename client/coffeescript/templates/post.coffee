_.extend( Template.post,
  content: ->
    ###
    1. Raw input is assumed in Content.
    2. Raw input converted using Showdown.
    3. Output of step 2 is subjected to Whitelist.
    4. Links are made ready for oembed.
    ###
    #1. @content contains the raw input.
    raw_input = @content;
    #2. Convert raw input using Showdown.
    showdown_converter = new Showdown.converter()
    raw_showdown = showdown_converter.makeHtml(raw_input)
    #3. Output subjected to whitelist.  
    # NotImplementedYet
    cooked_showdown = raw_showdown;
    #4. Links made ready for Oembed.  
    return post_content_html
  identifier: -> @_id
  link_href: ->
    return "/#{ @_id }"
  parent_href: ->
    if @parent_id?
      return "/#{ @parent_id }"
    else
      return false
)
