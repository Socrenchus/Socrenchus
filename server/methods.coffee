Meteor.methods
  user_id: -> 
    if Meteor.accounts?
      return @userId()
    else
      return Users.findOne({})._id

