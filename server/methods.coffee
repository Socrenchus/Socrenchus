Meteor.methods({
  gimmeUserID: gimmeUserID  
})

gimmeUserID = ->
  return "SPAGHETTI"#Users.findOne( {} )['_id']