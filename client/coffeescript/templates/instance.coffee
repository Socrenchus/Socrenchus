_.extend( Template.instance,
  instance_is_set: ->
    instance = Session.get('instance_id')
    if instance? and ![null]
      return true
      
  #perform checks, 
  set_instance: ->
    current_url = window.location.host
    admin_id = Session.get('user_id')
    Meteor.call('new_instance_checks', current_url, (err, passed) ->
      #add basic instance info to db if checks pass
      if passed then Meteor.call('create_instance', current_url, admin_id)
      else tron.log('One or more checks failed - cannot create new instance')
    )
  
)
