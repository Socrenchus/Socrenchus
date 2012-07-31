Meteor.methods(
  get_user_id: ->
    if Meteor.accounts?
      return @userId()
    else
      #if auth packages do not exist, return the first id you can find.
      return Users.findOne({})._id
  
  get_post_by_id: (post_id) ->
    return Posts.findOne(post_id)
    
  create_instance: (args...) ->
    url = args[0]
    user_id = args[1]
    #get instance id...
    instance = Instances.findOne({domain: url})
    if instance?
      tron.log 'instance id: ', instance._id
      Session.set('instance_id', instance._id)
      instance_exists = true
    else
      tron.log("Method get_instance_id: instance \"#{url}\" does not exist")
      instance_exists = false
    if !instance_exists
      #confirm instance dns...
      dns_match = false
      socrenchus_ip = '192.168.1.110' #<-private ip; will eventually change...
      #TODO: Perform DNS Lookup on supplied URL, compare to socrenchus IP addr
      #         still have no idea how to do this...
      if true
        dns_match = true
      else
        tron.log('DNS confirmation failed')
        dns_match = false
      #check email domain
      email_match = false
      if dns_match
        current_user_id = Meteor.call('get_user_id')
        email_addr = Users.findOne( _id: current_user_id ).email
        [host, domain] = email_addr.split("@")
        if domain is url
          email_match = true #success - email address matches url
        else
          tron.log('Email domain does not match requested instance domain')
          #should return false #mismatch - don't allow
          email_match = false #temporary for localhost use
      #create new instance
      if email_match
        tron.log('create_instance: Creating new instance')
        #Insert new instance info in db...
        Instances.insert({
          admin_id: user_id,
          domain: domain
        })
        #...and then set the instance_id session variable to the new instance
        Meteor.call('get_instance_id', url, (error, instance_id) ->
          Session.set('instance_id', instance_id)
        )
)
