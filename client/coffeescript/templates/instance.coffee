_.extend( Template.instance,
  instance_is_set: ->
    instance = Session.get('instance_id')
    if instance? and ![null]
      return true
  ###
  #perform checks, 
  set_instance: ->
    current_url = window.location.host
    admin_id = Session.get('user_id')
    Meteor.call('new_instance_checks', current_url, (err, passed) ->
      #add basic instance info to db if checks pass
      if passed then Meteor.call('create_instance', current_url, admin_id)
      else tron.log('One or more checks failed - cannot create new instance')
    )
  
  check_instance: ->
    Meteor.call('get_instance_id', current_url, (error, instance_id) ->
      if instance_id? #...and then set the session variable 
        Session.set('instance_id', instance_id)
      else
        tron.log('Invalid URL or URL not in db')
    )
    ###
)
