_.extend( Template.post,
  parent: ->
    parent = Posts.findOne(_id: @parent_id)
    return {exists: parent?, post: parent}

  #QQQ
  init: ->
    #function runs on initialization of post
    #takes care of dependencies
    if Session.equals('current_post', undefined)
      Session.set('current_post', @_id)  #volunteer
    if Session.equals('tagging', undefined)
      Session.set('tagging', false)
    if Session.equals('suggested_tags', undefined)
      Session.set('suggested_tags', [])
    return ""
    
  avatar: ->
    hash = hex_md5("#{@_id}@example.com")
    return "http://www.gravatar.com/avatar/#{hash}"
    
  content: ->
    ###
    1. Raw input is assumed in Content.
    2. Raw input converted using Showdown.
    3. Output of step 2 is subjected to Whitelist.
    4. Links are made ready for oembed.
    ###
    #1. @content contains the raw input.
    raw_input = @content
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
    Meteor.defer( -> $('a.oembed').oembed().removeClass('oembed') )
    return oembedded
  identifier: -> @_id
  link_href: ->
    return Router.link("/p/#{ @_id }")
)
