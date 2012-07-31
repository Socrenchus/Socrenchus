Meteor.methods(
  get_user_id: ->
    if Meteor.accounts?
      return @userId()
    else
      #if auth packages do not exist, return the first id you can find.
      return Users.findOne({})._id
  
  get_post_by_id: (post_id) ->
    return Posts.findOne(post_id)
    
  confirm_instance_dns: (url) ->
    socrenchus_ip = '192.168.1.110' #<-private ip; will eventually change...
    if true
      return true
    else
      tron.log('DNS confirmation failed')
      return false
    #{ spawn, exec } = __meteor_bootstrap__.require('child_process')
    #Line below results in TypeError: Converting circular structure to JSON
    #lookup = spawn('echo', ['hello'])
    #problem with using dns.lookup, asynchronous, wait function didn't work
    
  check_email_domain: (url) ->
    #check that logged in user is admin id
    current_user_id = Meteor.call('get_user_id')
    email_addr = Users.findOne( _id: current_user_id ).email
    [host, domain] = email_addr.split("@")
    if domain is url
      return true #success - email address matches url
    else
      tron.log('Email domain does not match requested instance domain')
      #return false #mismatch - don't allow
      return true #temporary for localhost use
      
  new_instance_checks: (url) ->
    Meteor.call('confirm_instance_dns', url, (error, is_confirmed) ->
      if is_confirmed
        Meteor.call('check_email_domain', url, (error, match) ->
          return match
        )
      else
        return false
    )
      
  get_instance_id: (url) ->
    instance = Instances.findOne({domain: url})
    if instance?
      tron.log 'instance id: ', instance._id
      return instance._id
    else
      tron.log("Method get_instance_id: instance \"#{url}\" does not exist")
    
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
    #end
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
      #end
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
      #end
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
      
  #don't remember why I needed this...
  get_all_instance_domains: ->
    all_instances = Instances.find().fetch()
    for instance in all_instances
      null

)

