Meteor.methods
  userId: -> 
    if Meteor.accounts?
      return @userId()
    else
      return Users.findOne({})._id

