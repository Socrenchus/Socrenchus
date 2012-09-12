_.extend( Template.post_preview,
  rendered: ->
    $(@.findAll('a.oembed')).oembed().removeClass('oembed')
  content: ->
      
    ###
    1. Raw input is assumed in Content.
    2. Raw input converted using Showdown.
    3. Output of step 2 is subjected to Whitelist.
    4. Links are made ready for oembed.
    ###
    return '' unless @content?
    raw_input = Handlebars._escape(@content);
    #1. @content contains the raw input.
    #raw_input = @content
    #2. Convert raw input using Showdown.
    showdown_converter = new Showdown.converter()
    raw_showdown = showdown_converter.makeHtml(raw_input)
    #3. Output subjected to whitelist.
    # NotImplementedYet
    cooked_showdown = raw_showdown
    #4. Links made ready for Oembed.
    replacement = '$1<div><a href="$2" class="oembed">$2</a></div>'
    oembedded = cooked_showdown.replace('<a', "<a class='oembed'")
    oembedded = oembedded.replace(/(\s|>|^)(https?:[^\s<]*)/igm, replacement)
    oembedded = oembedded.replace(/(\s|>|^)(mailto:[^\s<]*)/igm, replacement)
    return oembedded
    
    
  identifier: -> @_id
  
  author_name: -> 
    if @author?.name?
      return @author?.name
    else if @author?.username?
      return @author?.username
    else 
      return ''
  
  #a similar function exists in post_wrapper --phil
  email_hash: ->
    this_post = Posts.findOne( _id: @_id )
    author = this_post?.author
    if author?
      if author.emails? and author.emails.length? and author.emails.length>0
        return author.emails[0].md5()
      else if author._id?
        return author._id.md5()
    else
      return "NO AUTHOR".md5()
  
  author: -> @author_id

  
  reply_count: ->
    ct = @reply_count
    if ct is 1
      return '1 reply'
    else
      return "#{ct} replies"
  
  time: ->
    return (new Date(@time)).relative()
  
  events: {
    "click": (event) ->
      Backbone.history.navigate("/p/#{@_id}", trigger: true)
  }
  
)
